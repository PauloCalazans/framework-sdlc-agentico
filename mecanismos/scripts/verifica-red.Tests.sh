#!/bin/sh
# Testes do verifica-red.sh com um projeto mínimo em sh (independe de stack).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/agentic/.estado" "$r/src" "$r/tests"
  cat > "$r/agentic/config" <<'EOT'
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
mkdir -p "$r/agentic/projeto/specs/x/tasks" "$r/agentic/projeto/intent"
echo '- [x] RED' > "$r/agentic/projeto/specs/x/tasks/001-x.md"
echo 'intenção' > "$r/agentic/projeto/intent/001-x.md"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma + atualiza task"
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
tl_espera 0 "aceita RED que também atualiza agentic/projeto/specs/x/tasks/001-x.md e agentic/projeto/intent/" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# Isenção é só para docs/ e agentic/projeto/: produção fora de DIRS_TESTE segue bloqueada mesmo com doc junto.
r=$(prepara); teste_red "$r"
mkdir -p "$r/agentic/projeto/specs/x/tasks"; echo '- [x] RED' > "$r/agentic/projeto/specs/x/tasks/001-x.md"
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
echo 'CMD_TESTE="comando-que-nao-existe-xyz"' >> "$r/agentic/config"
tl_espera 1 "CMD_TESTE inexistente bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "comando de teste não encontrado" "explica o comando ausente"

r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'CMD_TESTE="./tests"' >> "$r/agentic/config" # diretório: exit 126 em qualquer plataforma
tl_espera 1 "CMD_TESTE não executável (126) bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "não encontrado/não executável" "explica o comando não executável"

# Contagem de asserções fail-closed.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'MARCADOR_ASSERCAO="assert_igual("' >> "$r/agentic/config"
tl_espera 1 "git grep com erro (regex inválida) bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "asserções" "explica a falha na contagem"

r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'MARCADOR_ASSERCAO=""' >> "$r/agentic/config"
tl_espera 1 "MARCADOR_ASSERCAO vazio com RED bloqueia" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "MARCADOR_ASSERCAO" "aponta o marcador vazio"

r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'DIRS_TESTE=""' >> "$r/agentic/config"
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
config_extra() { echo "$2" >> "$1/agentic/config"; git -C "$1" add -A; git -C "$1" commit -q -m "chore: config"; }

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

