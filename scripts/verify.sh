#!/bin/sh
# verify.sh do framework — roda todas as suítes *.Tests.sh. Só reporta; nunca conserta.
raiz=$(cd "$(dirname "$0")/.." && pwd)
falhas=0
suites=$(find "$raiz/mecanismos" "$raiz/adapters" "$raiz/bootstrap" -name '*.Tests.sh' 2>/dev/null | sort)
for t in $suites; do
  printf '\n== %s\n' "${t#"$raiz"/}"
  sh "$t" || falhas=$((falhas + 1))
done
printf '\n'
if [ "$falhas" -eq 0 ]; then
  echo "verify: OK"
else
  echo "verify: $falhas suíte(s) falharam"
  exit 1
fi
