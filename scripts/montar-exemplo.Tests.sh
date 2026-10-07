#!/bin/sh
# Testes do scripts/montar-exemplo.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"
montar="$dir/montar-exemplo.sh"

dest=$(mktemp -d); rmdir "$dest"
tl_espera 0 "monta o exemplo python" sh "$montar" python-cli-novo "$dest"
tl_espera 0 "destino é repositório git com main" git -C "$dest" rev-parse --verify -q main
tl_espera 0 "kit instalado" test -f "$dest/agentic/mecanismos/scripts/verify.sh"
tl_espera 0 "respostas pré-gravadas presentes" test -f "$dest/agentic/projeto/bootstrap-respostas.md"

tl_espera 2 "recusa destino existente" sh "$montar" python-cli-novo "$dest"
tl_espera 2 "recusa exemplo inexistente" sh "$montar" nao-existe "$(mktemp -d)/x"

tl_fim