# --- (c) Remoção autorizada por trailer "Assercoes-removidas: <arquivo> <n> [em <sha>] (<ref>)".
# grava_t <repo> <arquivo> "<chamada>|<esperado>"...: teste que carrega src/*.sh, com uma asserção por par
# (a definição de assert_igual também casa o marcador: contagem = pares + 1).
grava_t() {
  gt_r=$1; gt_f=$2; shift 2
  {
    echo 'for s in ./src/*.sh; do . "$s"; done'
    echo 'assert_igual() { [ "$1" = "$2" ] || { echo "esperado $2, obtido $1"; exit 1; }; }'
    for gt_p in "$@"; do echo "assert_igual \"\$(${gt_p%|*})\" ${gt_p#*|}"; done
  } > "$gt_r/tests/$gt_f"
}
# ruling <repo> <ref>: registra a referência no documento da task, num commit docs(task).
ruling() {
  mkdir -p "$1/agentic/projeto/specs/x/tasks"
  echo "- $2 (execução): o comportamento sai — por quê: decisão do dono" >> "$1/agentic/projeto/specs/x/tasks/001-x.md"
  git -C "$1" add -A; git -C "$1" commit -q -m "docs(task): $2"
}
# commita <repo> <assunto> [trailer...]: commit de tudo, com cada trailer numa linha do último parágrafo.
commita() {
  cm_r=$1; cm_s=$2; shift 2
  git -C "$cm_r" add -A
  if [ $# -gt 0 ]; then
    git -C "$cm_r" commit -q --allow-empty -m "$cm_s" -m "$(printf '%s\n' "$@")"
  else
    git -C "$cm_r" commit -q --allow-empty -m "$cm_s"
  fi
}
# prepara_rem <repo>: RED com 3 asserções em tests/t_soma.sh (contagem 4) e GREEN.
prepara_rem() {
  r=$(prepara_multi)
  grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2" "soma 0 4|4"
  commita "$r" "test(red): soma"; green_soma "$r"
  printf '%s\n' "$r"
}
vr() { sh -c "cd '$1' && sh '$dir/verifica-red.sh'"; }

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-1)" "Assercoes-removidas: tests/t_soma.sh 1 (R-1)"
tl_espera 0 "remoção: trailer igual ao removido, com Ruling registrada antes, passa" vr "$r"
tl_contem "tests/t_soma.sh: 4 -> 3 desde o RED" "remoção: informa a queda aceita"
tl_contem "1 removidas autorizadas por trailer" "remoção: informa o total autorizado"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5"
commita "$r" "test: soma enxuta (R-1)" "Assercoes-removidas: tests/t_soma.sh 1 (R-1)"
tl_espera 1 "remoção: trailer que declara menos que o removido bloqueia" vr "$r"
tl_contem "4 -> 2 (removidas autorizadas: 1)" "remoção: mostra o total autorizado"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-1)" "Assercoes-removidas: tests/t_soma.sh 5 (R-1)"
grava_t "$r" t_soma.sh "soma 2 3|5"
commita "$r" "refactor: tirei mais uma"
tl_espera 1 "remoção: trailer acima da queda do commit não dá folga para remoção posterior" vr "$r"
tl_contem "4 -> 2 (removidas autorizadas: 1)" "remoção: o crédito é limitado à queda do commit"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4" "Assercoes-removidas: tests/t_soma.sh 1 (porque sim)"
tl_espera 1 "remoção: trailer sem referência R-n, D<n> ou Emenda n não conta" vr "$r"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-9)" "Assercoes-removidas: tests/t_soma.sh 1 (R-9)"
tl_espera 1 "remoção: referência que não está registrada nos documentos não conta" vr "$r"
tl_contem "R-9" "remoção: aponta a referência sem registro"

r=$(prepara_rem); ruling "$r" R-12
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-1)" "Assercoes-removidas: tests/t_soma.sh 1 (R-1)"
tl_espera 1 "remoção: R-1 não casa com R-12 registrada" vr "$r"

r=$(prepara_rem)
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-1)" "Assercoes-removidas: tests/t_soma.sh 1 (R-1)"
ruling "$r" R-1
tl_espera 1 "remoção: Ruling registrada só depois da remoção não conta" vr "$r"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-1)" "Assercoes-removidas: tests/t_velho.sh 1 (R-1)"
tl_espera 1 "remoção: trailer de outro arquivo não conta para este" vr "$r"

r=$(prepara_multi); ruling "$r" R-1
commita "$r" "chore: declaração antecipada" "Assercoes-removidas: tests/t_soma.sh 1 (R-1)"
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2" "soma 0 4|4"
commita "$r" "test(red): soma"; green_soma "$r"
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4"
tl_espera 1 "remoção: trailer num commit anterior ao RED não conta" vr "$r"

# Commit vazio posterior apontando o commit da remoção ("em <sha>"): a história não é reescrita.
r=$(prepara_rem); ruling "$r" "Emenda 2"
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma segue a Emenda 2"; x=$(git -C "$r" rev-parse --short HEAD)
commita "$r" "chore: declara remoções" "Assercoes-removidas: tests/t_soma.sh 1 em $x (Emenda 2)"
tl_espera 0 "remoção: commit vazio com 'em <sha>' autoriza a remoção daquele commit" vr "$r"
tl_contem "1 removidas autorizadas por trailer" "remoção: em <sha> informa o total autorizado"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4"
commita "$r" "chore: declara remoções" "Assercoes-removidas: tests/t_soma.sh 1 em deadbeef (R-1)"
tl_espera 1 "remoção: 'em <sha>' inexistente não conta" vr "$r"

