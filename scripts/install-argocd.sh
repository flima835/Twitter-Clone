#!/usr/bin/env bash
# Instala e configura o ArgoCD de forma IDEMPOTENTE (seguro rodar toda vez que subir o lab).
# Assim que o cluster existir, o ArgoCD passa a monitorar continuamente o namespace
# 'twitter-clone' e a corrigir qualquer drift em relacao ao que esta em k8s/base no Git.
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${GREEN}### Instalando ArgoCD (idempotente) ###${NC}"
kubectl get ns argocd >/dev/null 2>&1 || kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${YELLOW}Aguardando o ArgoCD ficar pronto (pode levar alguns minutos na primeira vez)...${NC}"
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-repo-server deployment/argocd-server || true

echo -e "${GREEN}### Registrando o Projeto e a Application do Twitter-Clone ###${NC}"
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml

echo -e "${GREEN}ArgoCD instalado. Ele agora monitora o repo (pasta k8s/base) e o namespace twitter-clone continuamente.${NC}"
echo "Dica: acesse a UI com 'kubectl -n argocd port-forward svc/argocd-server 8080:443' e pegue a senha inicial com:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
