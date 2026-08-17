#!/bin/bash
set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Sempre roda a partir da raiz do repo, nao importa de onde o script foi chamado
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Variaveis do Projeto (edite se necessario)
PROJECT_ID="twitter-clone-sre"
ZONE="us-central1-a"
CLUSTER_NAME="twitter-clone-cluster"

echo -e "${GREEN}### 1. Provisionando Infraestrutura com Terraform ###${NC}"
cd infra/terraform
terraform init
terraform apply -auto-approve
cd - > /dev/null

echo -e "${GREEN}### 2. Configurando Contexto do Kubernetes ###${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

echo -e "${GREEN}### 3. Instalando/Atualizando o ArgoCD (GitOps) ###${NC}"
# A partir de agora, o ArgoCD monitora o cluster continuamente e mantem tudo
# sincronizado com a pasta k8s/base do repositorio (self-heal automatico).
bash scripts/install-argocd.sh

echo -e "${GREEN}### 4. Build da Imagem com Cloud Build ###${NC}"
TAG=$(date +%Y%m%d-%H%M%S)
IMAGE_URL="us-central1-docker.pkg.dev/$PROJECT_ID/repo-clone/app:$TAG"
(cd app && gcloud builds submit --tag $IMAGE_URL .)

echo -e "${GREEN}### 5. Atualizando o manifesto e disparando o ArgoCD (GitOps) ###${NC}"
sed -i "s|image: .*repo-clone/app:.*|image: $IMAGE_URL|" k8s/base/deployment.yaml
git add k8s/base/deployment.yaml
git commit -m "lab: atualiza imagem da aplicacao para $TAG" || echo -e "${YELLOW}Nada novo para commitar.${NC}"
if git push; then
  echo "Push feito. O ArgoCD vai detectar a mudanca e sincronizar automaticamente."
else
  echo -e "${YELLOW}Aviso: 'git push' falhou (confira credenciais/branch). Aplicando manualmente via kubectl como fallback...${NC}"
  kubectl apply -k k8s/base
fi
# Pede uma sincronizacao imediata em vez de esperar o polling padrao do ArgoCD (~3min)
kubectl -n argocd annotate application twitter-clone argocd.argoproj.io/refresh=hard --overwrite || true

echo -e "${GREEN}### 6. Preparando o Banco de Dados (Anti-Caos) ###${NC}"
echo -e "${YELLOW}Aguardando o pod do MySQL iniciar...${NC}"
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s
sleep 10
POD_MYSQL=$(kubectl get pods -l app=mysql -o jsonpath="{.items[0].metadata.name}")
echo -e "${YELLOW}Criando tabelas no MySQL ($POD_MYSQL)...${NC}"
kubectl exec -i $POD_MYSQL -- mysql -u root twitter_clone < app/db/backup_hoje.sql

echo -e "${GREEN}### 7. Tudo Pronto! Aguardando IP Externo do Load Balancer ###${NC}"
echo -e "${YELLOW}Pressione Ctrl+C para sair do log quando o IP aparecer.${NC}"
kubectl get service twitter-service -w
