#!/bin/sh
# Testes do scripts/verify.sh (runner das suítes do framework), numa árvore temporária.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

arvore() { # arvore: cria raiz temporária com scripts/verify.sh e imprime o caminho
  a=$(mktemp -d)
  mkdir -p "$a/scripts" "$a/mecanismos" "$a/adapters" "$a/bootstrap"
  cp "$dir/verify.sh" "$a/scripts/verify.sh"
  printf '%s\n' "$a"
}

a=$(arvore)
tl_espera 1 "zero suítes encontradas falha" sh "$a/scripts/verify.sh"
tl_contem "nenhuma suíte" "explica a ausência de suítes"

a=$(arvore); printf 'exit 0\n' > "$a/mecanismos/ok.Tests.sh"
tl_espera 0 "suíte verde passa" sh "$a/scripts/verify.sh"
tl_contem "verify: OK" "imprime verify: OK"

a=$(arvore); printf 'exit 0\n' > "$a/mecanismos/ok.Tests.sh"; printf 'exit 1\n' > "$a/bootstrap/ruim.Tests.sh"
tl_espera 1 "suíte vermelha falha" sh "$a/scripts/verify.sh"
tl_contem "1 suíte(s) falharam" "conta a suíte que falhou"

a=$(mktemp -d)/"com espaço"; mkdir -p "$a/scripts" "$a/mecanismos"; cp "$dir/verify.sh" "$a/scripts/verify.sh"
printf 'exit 0\n' > "$a/mecanismos/ok.Tests.sh"
tl_espera 0 "raiz com espaço no caminho: roda a suíte" sh "$a/scripts/verify.sh"

tl_fim
