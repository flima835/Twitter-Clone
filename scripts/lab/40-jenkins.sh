#!/usr/bin/env bash
# Jenkins via Helm (chart oficial jenkinsci). Versão: LAB_JENKINS_CHART_VERSION.
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if is_skipped jenkins; then log "jenkins: ignorado (LAB_SKIP)"; exit 0; fi
need_cmd helm

ver=(); [[ -n "${LAB_JENKINS_CHART_VERSION:-}" ]] && ver=(--version "$LAB_JENKINS_CHART_VERSION")

log "Instalando Jenkins"
helm repo add jenkins https://charts.jenkins.io --force-update >/dev/null
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins --create-namespace \
  -f "$LAB_MANIFESTS/jenkins-values.yaml" \
  --set-string controller.admin.password="$(lab_secret JENKINS_ADMIN_PASSWORD)" \
  ${ver[@]+"${ver[@]}"} \
  --wait --timeout 15m
