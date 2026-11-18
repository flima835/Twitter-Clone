#!/usr/bin/env bash
# cert-manager (pré-requisito) + Kargo via Helm.
# Versões: LAB_CERTMANAGER_VERSION e LAB_KARGO_VERSION (vazio = última do chart).
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if is_skipped kargo; then log "kargo: ignorado (LAB_SKIP)"; exit 0; fi
need_cmd helm

cm_ver=(); [[ -n "${LAB_CERTMANAGER_VERSION:-}" ]] && cm_ver=(--version "$LAB_CERTMANAGER_VERSION")
kg_ver=(); [[ -n "${LAB_KARGO_VERSION:-}" ]] && kg_ver=(--version "$LAB_KARGO_VERSION")

# ---- cert-manager ------------------------------------------------------------
if kubectl get crd certificates.cert-manager.io >/dev/null 2>&1; then
  log "cert-manager já instalado"
else
  log "Instalando cert-manager"
  helm repo add jetstack https://charts.jetstack.io --force-update >/dev/null
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager --create-namespace \
    --set crds.enabled=true \
    ${cm_ver[@]+"${cm_ver[@]}"} --wait --timeout 5m
fi

# ---- Kargo -------------------------------------------------------------------
pass="$(lab_secret KARGO_ADMIN_PASSWORD)"
hash="$(kv_get KARGO_ADMIN_HASH)"
if [[ -z "$hash" ]]; then
  hash="$(bcrypt_hash "$pass")"
  kv_set KARGO_ADMIN_HASH "$hash"
fi
signing_key="$(lab_secret KARGO_TOKEN_SIGNING_KEY)"

extra=()
if is_skipped argocd; then extra+=(--set controller.argocd.integrationEnabled=false); fi

log "Instalando Kargo"
helm upgrade --install kargo oci://ghcr.io/akuity/kargo-charts/kargo \
  --namespace kargo --create-namespace \
  --set-string api.adminAccount.passwordHash="$hash" \
  --set-string api.adminAccount.tokenSigningKey="$signing_key" \
  ${extra[@]+"${extra[@]}"} ${kg_ver[@]+"${kg_ver[@]}"} \
  --wait --timeout 10m
