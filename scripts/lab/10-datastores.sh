#!/usr/bin/env bash
# Redis, MongoDB e Kafka no namespace lab-data.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ensure_ns lab-data

if ! is_skipped redis; then
  log "Aplicando Redis"
  kubectl -n lab-data create secret generic redis-auth \
    --from-literal=password="$(lab_secret REDIS_PASSWORD)" --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f "$LAB_MANIFESTS/redis.yaml"
fi

if ! is_skipped mongodb; then
  log "Aplicando MongoDB"
  kubectl -n lab-data create secret generic mongodb-auth \
    --from-literal=password="$(lab_secret MONGODB_PASSWORD)" --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f "$LAB_MANIFESTS/mongodb.yaml"
fi

if ! is_skipped kafka; then
  log "Aplicando Kafka (KRaft)"
  kubectl apply -f "$LAB_MANIFESTS/kafka.yaml"
fi

if [[ "$LAB_NO_WAIT" != "1" ]]; then
  for t in redis mongodb kafka; do
    if ! is_skipped "$t"; then wait_rollout "statefulset/$t" lab-data 300s; fi
  done
fi
