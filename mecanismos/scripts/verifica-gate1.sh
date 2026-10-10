#!/bin/sh
# verifica-gate1.sh [base] — coerência do Gate 1 delegado (agentic/auto-mode).
#   gate1: humano|delegado    (ausente = humano)
#   gate1_decisao: D<n>       (obrigatório com gate1: delegado; é a decisão do humano que registra a delegação)
# Falha se:
#   (1) gate1: delegado sem gate1_decisao, ou com decisão inexistente em agentic/projeto/decisoes.md;
#   (2) a branch tem commit "... aprovada (Gate 1 delegado — D<n>)" sem gate1: delegado no auto-mode, ou com
#       D<n> diferente de gate1_decisao.
# Só o humano edita agentic/auto-mode (deny de Edit), então o agente não consegue ligar a delegação sozinho.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
base=${1:-$(agentic_base)}

modo=$(agentic_auto_valor gate1); [ -n "$modo" ] || modo=humano
dec=$(agentic_auto_valor gate1_decisao | tr -d 'dD')
case "$modo" in humano|delegado) ;; *) agentic_falha "gate1: '$modo' inválido em agentic/auto-mode (use humano ou delegado)" ;; esac
status=0

if [ "$modo" = delegado ]; then
  if [ -z "$dec" ]; then
    echo "agentic: BLOQUEADO — gate1: delegado exige gate1_decisao: D<n> em agentic/auto-mode (a decisão do humano que registra a delegação)"
    status=1
  elif ! grep -qE "^### D$dec([^0-9]|\$)" agentic/projeto/decisoes.md 2>/dev/null; then
    echo "agentic: BLOQUEADO — gate1_decisao: D$dec não existe em agentic/projeto/decisoes.md"
    status=1
  fi
fi

if [ -n "$base" ] && git rev-parse --verify -q "$base^{commit}" >/dev/null; then
  git log --format='%h %s' "$base..HEAD" | grep -E 'Gate 1 delegado' | while IFS= read -r linha; do
    d=$(printf '%s' "$linha" | sed -n 's/.*Gate 1 delegado[^D]*D\([0-9][0-9]*\).*/\1/p')
    if [ "$modo" != delegado ]; then
      echo "agentic: BLOQUEADO — ${linha%% *} registra Gate 1 delegado, mas agentic/auto-mode não tem gate1: delegado"
      exit 1
    elif [ "$d" != "$dec" ]; then
      echo "agentic: BLOQUEADO — ${linha%% *} cita D${d:-?}, mas gate1_decisao é D${dec:-?}"
      exit 1
    fi
  done || status=1
fi

[ "$status" -eq 0 ] && echo "verifica-gate1: OK (gate1: $modo${dec:+, D$dec})"
exit $status
