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

# --- Prova por arquivo (CMD_TESTE_ARQUIVO) e comparação de asserções por arquivo.
# prepara_multi: projeto com suíte que roda tests/t_*.sh e um teste antigo (tests/t_velho.sh, 2 asserções)
# que já passa na base.
prepara_multi() {
  r=$(prepara)
  cat > "$r/tests/run.sh" <<'EOS'
for t in tests/t_*.sh; do sh "$t" || exit 1; done
EOS
  echo 'dobro() { echo $(($1 * 2)); }' > "$r/src/dobro.sh"
  escreve_teste "$r" t_velho dobro "2 4" "3 6"
  git -C "$r" add -A; git -C "$r" commit -q -m "chore: teste antigo"
  printf '%s\n' "$r"
}
# escreve_teste <repo> <nome> <funcao> "<arg> <esperado>"...: grava tests/<nome>.sh com uma asserção por par.
escreve_teste() {
  et_r=$1; et_n=$2; et_f=$3; shift 3
  {
    echo ". ./src/$et_f.sh"
    echo 'assert_igual() { [ "$1" = "$2" ] || { echo "esperado $2, obtido $1"; exit 1; }; }'
    for et_p in "$@"; do
      set -- $et_p
      echo "assert_igual \"\$($et_f $1)\" $2"
    done
  } > "$et_r/tests/$et_n.sh"
}
# teste_soma <repo> [2]: grava tests/t_soma.sh com 1 asserção (ou 2); a definição de assert_igual também casa o marcador.
teste_soma() {
  { echo '. ./src/soma.sh'
    echo 'assert_igual() { [ "$1" = "$2" ] || { echo "esperado $2, obtido $1"; exit 1; }; }'
    echo 'assert_igual "$(soma 2 3)" 5'
    [ -n "$2" ] && echo 'assert_igual "$(soma 1 1)" 2'
  } > "$1/tests/t_soma.sh"
}
green_soma() {
  echo 'soma() { echo $(($1 + $2)); }' > "$1/src/soma.sh"
  git -C "$1" add -A; git -C "$1" commit -q -m "feat(green): soma"
}
modo_arquivo() { config_extra "$1" 'CMD_TESTE_ARQUIVO="sh {}"'; }
config_extra() { echo "$2" >> "$1/.agentic/config"; git -C "$1" add -A; git -C "$1" commit -q -m "chore: config"; }

# (a) Prova por arquivo.
r=$(prepara_multi); modo_arquivo "$r"; teste_soma "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
tl_espera 0 "por arquivo: aceita RED cujo arquivo de teste falhava" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "falhava (tests/t_soma.sh)" "por arquivo: roda o arquivo tocado pelo RED"

r=$(prepara_multi); modo_arquivo "$r"; teste_soma "$r"
escreve_teste "$r" t_dobro dobro "5 10" # arquivo novo no RED que já passa: não é evidência
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma e dobro"; green_soma "$r"
tl_espera 1 "por arquivo: rejeita RED em que um dos arquivos já passava (a suíte inteira falharia)" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "PASSAVAM no RED" "por arquivo: explica que o arquivo passava"
tl_contem "tests/t_dobro.sh" "por arquivo: aponta o arquivo que passava"

r=$(prepara_multi); modo_arquivo "$r"
echo 'dado' > "$r/tests/fixture.txt"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): só fixture"
tl_espera 1 "por arquivo: rejeita RED sem nenhum arquivo de teste com asserção" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "nenhum arquivo de teste com asserção" "por arquivo: explica a ausência de arquivo de teste"

r=$(prepara_multi); config_extra "$r" 'CMD_TESTE_ARQUIVO="comando-que-nao-existe-xyz {}"'; teste_soma "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "por arquivo: CMD_TESTE_ARQUIVO inexistente bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "não encontrado/não executável" "por arquivo: explica o comando ausente"

r=$(prepara_multi); modo_arquivo "$r"; teste_soma "$r"
mv "$r/tests/t_soma.sh" "$r/tests/t_it's soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
tl_espera 0 "por arquivo: caminho com espaço e aspas simples é passado intacto" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

r=$(prepara_multi); teste_soma "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
tl_espera 0 "sem CMD_TESTE_ARQUIVO: RED provado pela suíte inteira" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "degradado: CMD_TESTE_ARQUIVO não configurado" "sem CMD_TESTE_ARQUIVO: avisa o modo degradado"

# (b) Asserções por arquivo.
r=$(prepara_multi); teste_soma "$r" 2
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
teste_soma "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "refactor: tirei uma asserção do RED"
tl_espera 1 "asserção removida no arquivo do RED bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "em tests/t_soma.sh: 3 -> 2" "aponta o arquivo e a contagem"

r=$(prepara_multi); teste_soma "$r" 2
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
teste_soma "$r"; escreve_teste "$r" t_velho dobro "2 4" "3 6" "4 8" # soma total igual
git -C "$r" add -A; git -C "$r" commit -q -m "refactor: movi asserção"
tl_espera 1 "asserção removida do arquivo do RED e somada noutro (total igual) bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

r=$(prepara_multi); teste_soma "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
escreve_teste "$r" t_velho dobro "2 4"
git -C "$r" add -A; git -C "$r" commit -q -m "refactor: enxuga teste antigo"
tl_espera 0 "refactor que reduz asserções em arquivo NÃO tocado pelo RED não bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

r=$(prepara_multi); teste_soma "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"; green_soma "$r"
git -C "$r" rm -q tests/t_soma.sh; git -C "$r" commit -q -m "refactor: apaguei o teste"
tl_espera 1 "arquivo de teste do RED removido em HEAD bloqueia (cai para zero)" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "2 -> 0" "aponta a queda para zero"

tl_fim
