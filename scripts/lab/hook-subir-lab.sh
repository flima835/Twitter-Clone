#!/usr/bin/env bash
# Insere em scripts/subir-lab.sh a chamada do lab-up.sh, ANTES do passo "### 7." (o último passo
# termina com `kubectl get service ... -w`, que bloqueia; um bloco no fim nunca rodaria).
# Idempotente. Faz backup em subir-lab.sh.bak antes de alterar.
set -Eeuo pipefail

TARGET="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/subir-lab.sh"
MARK="# >>> lab-k8s (twitter-clone) >>>"

[[ -f "$TARGET" ]] || { echo "Não achei $TARGET"; exit 1; }

if grep -qF "$MARK" "$TARGET"; then
  echo "subir-lab.sh já chama o lab-up.sh. Nada a fazer."
  exit 0
fi

BLOCK_FILE="$(mktemp)"
cat > "$BLOCK_FILE" <<'EOF'
# >>> lab-k8s (twitter-clone) >>>
echo -e "${GREEN}### 6.5 Subindo o lab Kubernetes (ArgoCD, Kargo, Jenkins, GitLab, Redis, MongoDB, Kafka) ###${NC}"
# O GKE do Terraform é pequeno (1x e2-medium), então o lab roda num cluster kind local.
# Para usar o GKE (depois de aumentar o node pool): LAB_CLUSTER_MODE=existing
LAB_CLUSTER_MODE="${LAB_CLUSTER_MODE:-kind}" bash scripts/lab-up.sh || echo -e "${YELLOW}lab-k8s terminou com avisos (veja scripts/lab-status.sh)${NC}"
# <<< lab-k8s (twitter-clone) <<<

EOF

cp "$TARGET" "$TARGET.bak"
if grep -qE '### 7\.' "$TARGET.bak"; then
  awk -v bf="$BLOCK_FILE" '/### 7\./ && !done { while ((getline line < bf) > 0) print line; done=1 } { print }' "$TARGET.bak" > "$TARGET"
  echo "OK: bloco inserido antes do passo 7 em $TARGET (backup em $TARGET.bak)"
else
  { cat "$TARGET.bak"; echo; cat "$BLOCK_FILE"; } > "$TARGET"
  echo "OK: bloco adicionado ao final de $TARGET (backup em $TARGET.bak)."
  echo "ATENÇÃO: não achei o passo '### 7.'; confira se o bloco não ficou depois de um comando que bloqueia."
fi
rm -f "$BLOCK_FILE"
