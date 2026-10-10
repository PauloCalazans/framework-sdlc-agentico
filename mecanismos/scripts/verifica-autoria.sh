#!/bin/sh
# verifica-autoria.sh [--publicar] [base] — autoria por papel e independência do revisor.
# Convenção (trailers de commit, uma linha cada):
#   Papel: dominio|arquiteto|testes|dev|revisor|orquestrador
#   Agente: <produto>/<modelo>          (ex.: Kiro/Claude Sonnet 5 — sem nome de persona)
# Regras:
#   (1) todo commit test(red)/feat(green)/refactor/fix da branch traz Papel e Agente, e o Papel é compatível
#       com o tipo (test(red)=testes; feat(green), refactor=dev; fix=dev ou testes);
#   (2) o registro da revisão é um commit com os trailers
#         Revisor: <produto>/<modelo>
#         Veredito: APROVADO|DEVOLVIDO
#       (convencionalmente o docs(task) em-revisão, commitado pelo orquestrador; o revisor não escreve);
#   (3) independência: o Revisor difere do Agente de todo commit com Papel testes ou dev. REVISOR_DISTINTO_POR
#       (agentic/config) = agente (padrão: produto/modelo diferentes) ou produto (só o produto precisa diferir);
#   (4) --publicar (antes do push/PR): exige registro de revisão APROVADO posterior ao último commit de trabalho.
# Imprime o resumo Papel → Agente para colar no PR. Sem commits de trabalho na branch: nada a verificar.
# OPT-IN: AUTORIA em agentic/config = desligada (padrão: não verifica nada) | aviso (só avisa, nunca bloqueia) |
# exigida (bloqueia). Pensado para times multiagente; quem usa um só agente deixa desligada, sem editar o script.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
case "${AUTORIA:-desligada}" in
  desligada) echo "verifica-autoria: desligada (AUTORIA em agentic/config: aviso | exigida)"; exit 0 ;;
  aviso|exigida) ;;
  *) agentic_falha "AUTORIA='$AUTORIA' inválido em agentic/config (use desligada, aviso ou exigida)" ;;
esac
publicar=0
[ "${1:-}" = "--publicar" ] && { publicar=1; shift; }
base=${1:-$(agentic_base)}
if [ -z "$base" ]; then echo "degradado: sem base de comparação — autoria não verificada"; exit 0; fi
git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"
dist=${REVISOR_DISTINTO_POR:-agente}
case "$dist" in agente|produto) ;; *) agentic_falha "REVISOR_DISTINTO_POR='$dist' inválido (use agente ou produto)" ;; esac

trailer() { git log -1 --format=%B "$1" | git interpret-trailers --parse | sed -n "s/^$2:[[:space:]]*//p" | tail -n 1 | tr -d '\r'; }
produto() { printf '%s' "${1%%/*}"; }

status=0
probs=$(mktemp)
problema() { printf '%s\n' "$*" >> "$probs"; status=1; }
resumo=$(mktemp); trab=$(mktemp)
i=0; ult_trab=0; ult_rev=0; ult_ver=""; rev_agente=""
for c in $(git log --reverse --no-merges --format=%H "$base..HEAD"); do
  i=$((i + 1)); curto=$(git rev-parse --short "$c"); s=$(git log -1 --format=%s "$c")
  tipo=""
  case "$s" in
    "test(red)"*) tipo=testes ;;
    "feat(green)"*|"refactor:"*|"refactor("*) tipo=dev ;;
    "fix:"*|"fix("*) tipo=fix ;;
  esac
  if [ -n "$tipo" ]; then
    papel=$(trailer "$c" Papel); agente=$(trailer "$c" Agente)
    if [ -z "$papel" ] || [ -z "$agente" ]; then
      problema "$curto ($s) sem trailers Papel: e Agente: <produto>/<modelo>"; status=1
    else
      ok=1
      case "$tipo:$papel" in testes:testes|dev:dev|fix:dev|fix:testes) ;; *) ok=0 ;; esac
      if [ "$ok" -eq 0 ]; then
        problema "$curto ($s) com Papel: $papel incompatível com o tipo do commit"; status=1
      fi
      case "$agente" in */*) ;; *) problema "$curto com Agente: '$agente' fora do formato <produto>/<modelo>"; status=1 ;; esac
      printf '%s\t%s\n' "$papel" "$agente" >> "$resumo"
      printf '%s\t%s\t%s\n' "$curto" "$papel" "$agente" >> "$trab"
    fi
    ult_trab=$i
  fi
  r=$(trailer "$c" Revisor)
  if [ -n "$r" ]; then
    ult_rev=$i; rev_agente=$r; ult_ver=$(trailer "$c" Veredito)
    printf 'revisor\t%s\n' "$r" >> "$resumo"
    case "$r" in */*) ;; *) problema "$curto com Revisor: '$r' fora do formato <produto>/<modelo>"; status=1 ;; esac
  fi
done

# independência do revisor frente a quem escreveu RED/GREEN
if [ -n "$rev_agente" ]; then
  while IFS="$(printf '\t')" read -r curto papel agente; do
    [ -n "$curto" ] || continue
    if [ "$dist" = produto ]; then a=$(produto "$agente"); b=$(produto "$rev_agente"); else a=$agente; b=$rev_agente; fi
    if [ "$a" = "$b" ]; then
      problema "revisor ($rev_agente) não é independente de $curto (Papel: $papel, Agente: $agente); REVISOR_DISTINTO_POR=$dist"
      status=1
    fi
  done < "$trab"
fi

if [ "$publicar" -eq 1 ] && [ "$ult_trab" -gt 0 ]; then
  if [ "$ult_rev" -eq 0 ]; then
    problema "sem registro de revisão (trailers Revisor: e Veredito:) para publicar"; status=1
  elif [ "$ult_rev" -lt "$ult_trab" ]; then
    problema "a revisão é anterior ao último commit de trabalho; revise de novo antes de publicar"; status=1
  elif [ "$ult_ver" != APROVADO ]; then
    problema "último Veredito: '${ult_ver:-ausente}' (precisa ser APROVADO) para publicar"; status=1
  fi
elif [ "$ult_trab" -gt 0 ] && [ "$ult_rev" -eq 0 ]; then
  echo "aviso: ainda sem registro de revisão (Revisor:/Veredito:) — exigido na publicação (--publicar)"
fi

if [ -s "$resumo" ]; then
  echo "Autoria (Papel → Agente):"
  sort -u "$resumo" | awk -F'\t' '{ printf "  - %s: %s\n", $1, $2 }'
fi
rm -f "$resumo" "$trab"
if [ -s "$probs" ]; then
  if [ "$AUTORIA" = exigida ]; then sed 's/^/agentic: BLOQUEADO — /' "$probs"; rm -f "$probs"; exit 1; fi
  sed 's/^/aviso: /' "$probs"
fi
rm -f "$probs"
echo "verifica-autoria: OK ($AUTORIA)"
exit 0
