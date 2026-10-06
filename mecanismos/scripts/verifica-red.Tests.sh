#!/bin/sh
# Testes do verifica-red.sh com um projeto mínimo em sh (independe de stack).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/.agentic" "$r/src" "$r/tests"
  cat > "$r/.agentic/config" <<'EOT'
CMD_TESTE="sh tests/run.sh"
DIRS_TESTE="tests/"
MARCADOR_ASSERCAO="assert_igual"
EOT
  echo 'soma() { echo 0; }' > "$r/src/soma.sh"
  git -C "$r" add -A; git -C "$r" commit -q -m "base"
  git -C "$r" checkout -q -b feat/soma
  printf '%s\n' "$r"
}
teste_red() {
  cat > "$1/tests/run.sh" <<'EOT'
. ./src/soma.sh
assert_igual() { [ "$1" = "$2" ] || { echo "esperado $2, obtido $1"; exit 1; }; }
assert_igual "$(soma 2 3)" 5
EOT
}

# Caso feliz: RED falha, GREEN passa.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
tl_espera 0 "aceita RED que falhava e GREEN que mantém asserções" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# RED que já passava não é evidência.
r=$(prepara)
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat: soma antes do teste"
teste_red "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "rejeita RED cujos testes passavam" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "PASSAVAM" "explica que o RED não falhava"

# RED tocando produção.
r=$(prepara); teste_red "$r"; echo '# mexi' >> "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "rejeita RED que toca fora dos diretórios de teste" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "src/soma.sh" "aponta o arquivo de produção"

# GREEN que remove asserção.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
printf '. ./src/soma.sh\n' > "$r/tests/run.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): removi o teste"
tl_espera 1 "rejeita quando asserções diminuem depois do RED" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# Sem commit RED.
r=$(prepara)
tl_espera 0 "sem commit RED não falha" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "nenhum commit test(red):" "informa ausência de RED"

# Base explícita inválida: falha fechada.
r=$(prepara)
tl_espera 1 "base explícita inválida sai 1" sh -c "cd '$r' && sh '$dir/verifica-red.sh' naoexiste"
tl_contem "base inválida" "informa base inválida"

tl_fim
