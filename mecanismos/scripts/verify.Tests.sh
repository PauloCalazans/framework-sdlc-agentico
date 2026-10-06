#!/bin/sh
# Testes do verify.sh do projeto.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/.agentic" "$r/tests" "$r/sub/dir" "$r/docs/specs/x/tasks"
  printf 'CMD_VERIFY_STACK="sh tests/stack.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/.agentic/config"
  echo 'exit 0' > "$r/tests/stack.sh"
  printf '# T\n**Status:** em-andamento\n**Branch:** x/001\n\n## Arquivos\n- tests/*\n' > "$r/docs/specs/x/tasks/001-t.md"
  git -C "$r" add -A; git -C "$r" commit -q -m "base"
  git -C "$r" checkout -q -b x/001
  printf '%s\n' "$r"
}

r=$(prepara)
tl_espera 0 "passa quando a stack passa e o escopo é respeitado" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: OK" "resumo de sucesso"
tl_contem "escopo: OK" "encontrou a task pela branch"

tl_espera 0 "funciona chamado de um subdiretório" sh -c "cd '$r/sub/dir' && sh '$dir/verify.sh'"

echo 'exit 1' > "$r/tests/stack.sh"
tl_espera 1 "falha quando a stack falha" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: FALHOU em: stack" "nomeia a etapa que falhou"
echo 'exit 0' > "$r/tests/stack.sh"

echo z > "$r/fora.txt"
tl_espera 1 "falha quando o escopo é violado" sh -c "cd '$r' && sh '$dir/verify.sh'"
rm "$r/fora.txt"

mkdir "$r/.agentic/verify.lock"; echo $$ > "$r/.agentic/verify.lock/pid"
tl_espera 3 "recusa rodar com outro verify vivo" sh -c "cd '$r' && sh '$dir/verify.sh'"
echo 999999 > "$r/.agentic/verify.lock/pid"
tl_espera 0 "recupera lock abandonado" sh -c "cd '$r' && sh '$dir/verify.sh'"

git -C "$r" checkout -q main
tl_espera 0 "na branch principal, sem task: pula escopo (trilha rápida)" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "pulado" "declara a etapa pulada"
tl_contem "aviso: nenhuma task com **Branch:** main" "avisa que o escopo não foi verificado (há tasks)"

# Trilha enxuta: o documento único (template real) é achado pela **Branch:** e o escopo vale.
r=$(tl_repo)
mkdir -p "$r/.agentic" "$r/tests" "$r/src" "$r/docs/specs/desc/tasks"
printf 'CMD_VERIFY_STACK="sh tests/stack.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/.agentic/config"
echo 'exit 0' > "$r/tests/stack.sh"
sed -e 's|<nome>/001-<nome>|desc/001-desc|' -e 's|<caminho/exato>|src/desc.txt|' -e 's|<diretorio/\*>|tests/*|' \
  "$dir/../../core/templates/mudanca.md" > "$r/docs/specs/desc/tasks/001-desc.md"
git -C "$r" add -A; git -C "$r" commit -q -m "base"
git -C "$r" checkout -q -b desc/001-desc
echo a > "$r/src/desc.txt"
tl_espera 0 "trilha enxuta: acha o documento pela Branch e respeita o escopo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "escopo: OK (docs/specs/desc/tasks/001-desc.md)" "trilha enxuta: escopo verificado pelo documento único"
echo z > "$r/fora.txt"
tl_espera 1 "trilha enxuta: arquivo fora de ## Arquivos é bloqueado" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "fora.txt" "trilha enxuta: nomeia o arquivo fora do escopo"
rm "$r/fora.txt"
git -C "$r" checkout -q -b desc/002-sem-doc main
tl_espera 0 "trilha enxuta: documento ausente da branch não quebra o verify" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "aviso: nenhuma task com **Branch:** desc/002-sem-doc" "trilha enxuta: sem documento na branch, avisa que o escopo não foi verificado"

r=$(tl_repo)
tl_espera 1 "falha se CMD_VERIFY_STACK não está configurado" sh -c "cd '$r' && sh '$dir/verify.sh'"

tl_fim
