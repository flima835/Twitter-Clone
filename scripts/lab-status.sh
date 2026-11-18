#!/usr/bin/env bash
# Mostra o estado dos pods do lab e dos port-forwards.
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lab/common.sh
source "$DIR/lab/common.sh"

log "Contexto: $(kubectl config current-context)"
for ns in cert-manager argocd kargo jenkins gitlab lab-data; do
  if kubectl get namespace "$ns" >/dev/null 2>&1; then
    echo
    echo "== $ns =="
    kubectl -n "$ns" get pods
  fi
done
echo
echo "== port-forwards =="
bash "$DIR/lab-portforward.sh" status
