#!/usr/bin/env bash
# ArgoCD. Se já estiver instalado, não faz nada.
# LAB_ARGOCD_SCRIPT=1 usa o seu scripts/install-argocd.sh em vez da instalação padrão.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if is_skipped argocd; then log "argocd: ignorado (LAB_SKIP)"; exit 0; fi

if kubectl -n argocd get deployment argocd-server >/dev/null 2>&1; then
  log "ArgoCD já instalado"
elif [[ "$LAB_ARGOCD_SCRIPT" == "1" && -f "$LAB_ROOT/scripts/install-argocd.sh" ]]; then
  log "Instalando ArgoCD com scripts/install-argocd.sh"
  bash "$LAB_ROOT/scripts/install-argocd.sh"
else
  log "Instalando ArgoCD (manifesto oficial, canal stable)"
  ensure_ns argocd
  kubectl apply -n argocd --server-side --force-conflicts \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

if [[ "$LAB_NO_WAIT" != "1" ]]; then
  wait_rollout deployment/argocd-server argocd 300s
  wait_rollout statefulset/argocd-application-controller argocd 300s
fi
