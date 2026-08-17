# Twitter-Clone

Site para teste de conexao com banco de dados e controle de sessao de usuarios
utilizando HTML, BOOTSTRAP, JavaScript, PHP e MySQL. Usado como lab de
DevOps/SRE para praticar CI/CD, GitOps com ArgoCD e testes de APM no Datadog.

## Estrutura do repositorio

```
app/                  Codigo da aplicacao (PHP) + Dockerfile (contexto de build)
  db/                 Scripts/dumps SQL (usuarios.sql, migracao_gcp.sql, backup_hoje.sql)
infra/terraform/      Infraestrutura como codigo (provisiona o cluster GKE)
k8s/base/             Manifests Kubernetes ativos, sincronizados pelo ArgoCD
k8s/experiments/      Variantes antigas/nao usadas (nao entram no sync do ArgoCD)
argocd/               AppProject + Application do ArgoCD
scripts/              subir-lab.sh, install-argocd.sh, continuous-deployment.sh
secrets/              (fora do Git) credenciais locais, ex.: key.json
.github/workflows/    Pipeline de CI (build da imagem + atualiza manifesto)
```

## Fluxo GitOps

1. `scripts/subir-lab.sh` provisiona o cluster (Terraform), instala o ArgoCD
   de forma idempotente (`scripts/install-argocd.sh`) e builda a imagem.
2. A tag da nova imagem e gravada em `k8s/base/deployment.yaml` e o commit e
   enviado ao Git.
3. O ArgoCD (instalado no namespace `argocd`) detecta a mudanca no repo e
   sincroniza o cluster automaticamente, com self-heal e refresh sob demanda.
4. O `datadog-agent.yaml` faz parte do mesmo conjunto monitorado pelo ArgoCD,
   entao ele fica sempre no ar para os testes de APM.

## Seguranca

- Nenhuma credencial (`key.json`) fica dentro do contexto de build do Docker
  nem e versionada (veja `.gitignore`).
- O CI (`.github/workflows/deploy.yml`) nao tem mais acesso direto ao cluster;
  ele so builda a imagem e atualiza o manifesto no Git.
