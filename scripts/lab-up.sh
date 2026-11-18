#!/usr/bin/env bash
# Sobe o lab completo: ArgoCD, Kargo, Jenkins, GitLab, Redis, MongoDB e Kafka.
# É idempotente: pode rodar de novo a qualquer momento.
#
# Variáveis úteis:
#   LAB_SKIP="gitlab kargo"     não instala essas ferramentas
#   LAB_CLUSTER_MODE=kind       força cluster kind (padrão auto: usa o contexto atual se existir)
#   LAB_GITLAB_URL=https://...  URL externa do GitLab (no Cloud Shell, a do Web Preview)
#   LAB_PORT_FORWARD=0          não abre port-forwards
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lab/common.sh
source "$DIR/lab/common.sh"

FAILED=()
run_phase() { # <nome> <comando...>
  local name="$1"; shift
  log "==== $name ===="
  if ! "$@"; then
    warn "fase '$name' falhou"
    FAILED+=("$name")
  fi
}

log "Subindo o lab Twitter-Clone (Kubernetes)"

# Guarda o contexto atual do kubeconfig e devolve no final: o kind (modo kind) troca o contexto,
# e o subir-lab.sh continua trabalhando no GKE depois daqui.
ORIG_CTX="$(command kubectl config current-context 2>/dev/null || true)"
restore_ctx() {
  local cur; cur="$(command kubectl config current-context 2>/dev/null || true)"
  if [[ -n "$ORIG_CTX" && "$cur" != "$ORIG_CTX" ]]; then
    if command kubectl config use-context "$ORIG_CTX" >/dev/null 2>&1; then
      log "Contexto kubectl restaurado: $ORIG_CTX (o lab roda em: $(kv_get CONTEXT); os scripts do lab usam esse contexto sozinhos)"
    fi
  fi
}
trap restore_ctx EXIT

bash "$DIR/lab/00-cluster.sh"   # sem cluster não há o que fazer: falha aborta

# Em kind, o GitLab precisa de ~15 GiB livres em disco (imagem grande). Sem espaço, pula com aviso.
if [[ "$(kv_get MODE)" == "kind" ]] && ! is_skipped gitlab && [[ "${LAB_FORCE_GITLAB:-0}" != "1" ]]; then
  avail_gb="$(df -BG --output=avail /var/lib/docker 2>/dev/null | tail -n1 | tr -dc '0-9' || true)"
  if [[ -n "$avail_gb" ]] && (( avail_gb < 15 )); then
    warn "Só ${avail_gb} GiB livres em /var/lib/docker; o GitLab precisa de ~15 GiB. Pulando o GitLab (LAB_FORCE_GITLAB=1 força)."
    LAB_SKIP="$LAB_SKIP gitlab"; export LAB_SKIP
  fi
fi

# O que demora mais começa primeiro e sobe em paralelo com o resto.
run_phase "gitlab (aplicar)"      env LAB_NO_WAIT=1 bash "$DIR/lab/50-gitlab.sh"
run_phase "datastores (aplicar)"  env LAB_NO_WAIT=1 bash "$DIR/lab/10-datastores.sh"
run_phase "argocd"                bash "$DIR/lab/20-argocd.sh"
run_phase "kargo"                 bash "$DIR/lab/30-kargo.sh"
run_phase "jenkins"               bash "$DIR/lab/40-jenkins.sh"

log "==== aguardando datastores e GitLab ===="
for t in redis mongodb kafka; do
  if ! is_skipped "$t" && kubectl -n lab-data get statefulset "$t" >/dev/null 2>&1; then
    wait_rollout "statefulset/$t" lab-data 300s || { warn "$t não ficou pronto"; FAILED+=("$t"); }
  fi
done
if ! is_skipped gitlab && kubectl -n gitlab get statefulset gitlab >/dev/null 2>&1; then
  wait_rollout statefulset/gitlab gitlab 900s \
    || warn "GitLab ainda subindo (o primeiro boot leva 5-10 min): acompanhe com 'scripts/lab-status.sh'"
fi

if [[ "$LAB_PORT_FORWARD" == "1" ]]; then
  run_phase "port-forward" bash "$DIR/lab-portforward.sh" start
fi

# ---- Resumo ------------------------------------------------------------------
argocd_pass="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || true)"
echo
log "Lab pronto. Acessos (credenciais também em $LAB_STATE_FILE):"
if ! is_skipped argocd;  then echo "  ArgoCD   https://localhost:8080   admin / ${argocd_pass:-<veja o secret argocd-initial-admin-secret>}"; fi
if ! is_skipped kargo;   then echo "  Kargo    https://localhost:8085   admin / $(kv_get KARGO_ADMIN_PASSWORD)"; fi
if ! is_skipped jenkins; then echo "  Jenkins  http://localhost:8082    admin / $(kv_get JENKINS_ADMIN_PASSWORD)"; fi
if ! is_skipped gitlab;  then echo "  GitLab   $LAB_GITLAB_URL (porta local 8083)   root / $(kv_get GITLAB_ROOT_PASSWORD)"; fi
if ! is_skipped redis;   then echo "  Redis    localhost:6379           senha $(kv_get REDIS_PASSWORD)"; fi
if ! is_skipped mongodb; then echo "  MongoDB  mongodb://admin:$(kv_get MONGODB_PASSWORD)@localhost:27017/?authSource=admin"; fi
if ! is_skipped kafka;   then echo "  Kafka    kafka-0.kafka.lab-data.svc.cluster.local:9092 (só dentro do cluster)"; fi
echo

if (( ${#FAILED[@]} > 0 )); then
  warn "Fases com problema: ${FAILED[*]}"
  exit 1
fi
