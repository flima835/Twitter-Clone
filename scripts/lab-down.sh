#!/usr/bin/env bash
# Derruba o lab.
#  - modo kind: apaga o cluster kind inteiro
#  - modo existing: desinstala as ferramentas do lab e apaga os namespaces
#    (o ArgoCD só é removido com LAB_REMOVE_ARGOCD=1)
# Uso: scripts/lab-down.sh [-y]
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lab/common.sh
source "$DIR/lab/common.sh"

mode="$(kv_get MODE)"; mode="${mode:-existing}"
ctx="$(kubectl config current-context 2>/dev/null || echo '<nenhum>')"

if [[ "${1:-}" != "-y" && "${LAB_ASSUME_YES:-0}" != "1" ]]; then
  echo "Modo: $mode | contexto atual: $ctx"
  read -r -p "Apagar o lab? [s/N] " ans
  [[ "$ans" =~ ^[sSyY]$ ]] || { echo "Cancelado."; exit 0; }
fi

bash "$DIR/lab-portforward.sh" stop || true

if [[ "$mode" == "kind" ]]; then
  need_cmd kind
  kind delete cluster --name "$LAB_CLUSTER_NAME"
else
  helm uninstall kargo -n kargo 2>/dev/null || true
  helm uninstall jenkins -n jenkins 2>/dev/null || true
  helm uninstall cert-manager -n cert-manager 2>/dev/null || true
  for ns in kargo jenkins gitlab lab-data cert-manager; do
    kubectl delete namespace "$ns" --ignore-not-found --wait=false
  done
  if [[ "${LAB_REMOVE_ARGOCD:-0}" == "1" ]]; then
    kubectl delete namespace argocd --ignore-not-found --wait=false
  fi
fi

log "Lab removido. As credenciais continuam em $LAB_STATE_FILE (apague a pasta $LAB_STATE_DIR para zerar)."
