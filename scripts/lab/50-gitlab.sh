#!/usr/bin/env bash
# GitLab CE (pod único, Omnibus enxuto) no namespace gitlab.
# URL externa: LAB_GITLAB_URL (padrão http://localhost:8083; no Cloud Shell use a URL do Web Preview).
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if is_skipped gitlab; then log "gitlab: ignorado (LAB_SKIP)"; exit 0; fi

ensure_ns gitlab
kubectl -n gitlab create secret generic gitlab-root \
  --from-literal=password="$(lab_secret GITLAB_ROOT_PASSWORD)" --dry-run=client -o yaml | kubectl apply -f -

log "Aplicando GitLab (external_url: $LAB_GITLAB_URL)"
sed "s|__GITLAB_EXTERNAL_URL__|${LAB_GITLAB_URL}|g" "$LAB_MANIFESTS/gitlab.yaml" | kubectl apply -f -

if [[ "$LAB_NO_WAIT" != "1" ]]; then
  wait_rollout statefulset/gitlab gitlab 900s
fi
