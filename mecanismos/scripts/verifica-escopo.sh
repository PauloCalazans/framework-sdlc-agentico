#!/bin/sh
# verifica-escopo.sh <task.md> [base] — falha se a branch altera arquivo fora da seção "## Arquivos" da task.
# Para ampliar o escopo, atualize a lista da task num commit docs(task): (visível na revisão e no Gate 2).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
task=${1:-}
[ -n "$task" ] && [ -f "$task" ] || { echo "uso: verifica-escopo.sh <task.md relativo à raiz> [base]" >&2; exit 2; }
base=${2:-$(agentic_base)}
[ -n "$base" ] || agentic_falha "sem base de comparação (a branch principal '$BRANCH_PRINCIPAL' existe?)"
git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"

set -f  # padrões com glob não podem ser expandidos contra o disco
padroes=$(sed -n '/^## Arquivos/,/^## /p' "$task" \
  | sed -n 's/^[[:space:]]*-[[:space:]]*`\{0,1\}\([^` ]*\)`\{0,1\}.*/\1/p')
dir_spec=$(dirname "$(dirname "$task")")

lista=$( { git -c core.quotepath=off diff --no-renames --name-only "$base" HEAD \
  && git -c core.quotepath=off diff --no-renames --name-only HEAD \
  && git -c core.quotepath=off ls-files --others --exclude-standard; } ) \
  || agentic_falha "falha ao listar arquivos alterados"

fora=$(
  printf '%s\n' "$lista" \
  | sort -u | while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in "$dir_spec"/*) continue ;; esac
      case "$f" in .agentic/verify.lock/*|.agentic/execucao/*) continue ;; esac
      dentro=1
      for p in $padroes; do
        case "$f" in $p) dentro=0; break ;; esac
      done
      [ "$dentro" -eq 0 ] || printf '  %s\n' "$f"
    done
)

if [ -n "$fora" ]; then
  echo "agentic: BLOQUEADO — arquivos fora do escopo de $task:"
  printf '%s\n' "$fora"
  echo "Se a ampliação for legítima, acrescente-os em '## Arquivos' via commit docs(task):."
  exit 1
fi
echo "escopo: OK ($task)"
