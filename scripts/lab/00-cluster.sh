#!/usr/bin/env bash
# Garante kubectl, helm e um cluster Kubernetes acessível (kind ou contexto existente).
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# shellcheck disable=SC2034  # lido pelos wrappers kubectl/helm de common.sh
LAB_PIN_CONTEXT=0   # aqui decidimos o contexto; antes disso vale o contexto atual do kubeconfig

need_cmd kubectl "Instale o kubectl (no Cloud Shell ele já vem instalado)."
need_cmd openssl

# ---- helm ------------------------------------------------------------------
if ! type -P helm >/dev/null 2>&1; then
  log "Instalando helm em $LAB_BIN_DIR"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | USE_SUDO=false HELM_INSTALL_DIR="$LAB_BIN_DIR" bash
fi

# ---- modo do cluster -------------------------------------------------------
cluster_reachable() { kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; }

mode="$LAB_CLUSTER_MODE"
if [[ "$mode" == "auto" ]]; then
  if cluster_reachable; then mode="existing"; else mode="kind"; fi
fi

case "$mode" in
  kind)
    need_cmd docker "O modo kind precisa do Docker rodando."
    docker info >/dev/null 2>&1 || die "Docker não está acessível."
    if ! command -v kind >/dev/null 2>&1; then
      log "Instalando kind em $LAB_BIN_DIR"
      curl -fsSL -o "$LAB_BIN_DIR/kind" \
        https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-linux-amd64
      chmod +x "$LAB_BIN_DIR/kind"
    fi
    mem_gb="$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)"
    need_gb=10; is_skipped gitlab && need_gb=6
    if (( mem_gb < need_gb )); then
      warn "Esta máquina tem ~${mem_gb} GiB de RAM; o lab completo pede ~${need_gb} GiB."
      warn "Use uma VM maior ou LAB_SKIP=\"gitlab\" (ex.: LAB_SKIP=\"gitlab kargo\")."
    fi
    if kind get clusters 2>/dev/null | grep -qx "$LAB_CLUSTER_NAME"; then
      log "Cluster kind '$LAB_CLUSTER_NAME' já existe"
    else
      log "Criando cluster kind '$LAB_CLUSTER_NAME'"
      kind create cluster --name "$LAB_CLUSTER_NAME" --config "$LAB_MANIFESTS/kind-config.yaml" --wait 180s
    fi
    kubectl config use-context "kind-$LAB_CLUSTER_NAME" >/dev/null
    ;;
  existing)
    cluster_reachable || die "Nenhum cluster acessível pelo kubectl. Rode 'gcloud container clusters get-credentials ...' ou use LAB_CLUSTER_MODE=kind."
    log "Usando o cluster existente (contexto: $(kubectl config current-context))"
    alloc_gb="$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.allocatable.memory}{"\n"}{end}' \
      | awk '{ sub(/Ki$/, "", $1); s += $1 } END { printf "%d", s/1024/1024 }')"
    if (( alloc_gb < 8 )); then
      warn "Memória alocável dos nós: ~${alloc_gb} GiB. O lab completo pede ~7 GiB de requests (GitLab sozinho ~3 GiB)."
    fi
    ;;
  *) die "LAB_CLUSTER_MODE inválido: $mode (use auto, kind ou existing)" ;;
esac

kv_set MODE "$mode"
kv_set CONTEXT "$(kubectl config current-context)"
kubectl get nodes
