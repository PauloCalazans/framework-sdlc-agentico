#!/bin/sh
# verifica-decisoes.sh [base] — integridade do registro de decisões (agentic/projeto/decisoes.md):
#   (1) toda referência "D<n>" em agentic/projeto/ (exceto o próprio registro) e em agentic/auto-mode
#       aponta para um "### D<n>" existente (vigente ou revogada);
#   (2) nenhuma decisão presente na base (merge-base com a principal) desapareceu do registro em HEAD —
#       decisão nunca é apagada, só movida para "Decisões revogadas" (cobre a perda silenciosa por conflito
#       de merge, que os testes da stack não enxergam).
# Sem registro (agentic/projeto/decisoes.md ausente): pulado.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
reg=agentic/projeto/decisoes.md
if [ ! -f "$reg" ]; then
  echo "verifica-decisoes: sem $reg — pulado"
  exit 0
fi

# ids <arquivo>: números das decisões definidas ("### D<n>"), um por linha, sem repetição.
ids() { sed -n 's/^### D\([0-9][0-9]*\)\([^0-9].*\)\{0,1\}$/\1/p' | sort -u; }

definidas=$(ids < "$reg")
status=0

# (1) referências órfãs
refs=$(
  {
    find agentic/projeto -type f -name '*.md' ! -path "$reg" 2>/dev/null
    [ -f agentic/auto-mode ] && echo agentic/auto-mode
  } | while IFS= read -r f; do
    grep -o -E '(^|[^A-Za-z0-9_])D[0-9]+([^A-Za-z0-9_]|$)' "$f" 2>/dev/null \
      | sed -n 's/^[^D]*D\([0-9][0-9]*\).*$/\1/p' | sed "s|\$|\t$f|"
  done | sort -u
)
orfas=$(printf '%s\n' "$refs" | while IFS="$(printf '\t')" read -r n f; do
  [ -n "$n" ] || continue
  printf '%s\n' "$definidas" | grep -qx "$n" || printf 'D%s (em %s)\n' "$n" "$f"
done)
if [ -n "$orfas" ]; then
  echo "agentic: BLOQUEADO — referência a decisão inexistente em $reg:"
  printf '%s\n' "$orfas" | sed 's/^/  /'
  status=1
fi

# (2) decisão da base que sumiu
base=${1:-$(agentic_base)}
if [ -z "$base" ]; then
  echo "degradado: sem base de comparação — perda de decisões não verificada"
elif ! git rev-parse --verify -q "$base^{commit}" >/dev/null; then
  agentic_falha "base inválida: $base"
elif git cat-file -e "$base:$reg" 2>/dev/null; then
  perdidas=$(git show "$base:$reg" | ids | while IFS= read -r n; do
    printf '%s\n' "$definidas" | grep -qx "$n" || printf 'D%s\n' "$n"
  done)
  if [ -n "$perdidas" ]; then
    echo "agentic: BLOQUEADO — decisão(ões) da base ausente(s) em $reg (decisão não se apaga; revogue-a): $(printf '%s' "$perdidas" | tr '\n' ' ')"
    status=1
  fi
fi

[ "$status" -eq 0 ] && echo "verifica-decisoes: OK"
exit $status
