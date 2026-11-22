#!/bin/sh
# red-junit.sh '<glob dos XML>' -- <comando…> — ajuda opcional para TESTE_<n>_COMANDO, usada com TESTE_<n>_RC_RED="1".
# Roda o comando (o código de saída dele é ignorado), expande o glob DEPOIS e decide pelo JUnit XML gerado:
#   1   (RED): pelo menos um <testcase> e pelo menos um <failure>;
#   0        : casos rodaram e nenhum tem <failure> nem <error>;
#   126      : nenhum XML, zero <testcase>, ou <error> sem <failure> (compilação, coleta, fixture: nada foi provado).
# Sem "--" ou sem comando: 126, com o uso em stderr. Imprime "red-junit: casos <c> failure <f> error <e> -> <rc>".
# Limite declarado: no JUnit, exceção lançada no corpo do teste também é <failure>.
if [ $# -lt 3 ] || [ "$2" != "--" ]; then
  echo "uso: red-junit.sh '<glob dos XML>' -- <comando…>" >&2
  exit 126
fi
rj_glob=$1
shift 2
"$@"

# rj_conta <elemento> <arquivo>: ocorrências da tag de abertura (não casa atributos como failures="0").
rj_conta() { grep -oE "<$1([[:space:]/>]|\$)" "$2" | wc -l | tr -d ' '; }

rj_casos=0; rj_fal=0; rj_err=0
set +f
# O padrão é expandido como glob; os nomes resultantes (mesmo com espaço) não são re-divididos.
# shellcheck disable=SC2086
for rj_a in $rj_glob; do
  [ -f "$rj_a" ] || continue
  rj_casos=$((rj_casos + $(rj_conta testcase "$rj_a")))
  rj_fal=$((rj_fal + $(rj_conta failure "$rj_a")))
  rj_err=$((rj_err + $(rj_conta error "$rj_a")))
done
if [ "$rj_casos" -gt 0 ] && [ "$rj_fal" -gt 0 ]; then
  rj_rc=1
elif [ "$rj_casos" -gt 0 ] && [ "$rj_err" -eq 0 ]; then
  rj_rc=0
else
  rj_rc=126
fi
echo "red-junit: casos $rj_casos failure $rj_fal error $rj_err -> $rj_rc"
exit $rj_rc