r=$(prepara_rem); ruling "$r" R-1
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma sem o caso 0+4 (R-1)" "Assercoes-removidas: tests/t_soma.sh 1 (R-1)"
x=$(git -C "$r" rev-parse --short HEAD)
commita "$r" "chore: repete a declaração" "Assercoes-removidas: tests/t_soma.sh 1 em $x (R-1)"
grava_t "$r" t_soma.sh "soma 2 3|5"
commita "$r" "refactor: tirei mais uma"
tl_espera 1 "remoção: duas declarações do mesmo commit somam no máximo a queda dele" vr "$r"

# RED posterior à remoção não recebe o crédito, mesmo com o commit vazio no fim da branch.
r=$(prepara_rem); ruling "$r" "Emenda 2"
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2"
commita "$r" "test: soma segue a Emenda 2"; x=$(git -C "$r" rev-parse --short HEAD)
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2" "triplo 2|6" "triplo 3|9"
commita "$r" "test(red): triplo"
echo 'triplo() { echo $(($1 * 3)); }' > "$r/src/triplo.sh"; commita "$r" "feat(green): triplo"
grava_t "$r" t_soma.sh "soma 2 3|5" "soma 1 1|2" "triplo 2|6"
commita "$r" "refactor: tirei um caso do triplo"
commita "$r" "chore: declara remoções" "Assercoes-removidas: tests/t_soma.sh 1 em $x (Emenda 2)"
tl_espera 1 "remoção: RED posterior ao commit da remoção não recebe o crédito" vr "$r"
tl_contem "tests/t_soma.sh: 5 -> 4" "remoção: aponta a queda do RED posterior"

# Caminho com espaço: o trailer é lido de trás para frente.
r=$(prepara_multi)
grava_t "$r" "t_soma x.sh" "soma 2 3|5" "soma 1 1|2"
commita "$r" "test(red): soma"; green_soma "$r"; ruling "$r" R-1
grava_t "$r" "t_soma x.sh" "soma 2 3|5"
commita "$r" "test: soma sem o caso 1+1 (R-1)" "Assercoes-removidas: tests/t_soma x.sh 1 (R-1)"
tl_espera 0 "remoção: caminho com espaço no trailer" vr "$r"

# Branch empilhada: o RED da base (que passa no HEAD da base) não é cobrado da task empilhada, que não o fez.
r=$(prepara)
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat: soma antes do teste"
teste_red "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
git -C "$r" branch -q pedidos/001
mkdir -p "$r/agentic/projeto/specs/pedidos/tasks"
printf '# T2
**Status:** em-andamento
**Branch:** feat/soma
**Base:** pedidos/001

