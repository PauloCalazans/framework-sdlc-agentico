#!/bin/sh
# verifica-decisoes.sh [base] — integridade do registro de decisões (agentic/projeto/decisoes.md):
#   (1) toda referência "D<n>" em agentic/projeto/ (exceto o próprio registro) e em agentic/auto-mode
#       aponta para um "### D<n>" existente (vigente ou revogada);
#   (2) nenhuma decisão presente na base (merge-base com a principal) desapareceu do registro em HEAD —
#       decisão nunca é apagada, só movida para "Decisões revogadas" (cobre a perda silenciosa por conflito
#       de merge, que os testes da stack não enxergam);
#   (3) "gate1: D<n>" em agentic/auto-mode (Gate 1 delegado ao orquestrador) aponta uma decisão vigente;
#   (4) todo commit da branch que registra "Gate 1 delegado, D<n>" tem delegação vigente: auto-mode com
#       "enabled: true" e "gate1: D<n>" (a mesma decisão), D<n> vigente — ou um Gate 1 humano registrado na
#       branch para o mesmo artefato ("<tipo>: <nome> aprovada (Gate 1)").
# Sem registro (agentic/projeto/decisoes.md ausente): pulado, salvo Gate 1 delegado no auto-mode (bloqueia).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
reg=agentic/projeto/decisoes.md
if [ ! -f "$reg" ]; then
  if [ -n "$(sed -n 's/^gate1:[[:space:]]*\([^[:space:]]\)/\1/p' agentic/auto-mode 2>/dev/null)" ]; then
    echo "agentic: BLOQUEADO — agentic/auto-mode delega o Gate 1, mas não há decisão: sem $reg"
    exit 1
  fi
  echo "verifica-decisoes: sem $reg — pulado"
  exit 0
fi

# ids <arquivo>: números das decisões definidas ("### D<n>"), um por linha, sem repetição.
ids() { sed -n 's/^### D\([0-9][0-9]*\)\([^0-9].*\)\{0,1\}$/\1/p' | sort -u; }

definidas=$(ids < "$reg")
status=0

# ausentes: lê números (ou "<n>\t<arquivo>") e imprime os que não estão em $definidas. Um awk para a lista toda:
# um processo por item custava dezenas de segundos em projeto com centenas de artefatos.
ausentes() {
  DEFINIDAS=$definidas awk -F'\t' -v formato="$1" '
    BEGIN { n = split(ENVIRON["DEFINIDAS"], d, "\n"); for (i = 1; i <= n; i++) def[d[i] ""] = 1 }
    $1 != "" && !(($1 "") in def) { printf formato "\n", $1, $2 }'
}

# (1) referências órfãs — uma varredura para todos os arquivos; o /dev/null faz o grep imprimir o nome do arquivo.
padrao='(^|[^A-Za-z0-9_])D[0-9]+([^A-Za-z0-9_]|$)'
refs=$(
  {
    find agentic/projeto -type f -name '*.md' ! -path "$reg" -exec grep -o -E "$padrao" /dev/null {} + 2>/dev/null
    [ -f agentic/auto-mode ] && grep -o -E "$padrao" /dev/null agentic/auto-mode 2>/dev/null
  } | awk '
    { sub(/\r$/, "") }
    match($0, /:[^A-Za-z0-9_]?D[0-9]+[^A-Za-z0-9_]?$/) {
      arquivo = substr($0, 1, RSTART - 1); n = substr($0, RSTART + 1)
      sub(/^[^D]*D/, "", n); sub(/[^0-9].*$/, "", n)
      print n "\t" arquivo
    }' | sort -u
)
orfas=$(printf '%s\n' "$refs" | ausentes 'D%s (em %s)')
if [ -n "$orfas" ]; then
  echo "agentic: BLOQUEADO — referência a decisão inexistente em $reg:"
  printf '%s\n' "$orfas" | sed 's/^/  /'
  status=1
fi

# (2) decisão da base que sumiu
if [ -n "${1:-}" ]; then
  base=$(git merge-base HEAD "$1") || agentic_falha "base inválida: $1"
else
  base=$(agentic_base)
fi
if [ -z "$base" ]; then
  echo "degradado: sem base de comparação — perda de decisões não verificada"
elif ! git rev-parse --verify -q "$base^{commit}" >/dev/null; then
  agentic_falha "base inválida: $base"
elif git cat-file -e "$base:$reg" 2>/dev/null; then
  perdidas=$(git show "$base:$reg" | ids | ausentes 'D%s')
  if [ -n "$perdidas" ]; then
    echo "agentic: BLOQUEADO — decisão(ões) da base ausente(s) em $reg (decisão não se apaga; revogue-a): $(printf '%s' "$perdidas" | tr '\n' ' ')"
    status=1
  fi
fi

# (3) delegação do Gate 1
vigentes=$(sed -n '/^## Vigentes/,/^## /p' "$reg" | ids)
gate1=""; ligado=""
if [ -f agentic/auto-mode ]; then
  gate1=$(sed -n 's/^gate1:[[:space:]]*//p' agentic/auto-mode | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*$//')
  grep -q '^enabled:[[:space:]]*true' agentic/auto-mode && ligado=1
fi
delegada=""
if [ -n "$gate1" ]; then
  n=${gate1#D}
  case "$gate1:$n" in
    D*:""|D*:*[!0-9]*|[!D]*) echo "agentic: BLOQUEADO — gate1: em agentic/auto-mode precisa ser D<n> ou vazio (encontrado: $gate1)"; status=1 ;;
    *) if printf '%s\n' "$vigentes" | grep -qx "$n"; then delegada=$n
       else echo "agentic: BLOQUEADO — agentic/auto-mode delega o Gate 1 pela D$n, que não está vigente em $reg"; status=1; fi ;;
  esac
fi

# (4) commits de registro do Gate 1 delegado
if [ -n "$base" ]; then
  assuntos=$(git log --format='%s' "$base..HEAD")
  invalidos=$(git log --format='%h %s' "$base..HEAD" | grep -F 'Gate 1 delegado' | while IFS= read -r c; do
    n=$(printf '%s\n' "$c" | sed -n 's/.*Gate 1 delegado, D\([0-9][0-9]*\)).*/\1/p')
    { [ -n "$n" ] && [ -n "$ligado" ] && [ "$n" = "$delegada" ]; } && continue
    # Gate 1 humano do mesmo artefato registrado na mesma branch, em qualquer posição ("<tipo>: <nome> aprovada (Gate 1)") substitui o delegado.
    assunto=${c#* }
    printf '%s\n' "$assuntos" | grep -qxF "${assunto%% (Gate 1 delegado*} (Gate 1)" && continue
    printf '  %s\n' "$c"
  done)
  if [ -n "$invalidos" ]; then
    echo "agentic: BLOQUEADO — commit registra Gate 1 delegado sem delegação vigente (agentic/auto-mode com enabled: true e gate1: D<n>, D<n> vigente):"
    printf '%s\n' "$invalidos"
    status=1
  fi
fi

[ "$status" -eq 0 ] && echo "verifica-decisoes: OK"
exit $status
