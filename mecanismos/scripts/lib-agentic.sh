# lib-agentic.sh — configuração e funções comuns aos hooks e scripts do framework.
# Carregar com ". lib-agentic.sh". Lê <raiz>/agentic/config sobre os padrões abaixo.
agentic_raiz=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "agentic: BLOQUEADO — fora de um repositório git" >&2
  exit 1
}

BRANCH_PRINCIPAL="main"
BRANCHES_PROTEGIDAS="main master"
DIRS_TESTE="tests/ test/"
MARCADOR_DESABILITADO=""
MARCADOR_ASSERCAO="assert|expect"
RELATORIO_TESTES=""
CMD_PREPARAR_TESTE=""
CMD_TESTE=""
CMD_TESTE_ARQUIVO=""
CMD_VERIFY_STACK=""
GITLEAKS_BIN="gitleaks"

if [ -f "$agentic_raiz/agentic/config" ]; then
  . "$agentic_raiz/agentic/config"
fi

# agentic_branch_protegida <branch>: retorna 0 se a branch está em BRANCHES_PROTEGIDAS.
agentic_branch_protegida() {
  for agentic_b in $BRANCHES_PROTEGIDAS; do
    [ "$1" = "$agentic_b" ] && return 0
  done
  return 1
}

# agentic_falha <mensagem>: bloqueia com mensagem padronizada.
agentic_falha() {
  printf 'agentic: BLOQUEADO — %s\n' "$*" >&2
  exit 1
}

# agentic_base: ponto de divergência entre HEAD e a branch principal. Sem a principal local (clone de CI
# ou de agente de nuvem, que só traz origin/<principal>), usa a remota. Com AGENTIC_BASE (branch empilhada,
# definido pelo verify.sh a partir do **Base:** da task), o ponto de divergência é com essa branch.
agentic_base() {
  if [ -n "${AGENTIC_BASE:-}" ]; then
    git merge-base HEAD "$AGENTIC_BASE" 2>/dev/null
    return
  fi
  git merge-base HEAD "$BRANCH_PRINCIPAL" 2>/dev/null || git merge-base HEAD "origin/$BRANCH_PRINCIPAL" 2>/dev/null
}

# agentic_principal_ref: a branch principal local ou, sem ela, a remota. Vazio se nenhuma existir.
agentic_principal_ref() {
  for agentic_p in "$BRANCH_PRINCIPAL" "origin/$BRANCH_PRINCIPAL"; do
    git rev-parse --verify -q "$agentic_p^{commit}" >/dev/null && { printf '%s\n' "$agentic_p"; return 0; }
  done
  return 1
}
