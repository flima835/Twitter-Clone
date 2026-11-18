#!/usr/bin/env bash
# Funções e configuração compartilhadas do lab Kubernetes do Twitter-Clone.
# Todos os scripts em scripts/lab/ fazem `source` deste arquivo.
# shellcheck disable=SC2034  # variáveis usadas pelos scripts que fazem source

LAB_ROOT="${LAB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LAB_MANIFESTS="$LAB_ROOT/k8s/lab"
LAB_STATE_DIR="${LAB_STATE_DIR:-$HOME/.twitter-lab}"
LAB_BIN_DIR="${LAB_BIN_DIR:-$HOME/bin}"

# ---- Configuração (sobrescreva via variáveis de ambiente) -------------------
# auto     = usa o contexto kubectl atual se estiver acessível; senão cria um cluster kind
# kind     = sempre cria/usa um cluster kind local (contexto kind-<LAB_CLUSTER_NAME>)
# existing = exige um contexto kubectl já acessível (ex.: GKE)
LAB_CLUSTER_MODE="${LAB_CLUSTER_MODE:-auto}"
LAB_CLUSTER_NAME="${LAB_CLUSTER_NAME:-twitter-lab}"
LAB_SKIP="${LAB_SKIP:-}"                          # ex.: LAB_SKIP="gitlab kargo"
LAB_PORT_FORWARD="${LAB_PORT_FORWARD:-1}"         # 0 = não abrir port-forwards
LAB_GITLAB_URL="${LAB_GITLAB_URL:-http://localhost:8083}"
LAB_ARGOCD_SCRIPT="${LAB_ARGOCD_SCRIPT:-0}"       # 1 = usar scripts/install-argocd.sh
LAB_NO_WAIT="${LAB_NO_WAIT:-0}"                   # 1 = aplica e não espera ficar pronto

LAB_TOOLS="argocd kargo jenkins gitlab redis mongodb kafka"

mkdir -p "$LAB_STATE_DIR" "$LAB_BIN_DIR"
export PATH="$LAB_BIN_DIR:$PATH"

# ---- Log -------------------------------------------------------------------
log()  { printf '\033[1;34m[lab]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[lab][aviso]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[lab][erro]\033[0m %s\n' "$*" >&2; exit 1; }

# `type -P` só enxerga binários (ignora os wrappers kubectl/helm definidos abaixo).
need_cmd() { type -P "$1" >/dev/null 2>&1 || die "'$1' não encontrado no PATH. ${2:-}"; }

# ---- Contexto fixo do lab ------------------------------------------------------
# Depois que 00-cluster.sh grava o contexto do lab (state.env: CONTEXT), kubectl e helm
# passam a usá-lo sempre, mesmo que o contexto atual do kubeconfig mude (ex.: subir-lab.sh
# trabalhando no GKE). 00-cluster.sh desliga isso com LAB_PIN_CONTEXT=0.
LAB_PIN_CONTEXT="${LAB_PIN_CONTEXT:-1}"
_lab_ctx() { if [[ "${LAB_PIN_CONTEXT:-1}" == "1" ]]; then kv_get CONTEXT; fi; }
kubectl() {
  local c; c="$(_lab_ctx)"
  if [[ -n "$c" ]]; then command kubectl --context "$c" "$@"; else command kubectl "$@"; fi
}
helm() {
  local c; c="$(_lab_ctx)"
  if [[ -n "$c" ]]; then command helm --kube-context "$c" "$@"; else command helm "$@"; fi
}

is_skipped() { [[ " $LAB_SKIP " == *" $1 "* ]]; }

# ---- Estado e credenciais (arquivo fora do repositório) ----------------------
LAB_STATE_FILE="$LAB_STATE_DIR/state.env"

kv_get() {
  [[ -f "$LAB_STATE_FILE" ]] || return 0
  grep -E "^$1=" "$LAB_STATE_FILE" | tail -n1 | cut -d= -f2- || true
}

kv_set() {
  touch "$LAB_STATE_FILE"; chmod 600 "$LAB_STATE_FILE"
  { grep -vE "^$1=" "$LAB_STATE_FILE" || true; echo "$1=$2"; } > "$LAB_STATE_FILE.tmp"
  mv "$LAB_STATE_FILE.tmp" "$LAB_STATE_FILE"
}

# Devolve o segredo guardado; se não existir, gera um e persiste.
lab_secret() {
  local val
  val="$(kv_get "$1")"
  if [[ -z "$val" ]]; then
    val="$(openssl rand -hex 12)"
    kv_set "$1" "$val"
  fi
  printf '%s' "$val"
}

# Hash bcrypt (usado pelo admin do Kargo).
bcrypt_hash() {
  local pass="$1"
  if command -v htpasswd >/dev/null 2>&1; then
    htpasswd -bnBC 10 "" "$pass" | tr -d ':\n'
  elif command -v docker >/dev/null 2>&1; then
    docker run --rm httpd:2 htpasswd -bnBC 10 "" "$pass" | tr -d ':\n'
  elif python3 -c 'import bcrypt' >/dev/null 2>&1; then
    python3 -c 'import bcrypt,sys; print(bcrypt.hashpw(sys.argv[1].encode(), bcrypt.gensalt(10)).decode())' "$pass"
  else
    die "Preciso de htpasswd, docker ou python3+bcrypt para gerar o hash do Kargo."
  fi
}

wait_rollout() { # <tipo/nome> <namespace> [timeout]
  kubectl -n "$2" rollout status "$1" --timeout="${3:-300s}"
}

ensure_ns() { kubectl create namespace "$1" --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }
