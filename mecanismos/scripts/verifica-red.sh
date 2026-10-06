#!/bin/sh
# verifica-red.sh [base] — prova que cada commit test(red): (1) só tocou testes, (2) falhava de fato,
# (3) não teve asserções removidas depois. Roda os testes do RED num worktree isolado.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
base=${1:-$(agentic_base)}
[ -n "$base" ] || agentic_falha "sem base de comparação (a branch principal '$BRANCH_PRINCIPAL' existe?)"
git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"

reds=$(git log --format=%H --grep='^test(red):' "$base..HEAD") || agentic_falha "falha ao listar commits"
if [ -z "$reds" ]; then
  echo "verifica-red: nenhum commit test(red): na branch"
  exit 0
fi
[ -n "$CMD_TESTE" ] || agentic_falha "CMD_TESTE não configurado em .agentic/config"

conta_assercoes() {
  # shellcheck disable=SC2086
  git grep -c -E -e "$MARCADOR_ASSERCAO" "$1" -- $DIRS_TESTE 2>/dev/null \
    | awk -F: '{ s += $NF } END { print s + 0 }'
}

status=0
for c in $reds; do
  curto=$(git rev-parse --short "$c")

  arquivos=$(git diff-tree --no-commit-id --name-only -r "$c") || agentic_falha "falha ao listar arquivos do RED $curto"
  for f in $arquivos; do
    dentro=1
    for d in $DIRS_TESTE; do
      case "$f" in "$d"*) dentro=0 ;; esac
    done
    if [ "$dentro" -ne 0 ]; then
      echo "agentic: BLOQUEADO — RED $curto toca arquivo fora dos diretórios de teste: $f"
      status=1
    fi
  done

  wt=$(mktemp -d)
  rmdir "$wt"
  git worktree add -q --detach "$wt" "$c" || agentic_falha "não foi possível criar worktree para $curto"
  # Entre worktree add e remove não há saída via agentic_falha: o worktree é sempre removido.
  if [ -n "$CMD_PREPARAR_TESTE" ] && ! ( cd "$wt" && eval "$CMD_PREPARAR_TESTE" ) >/dev/null 2>&1; then
    echo "agentic: BLOQUEADO — CMD_PREPARAR_TESTE falhou no RED $curto; não há evidência."
    status=1
  elif ( cd "$wt" && eval "$CMD_TESTE" ) >/dev/null 2>&1; then
    echo "agentic: BLOQUEADO — os testes PASSAVAM no RED $curto: não é evidência de RED."
    status=1
  else
    echo "RED $curto: falhava (ok)"
  fi
  git worktree remove --force "$wt"

  a_red=$(conta_assercoes "$c")
  a_head=$(conta_assercoes HEAD)
  if [ "$a_head" -lt "$a_red" ]; then
    echo "agentic: BLOQUEADO — asserções diminuíram desde o RED $curto: $a_red -> $a_head"
    status=1
  fi
done
exit $status
