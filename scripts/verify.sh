#!/bin/sh
# verify.sh do framework — roda todas as suítes *.Tests.sh. Só reporta; nunca conserta.
# Zero suítes encontradas é falha (fail-closed): um verify que não testa nada não pode dizer OK.
raiz=$(cd "$(dirname "$0")/.." && pwd)
falhas=0
total=0
lista=$(mktemp)
for d in mecanismos adapters bootstrap scripts; do
  [ -d "$raiz/$d" ] && find "$raiz/$d" -name '*.Tests.sh'
done | sort > "$lista"
while IFS= read -r t; do
  [ -n "$t" ] || continue
  total=$((total + 1))
  printf '\n== %s\n' "${t#"$raiz"/}"
  sh "$t" </dev/null || falhas=$((falhas + 1))
done < "$lista"
rm -f "$lista"
printf '\n'
if [ "$total" -eq 0 ]; then
  echo "verify: FALHOU — nenhuma suíte *.Tests.sh encontrada em $raiz"
  exit 1
fi
if [ "$falhas" -eq 0 ]; then
  echo "verify: OK"
else
  echo "verify: $falhas suíte(s) falharam"
  exit 1
fi