## Arquivos
- src/*
' > "$r/agentic/projeto/specs/pedidos/tasks/002-t.md"
git -C "$r" add -A; git -C "$r" commit -q -m "task 2"
tl_espera 0 "avulso em branch empilhada não prova o RED da base" env -u AGENTIC_BASE sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "nenhum commit test(red):" "avulso empilhado: só os REDs da própria task"


# --- Cache da prova de RED (por SHA + assinatura) ---
vrc() { sh -c "cd '$1' && sh '$dir/verifica-red.sh'" </dev/null; }
conta() { [ "$(wc -l < "$cont")" -eq "$1" ]; }
prepara_cache() {
  r=$(prepara)
  cont=$(mktemp)
  : > "$cont"
  printf 'CMD_TESTE_ARQUIVO="echo x >> '"'%s'"'; sh {}"\n' "$cont" >> "$r/agentic/config"
  git -C "$r" add -A; git -C "$r" commit -q -m "config: contador"
  teste_red "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
  echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
  git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
}
prepara_cache
tl_espera 0 "cache: 1ª prova executa" vrc "$r"
tl_espera 0 "cache: contador 1" conta 1
tl_espera 0 "cache: 2ª chamada usa o cache" vrc "$r"
tl_contem "já provado (tests/run.sh) (ok)" "cache: diz que usou o cache"
tl_espera 0 "cache: contador continua 1" conta 1
git -C "$r" worktree add -q --detach "$r.wt" HEAD
tl_espera 0 "cache: compartilhado entre worktrees" vrc "$r.wt"
tl_contem "já provado" "cache: o worktree ligado usou a prova do diretório comum"
tl_espera 0 "cache: contador inalterado no worktree ligado" conta 1
git -C "$r" worktree remove --force "$r.wt"
tl_espera 0 "cache: AGENTIC_RED_SEM_CACHE=1 prova de novo" env AGENTIC_RED_SEM_CACHE=1 sh -c "cd '$r' && sh '$dir/verifica-red.sh'" </dev/null
tl_espera 0 "cache: contador 2" conta 2
printf 'CMD_TESTE_ARQUIVO="echo y >> '"'%s'"'; sh {}"\n' "$cont" >> "$r/agentic/config"
git -C "$r" add -A; git -C "$r" commit -q -m "config: outro comando"
tl_espera 0 "cache: assinatura nova prova de novo" vrc "$r"
tl_espera 0 "cache: contador 3" conta 3
tl_espera 0 "cache: depois da nova assinatura usa o cache" vrc "$r"
tl_espera 0 "cache: contador segue 3" conta 3

# RED que passava nunca é guardado.
r=$(prepara)
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat: soma antes do teste"
teste_red "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "cache: RED que passava não é guardado (1ª)" vrc "$r"
tl_espera 1 "cache: RED que passava não é guardado (2ª)" vrc "$r"
tl_contem "PASSAVAM" "cache: segue explicando"

# Preparo com falha nunca é guardado.
r=$(prepara); teste_red "$r"; echo 'CMD_PREPARAR_TESTE="exit 1"' >> "$r/agentic/config"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "cache: preparo com falha bloqueia (1ª)" vrc "$r"
tl_espera 1 "cache: preparo com falha bloqueia (2ª)" vrc "$r"
tl_contem "CMD_PREPARAR_TESTE falhou" "cache: preparo com falha segue explicado"

# Asserções removidas depois: verificadas mesmo com prova guardada.
prepara_cache
tl_espera 0 "cache: guarda a prova" vrc "$r"
printf '. ./src/soma.sh\n' > "$r/tests/run.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "refactor: removi a asserção"
tl_espera 1 "cache: contagem de asserções roda mesmo com cache" vrc "$r"
tl_contem "asserções diminuíram" "cache: aponta a queda"
tl_contem "já provado" "cache: e ainda usou a prova guardada"

# Produção no RED: bloqueia mesmo com a prova guardada para esse SHA.
r=$(prepara); teste_red "$r"; echo '# mexi' >> "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
red=$(git -C "$r" rev-parse HEAD)
mkdir -p "$r/.git/agentic"
sig=$(printf '%s\n%s\n%s\n' "" "" "sh tests/run.sh" | git hash-object --stdin)
printf '%s %s %s\n' "$red" "$sig" '*suite*' > "$r/.git/agentic/red-provados"
tl_espera 1 "cache: recusa de produção roda mesmo com prova guardada" vrc "$r"
tl_contem "já provado (*suite*)" "cache: a prova guardada estava valendo (assinatura certa)"
tl_contem "src/soma.sh" "cache: aponta a produção"

# Modo degradado: a suíte inteira é guardada como *suite*.
r=$(prepara); teste_red "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 0 "cache degradado: 1ª prova" vrc "$r"
tl_espera 0 "cache degradado: 2ª usa o cache" vrc "$r"
tl_contem "já provado (*suite*)" "cache degradado: diz que usou o cache"
tl_espera 0 "cache degradado: arquivo guarda *suite* literal" grep -qF ' *suite*' "$r/.git/agentic/red-provados"

# Execução interrompida (rc >= 124: timeout ou sinal) não vira prova permanente.
r=$(prepara); cont=$(mktemp); : > "$cont"
printf 'CMD_TESTE_ARQUIVO="echo x >> '"'%s'"'; exit 130"
' "$cont" >> "$r/agentic/config"
git -C "$r" add -A; git -C "$r" commit -q -m "config: interrompido"
printf 'exit 1
assert_igual
' > "$r/tests/a.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): a"
tl_espera 0 "cache: rc 130 mantém o veredicto (falhava)" vrc "$r"
tl_contem "falhava (tests/a.sh) (ok)" "cache: rc 130 segue 'falhava (ok)'"
tl_espera 0 "cache: rc 130 executou uma vez" conta 1
tl_espera 0 "cache: rc 130 prova de novo na 2ª chamada" vrc "$r"
tl_espera 0 "cache: rc 130 não imprime 'já provado'" sh -c "! grep -q 'já provado' '$TL_SAIDA'"
tl_espera 0 "cache: rc 130 não foi guardado (contador 2)" conta 2

# Cache parcial: um arquivo já provado e outro novo; só o novo executa.
parcial() {
  r=$(prepara); cont=$(mktemp); : > "$cont"
  cmdarq="echo x >> '$cont'; sh {}"
  printf 'CMD_TESTE_ARQUIVO="%s"
' "$cmdarq" >> "$r/agentic/config"
  git -C "$r" add -A; git -C "$r" commit -q -m "config: contador"
  printf 'exit 1
assert_igual
' > "$r/tests/a.sh"
  printf '%s
assert_igual
' "$1" > "$r/tests/b.sh"
  git -C "$r" add -A; git -C "$r" commit -q -m "test(red): a e b"
  red=$(git -C "$r" rev-parse HEAD)
  sig=$(printf '%s
%s
%s
' "" "$cmdarq" "sh tests/run.sh" | git hash-object --stdin)
  mkdir -p "$r/.git/agentic"
  printf '%s %s %s
' "$red" "$sig" 'tests/a.sh' > "$r/.git/agentic/red-provados"
}
parcial 'exit 1'
tl_espera 0 "cache parcial: a provado, b novo" vrc "$r"
tl_contem "já provado (tests/a.sh) (ok)" "cache parcial: a veio do cache"
tl_contem "falhava (tests/b.sh) (ok)" "cache parcial: b foi provado"
tl_espera 0 "cache parcial: só o novo executou" conta 1
parcial 'exit 0'
tl_espera 1 "cache parcial: b novo que passa bloqueia" vrc "$r"
tl_contem "já provado (tests/a.sh)" "cache parcial: a segue do cache"
tl_contem "PASSAVAM no RED" "cache parcial: explica que b passava"
tl_espera 0 "cache parcial: b executou" conta 1

# Review Focus 5: comando que lê stdin não come a lista de arquivos.
r=$(prepara)
echo 'CMD_TESTE_ARQUIVO="cat >/dev/null; sh {}"' >> "$r/agentic/config"
git -C "$r" add -A; git -C "$r" commit -q -m "config: lê stdin"
printf 'exit 1\nassert_igual\n' > "$r/tests/a.sh"; printf 'exit 1\nassert_igual\n' > "$r/tests/b.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): a e b"
tl_espera 0 "stdin: comando que lê stdin não come a lista de arquivos" vrc "$r"
tl_contem "(tests/a.sh)" "stdin: provou a.sh"
tl_contem "(tests/b.sh)" "stdin: provou b.sh"


# --- Vínculo CA -> teste no commit RED (Task 9)
# vinculo <texto-da-seção> [titulo]: repo com a task da branch; o RED toca tests/a.sh e tests/b.sh.
vinculo() {
  r=$(prepara)
  mkdir -p "$r/agentic/projeto/specs/x/tasks"
  printf '# Task 001\n**Status:** pendente\n**Branch:** feat/soma\n\n## %s\n' "${2:-Critérios de pronto}" > "$r/agentic/projeto/specs/x/tasks/001-x.md"
  printf '%b\n\n## Questões em aberto\n- nada\n' "$1" >> "$r/agentic/projeto/specs/x/tasks/001-x.md"
  git -C "$r" add -A; git -C "$r" commit -q -m "docs: task"
  printf 'exit 1\nassert_igual\n' > "$r/tests/a.sh"; printf 'exit 1\nassert_igual\n' > "$r/tests/b.sh"
  printf 'x\n' > "$r/tests/outro.sh"
  printf 'exit 1
' > "$r/tests/run.sh"
  git -C "$r" add tests/a.sh tests/b.sh tests/run.sh; git -C "$r" commit -q -m "test(red): a e b"
}
vv() { sh -c "cd '$1' && sh '$dir/verifica-red.sh'"; }
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n- CA2 (R2): b → test: tests/b.sh::dois\n- `sh verify.sh` verde'
tl_espera 0 "vínculo: todo CA anotado com arquivo do RED passa" vv "$r"
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n- CA2 (R2): b sem anotação'
tl_espera 1 "vínculo: CA sem anotação, com outro anotado, bloqueia" vv "$r"
tl_contem "CA2 sem → test:" "vínculo: nomeia o CA"
vinculo '- CA1 (R1): a → test: tests/outro.sh::um'
tl_espera 1 "vínculo: arquivo anotado fora dos commits RED bloqueia" vv "$r"
tl_contem "tests/outro.sh" "vínculo: nomeia o arquivo"
vinculo '- CA1 (R1): a\n- CA2 (R2): b'
tl_espera 0 "vínculo: task sem nenhuma anotação passa com aviso" vv "$r"
tl_contem "aviso: task sem anotação" "vínculo: avisa"
vinculo '- CA1 (R1): a → test: tests/a.sh::um; tests/b.sh::dois'
tl_espera 0 "vínculo: dois testes num CA separados por ; " vv "$r"
vinculo '- CA1 (R1): a → test: tests/a.sh::um\r\n- CA2 (R2): b → test: `tests/b.sh::dois`\r'
tl_espera 0 "vínculo: anotação com CRLF" vv "$r"
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n<!-- - CA9 (R9): comentado sem anotação -->'
tl_espera 0 "vínculo: CA dentro de comentário HTML é ignorado" vv "$r"
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n- CA2 (R2): b' "Critérios de aceite"
tl_espera 1 "vínculo: mudança lê Critérios de aceite" vv "$r"
r=$(prepara); printf 'exit 1\nassert_igual\n' > "$r/tests/a.sh"; echo "exit 1" > "$r/tests/run.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): a"
tl_espera 0 "vínculo: branch sem task (trilha rápida) não checa" vv "$r"


# Correções da revisão: anotação sem arquivo e CA em checkbox
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n- CA2 (R2): b → test: ::x'
tl_espera 1 "vínculo: → test: ::x (sem arquivo) bloqueia" vv "$r"
tl_contem "CA2 com → test: sem arquivo" "vínculo: nomeia o CA sem arquivo"
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n- CA2 (R2): b → test:'
tl_espera 1 "vínculo: → test: vazio bloqueia" vv "$r"
tl_contem "CA2 com → test: sem arquivo" "vínculo: nomeia o CA com anotação vazia"
vinculo '- CA1 (R1): b → test:'
tl_espera 1 "vínculo: única anotação vazia não vira aviso" vv "$r"
vinculo '- [x] CA1 (R1): a → test: tests/a.sh::um\n- [ ] CA2 (R2): b sem anotação'
tl_espera 1 "vínculo: CA em checkbox sem anotação bloqueia" vv "$r"
tl_contem "CA2 sem → test:" "vínculo: nomeia o CA do checkbox"
vinculo '- [x] CA1 (R1): a → test: tests/a.sh::um\n- [ ] CA2 (R2): b → test: tests/b.sh::dois'
tl_espera 0 "vínculo: CA em checkbox anotado passa" vv "$r"

# Varredura de coerência: GREEN sem RED numa task com CA bloqueia; só registro/contrato ainda não.
semred() {
  r=$(prepara)
  mkdir -p "$r/agentic/projeto/specs/x/tasks"
  printf '# Task 001\n**Status:** pendente\n**Branch:** feat/soma\n\n## Critérios de pronto\n- CA1 (R1): a\n' > "$r/agentic/projeto/specs/x/tasks/001-x.md"
  git -C "$r" add -A; git -C "$r" commit -q -m "docs(spec): x aprovada (Gate 1)"
  echo 'soma() { echo 9; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "chore: contrato executável"
}
semred
tl_espera 0 "sem RED: só docs e chore ainda não bloqueia" vv "$r"
tl_contem "nenhum commit test(red):" "sem RED: informa"
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
tl_espera 1 "sem RED: task com CA e GREEN sem RED bloqueia" vv "$r"
tl_contem "sem nenhum test(red):" "sem RED: explica"
r=$(prepara); echo 'soma() { echo 1; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "fix: sem task"
tl_espera 0 "sem RED: branch sem task (trilha rápida) não bloqueia" vv "$r"
# Revisão: mesma definição de CA do vínculo; test: e o que um merge trouxe não contam como GREEN.
semred_task() {
  r=$(prepara)
  mkdir -p "$r/agentic/projeto/specs/x/tasks"
  printf '%b\n' "$1" > "$r/agentic/projeto/specs/x/tasks/001-x.md"
  git -C "$r" add -A; git -C "$r" commit -q -m "docs(spec): x aprovada (Gate 1)"
}
semred_task '# Task 001\n**Branch:** feat/soma\n\n## Critérios de pronto\n<!-- - CA1 (R1): exemplo -->\n- `sh verify.sh` verde'
echo 'soma() { echo 1; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "feat: x"
tl_espera 0 "sem RED: CA só em comentário HTML não conta" vv "$r"
semred_task '# Task 001\n**Branch:** feat/soma\n\n## Contexto\n- CA1 citado fora dos critérios\n\n## Critérios de pronto\n- `sh verify.sh` verde'
echo 'soma() { echo 1; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "feat: x"
tl_espera 0 "sem RED: CA fora da seção de critérios não conta" vv "$r"
semred
printf 'assert_igual\n' > "$r/tests/carac.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "test: caracterização do legado"
tl_espera 0 "sem RED: commit test: (caracterização) não é GREEN" vv "$r"
semred
git -C "$r" checkout -q main; echo y > "$r/src/outro.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "feat: de outra task, já integrada"
git -C "$r" checkout -q feat/soma; git -C "$r" merge -q --no-edit main
tl_espera 0 "sem RED: commits da principal trazidos por merge não contam" vv "$r"

# Varredura de coerência: verify.sh --task exporta AGENTIC_TASK; a task chega ao vínculo numa branch de nome imposto.
vinculo '- CA1 (R1): a → test: tests/a.sh::um\n- CA2 (R2): b sem anotação'
git -C "$r" checkout -q -b copilot/imposta
tl_espera 0 "branch imposta sem AGENTIC_TASK: sem task associada, não checa" vv "$r"
tl_espera 1 "branch imposta com AGENTIC_TASK: vínculo checado" sh -c "cd '$r' && AGENTIC_TASK=agentic/projeto/specs/x/tasks/001-x.md sh '$dir/verifica-red.sh'"
tl_contem "CA2 sem → test:" "branch imposta: nomeia o CA"
tl_espera 0 "verify.sh exporta a task para o verifica-red" grep -q 'AGENTIC_TASK=$task; export AGENTIC_TASK' "$dir/verify.sh"

# Re-revisão: test: com produção conta; remoção autorizada não bloqueia; GREEN de sub-branch conta.
semred
echo 'soma() { echo 2; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "test: disfarçado"
tl_espera 1 "sem RED: test: que toca produção conta como GREEN" vv "$r"
semred
printf 'x\n' > "$r/tests/velho.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "test: remove x (R-1)" -m "Assercoes-removidas: tests/velho.sh 1 (R-1)"
echo 'soma() { echo 3; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "refactor: tira comportamento"
tl_espera 0 "sem RED: task de remoção de comportamento não bloqueia" vv "$r"
semred
git -C "$r" checkout -q -b sub; echo 'soma() { echo 4; }' > "$r/src/soma.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): na sub"
git -C "$r" checkout -q feat/soma; git -C "$r" merge -q --no-ff --no-edit sub
tl_espera 1 "sem RED: GREEN trazido de sub-branch por merge conta" vv "$r"

tl_fim
