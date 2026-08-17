# Experimentos (nao usados pelo ArgoCD)

Estes manifests nao fazem parte do sync automatico do ArgoCD (nao estao no
k8s/base/kustomization.yaml) porque duplicam o Deployment/Service `mysql`
já definido em `k8s/base/mysql-deployment.yaml`:

- `mysql.yaml`: versao mais antiga do mysql, superada por mysql-deployment.yaml.
- `mysql-zabbix.yaml`: variante com um sidecar mysqld-exporter (metricas). Tem
  valor, mas precisa ser mesclada manualmente ao mysql-deployment.yaml (dar
  um nome diferente ou usar patches do Kustomize) antes de entrar em k8s/base,
  senao o `kubectl apply -k` falha por objetos duplicados.
