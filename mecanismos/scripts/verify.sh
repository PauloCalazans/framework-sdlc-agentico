#!/bin/sh
# verify.sh [--task <task.md>] — ponto único de verificação do projeto. Só reporta; nunca conserta.
# Task com **Base:** <branch> (branch empilhada): enquanto essa branch não estiver na principal, as etapas
# comparam com ela; depois, com a principal.
# Etapas (as baratas primeiro): hooks → escopo → decisões → red → stack → skip (skip lê os JUnit que a stack produz).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/lib-agentic.sh"
cd "$agentic_raiz" || exit 1

task=""
[ "${1:-}" = "--task" ] && task=${2:-}
[ -n "$CMD_VERIFY_STACK" ] || agentic_falha "CMD_VERIFY_STACK não configurado em agentic/config (rode /bootstrap)"

mkdir -p agentic/.estado
lock="agentic/.estado/verify.lock"
if ! mkdir "$lock" 2>/dev/null; then
  pid=$(cat "$lock/pid" 2>/dev/null)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "verify já em execução (pid $pid)"
    exit 3
  fi
  rm -rf "$lock"
  mkdir "$lock" || exit 3
fi
echo $$ > "$lock/pid"
trap 'rm -rf "$lock"' EXIT INT TERM

falhas=""
etapa() {
  nome=$1; shift
  echo; echo "== $nome"
  if "$@"; then echo "-- $nome: OK"; else echo "-- $nome: FALHOU"; falhas="$falhas $nome"; fi
}

# Os githooks valem para qualquer autor, mas core.hooksPath é configuração local: um clone novo
# (outra máquina, agente de nuvem) roda sem eles e nada avisa.
verifica_hooks() {
  atual=$(git config core.hooksPath)
  [ "$atual" = "agentic/mecanismos/githooks" ] && { echo "githooks ligados"; return 0; }
  echo "githooks desligados neste clone (core.hooksPath = '${atual:-<vazio>}')."
  echo "Ligue com: git config core.hooksPath agentic/mecanismos/githooks (ação humana; o agente não altera as próprias proteções)."
  return 1
}
# Base única: todas as etapas comparam com a mesma base (a **Base:** da task empilhada, ainda não integrada,
# ou a principal), calculada uma vez, antes das etapas.
if [ -z "$task" ]; then
  branch=$(git symbolic-ref --short -q HEAD)
  [ -n "$branch" ] && task=$(grep -l "^\*\*Branch:\*\*[[:space:]]*$branch[[:space:]]*$" agentic/projeto/specs/*/tasks/*.md 2>/dev/null | head -n 1)
fi
if [ -n "$task" ]; then
  base_task=$(sed -n 's/^\*\*Base:\*\*[[:space:]]*//p' "$task" | head -n 1 | tr -d '\r`' | sed 's/[[:space:]]*$//')
  if [ -n "$base_task" ]; then
    ref=$(agentic_base_task "$task")
    if [ -n "$ref" ]; then
      AGENTIC_BASE=$ref; export AGENTIC_BASE
      echo; echo "base: $ref (branch empilhada, **Base:** da task)"
    else
      echo; echo "base: principal (**Base:** $base_task já integrada ou ausente)"
    fi
  fi
fi

etapa hooks verifica_hooks
if [ -n "$task" ]; then
  etapa escopo sh "$dir/verifica-escopo.sh" "$task"
else
  if [ -n "$(ls agentic/projeto/specs/*/tasks/*.md 2>/dev/null | head -n 1)" ]; then
    echo; echo "aviso: nenhuma task com **Branch:** ${branch:-?} — escopo não verificado (trilha rápida?)"
  fi
  echo; echo "== escopo: nenhuma task associada à branch (trilha rápida) — pulado"
fi
etapa decisoes sh "$dir/verifica-decisoes.sh"
etapa red sh "$dir/verifica-red.sh"
etapa stack sh -c "$CMD_VERIFY_STACK"
etapa skip sh "$dir/verifica-skip.sh"

echo
if [ -z "$falhas" ]; then
  echo "VERIFY: OK"
else
  echo "VERIFY: FALHOU em:$falhas"
  exit 1
fi
