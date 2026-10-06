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

# RED que atualiza o documento da task (docs/) e o intent: documentação não é produção.
r=$(prepara); teste_red "$r"
mkdir -p "$r/docs/specs/x/tasks" "$r/intent"
echo '- [x] RED' > "$r/docs/specs/x/tasks/001-x.md"
echo 'intenção' > "$r/intent/001-x.md"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma + atualiza task"
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
tl_espera 0 "aceita RED que também atualiza docs/specs/x/tasks/001-x.md e intent/" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# Isenção é só para docs/ e intent/: produção fora de DIRS_TESTE segue bloqueada mesmo com doc junto.
r=$(prepara); teste_red "$r"
mkdir -p "$r/docs/specs/x/tasks"; echo '- [x] RED' > "$r/docs/specs/x/tasks/001-x.md"
echo 'module.exports = 1' > "$r/src/x.js"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "rejeita RED que toca src/x.js mesmo junto com doc da task" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "src/x.js" "aponta src/x.js"

# Nome parecido com docs/ não é isento (casamento por prefixo de diretório).
r=$(prepara); teste_red "$r"
mkdir -p "$r/docsx"; echo 'x' > "$r/docsx/a.md"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "rejeita RED que toca docsx/ (não é docs/)" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

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

# Nomes de arquivo com acento e espaço no RED: lidos por linha e sem aspas do quotepath.
r=$(prepara); teste_red "$r"
echo 'dado' > "$r/tests/cenário de preço.txt"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma com acento"
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
tl_espera 0 "aceita RED com arquivo de teste com acento e espaço" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# CMD_TESTE inexistente (127) ou não executável (126) não é evidência de RED.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'CMD_TESTE="comando-que-nao-existe-xyz"' >> "$r/.agentic/config"
tl_espera 1 "CMD_TESTE inexistente bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "comando de teste não encontrado" "explica o comando ausente"

r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'CMD_TESTE="./tests"' >> "$r/.agentic/config" # diretório: exit 126 em qualquer plataforma
tl_espera 1 "CMD_TESTE não executável (126) bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "não encontrado/não executável" "explica o comando não executável"

# Contagem de asserções fail-closed.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'MARCADOR_ASSERCAO="assert_igual("' >> "$r/.agentic/config"
tl_espera 1 "git grep com erro (regex inválida) bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "asserções" "explica a falha na contagem"

r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'MARCADOR_ASSERCAO=""' >> "$r/.agentic/config"
tl_espera 1 "MARCADOR_ASSERCAO vazio com RED bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "MARCADOR_ASSERCAO" "aponta o marcador vazio"

r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'DIRS_TESTE=""' >> "$r/.agentic/config"
tl_espera 1 "DIRS_TESTE vazio com RED bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "DIRS_TESTE" "aponta DIRS_TESTE vazio"

tl_fim
