#!/usr/bin/env bash
# Port-forwards do lab em background (reconectam sozinhos se o pod reiniciar).
# Uso: scripts/lab-portforward.sh [start|stop|status]
# LAB_PF_ADDRESS=0.0.0.0 expõe em todas as interfaces (padrão: 127.0.0.1).
set -Eeuo pipefail
# shellcheck source=lab/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lab/common.sh"

PF_DIR="$LAB_STATE_DIR/pf"
ADDR="${LAB_PF_ADDRESS:-127.0.0.1}"
mkdir -p "$PF_DIR"

# nome|namespace|serviço|porta-local|porta-remota (auto = primeira porta do serviço)
TARGETS=(
  "argocd|argocd|argocd-server|8080|443"
  "jenkins|jenkins|jenkins|8082|8080"
  "gitlab|gitlab|gitlab|8083|80"
  "kargo|kargo|kargo-api|8085|auto"
  "redis|lab-data|redis|6379|6379"
  "mongodb|lab-data|mongodb|27017|27017"
)

is_running() {
  local f="$PF_DIR/$1.pid"
  [[ -f "$f" ]] && kill -0 "$(cat "$f")" 2>/dev/null
}

stop_one() {
  local f="$PF_DIR/$1.pid"
  if [[ -f "$f" ]]; then
    kill -- "-$(cat "$f")" 2>/dev/null || kill "$(cat "$f")" 2>/dev/null || true
    rm -f "$f"
  fi
}

start_all() {
  need_cmd kubectl
  local ctx; ctx="$(kubectl config current-context)"
  local t name ns svc lport rport
  for t in "${TARGETS[@]}"; do
    IFS='|' read -r name ns svc lport rport <<<"$t"
    if is_skipped "$name"; then continue; fi
    if ! kubectl -n "$ns" get svc "$svc" >/dev/null 2>&1; then
      warn "$name: serviço $ns/$svc não encontrado, pulando"
      continue
    fi
    if [[ "$rport" == "auto" ]]; then
      rport="$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.ports[0].port}')"
    fi
    stop_one "$name"
    setsid bash -c "while true; do kubectl --context '$ctx' -n '$ns' port-forward --address '$ADDR' 'svc/$svc' '$lport:$rport'; sleep 3; done" \
      >"$PF_DIR/$name.log" 2>&1 &
    echo $! >"$PF_DIR/$name.pid"
    log "port-forward $name -> $ADDR:$lport"
  done
}

stop_all() {
  local t name
  for t in "${TARGETS[@]}"; do
    name="${t%%|*}"
    stop_one "$name"
  done
  log "port-forwards encerrados"
}

status_all() {
  local t name lport
  for t in "${TARGETS[@]}"; do
    IFS='|' read -r name _ _ lport _ <<<"$t"
    if is_running "$name"; then echo "  ativo   $name ($ADDR:$lport)"; else echo "  parado  $name"; fi
  done
}

case "${1:-start}" in
  start)  start_all ;;
  stop)   stop_all ;;
  status) status_all ;;
  *) die "Uso: $0 [start|stop|status]" ;;
esac
