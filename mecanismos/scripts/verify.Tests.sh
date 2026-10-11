#!/bin/sh
# Testes do verify.sh do projeto.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

# Instância com os githooks ligados, como o instalar.sh deixa (a etapa hooks exige).
repo() { rr=$(tl_repo); git -C "$rr" config core.hooksPath agentic/mecanismos/githooks; printf '%s\n' "$rr"; }

prepara() {
  r=$(repo)
  mkdir -p "$r/agentic/.estado" "$r/tests" "$r/sub/dir" "$r/agentic/projeto/specs/x/tasks"
  printf 'CMD_VERIFY_STACK="sh tests/stack.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
  echo 'exit 0' > "$r/tests/stack.sh"
  printf '# T\n**Status:** em-andamento\n**Branch:** x/001\n\n## Arquivos\n- tests/*\n' > "$r/agentic/projeto/specs/x/tasks/001-t.md"
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

# etapa decisões (trilha rápida, sem task): referência a decisão inexistente derruba o verify
r2=$(repo); mkdir -p "$r2/agentic/projeto" "$r2/tests"
printf 'CMD_VERIFY_STACK="sh tests/stack.sh"\n' > "$r2/agentic/config"; echo 'exit 0' > "$r2/tests/stack.sh"
printf '# Decisões\n\n### D1 — t\n' > "$r2/agentic/projeto/decisoes.md"
git -C "$r2" add -A; git -C "$r2" commit -q -m "base"; git -C "$r2" checkout -q -b chore/d
printf 'Ver D2.\n' > "$r2/agentic/projeto/nota.md"; git -C "$r2" add -A; git -C "$r2" commit -q -m "nota"
tl_espera 1 "falha quando há referência a decisão inexistente" sh -c "cd '$r2' && sh '$dir/verify.sh'"
tl_contem "VERIFY: FALHOU em: decisoes" "nomeia a etapa decisoes"

# etapa hooks: clone sem core.hooksPath (outra máquina, agente de nuvem) tem os githooks desligados
git -C "$r" config --unset core.hooksPath
tl_espera 1 "falha quando os githooks estão desligados no clone" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: FALHOU em: hooks" "nomeia a etapa hooks"
tl_contem "git config core.hooksPath agentic/mecanismos/githooks" "mostra o comando que liga os githooks"
git -C "$r" config core.hooksPath .outro
tl_espera 1 "falha quando core.hooksPath aponta para outro lugar" sh -c "cd '$r' && sh '$dir/verify.sh'"
git -C "$r" config core.hooksPath agentic/mecanismos/githooks

# Produto que impõe o próprio nome de branch (ex.: copilot/…): a task vem por --task e o escopo vale.
git -C "$r" checkout -q -b copilot/tarefa-qualquer
tl_espera 0 "branch sem task associada: escopo pulado com aviso" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "aviso: nenhuma task com **Branch:** copilot/tarefa-qualquer" "avisa que o escopo não foi verificado"
tl_espera 0 "com --task, o escopo é verificado em qualquer branch" sh -c "cd '$r' && sh '$dir/verify.sh' --task agentic/projeto/specs/x/tasks/001-t.md"
tl_contem "escopo: OK" "--task: escopo verificado"
echo z > "$r/fora.txt"
tl_espera 1 "com --task, arquivo fora do escopo é bloqueado" sh -c "cd '$r' && sh '$dir/verify.sh' --task agentic/projeto/specs/x/tasks/001-t.md"
rm "$r/fora.txt"
git -C "$r" checkout -q x/001

# Clone novo de CI ou de agente de nuvem: só existe origin/main, sem a principal local.
c=$(mktemp -d); git clone -q "$r" "$c"; git -C "$c" checkout -q x/001; git -C "$c" branch -q -D main
git -C "$c" config core.hooksPath agentic/mecanismos/githooks
tl_espera 0 "clone sem a principal local: usa origin/main como base" sh -c "cd '$c' && sh '$dir/verify.sh'"
tl_contem "escopo: OK" "clone sem a principal local: escopo verificado contra origin/main"

echo z > "$r/fora.txt"
tl_espera 1 "falha quando o escopo é violado" sh -c "cd '$r' && sh '$dir/verify.sh'"
rm "$r/fora.txt"

mkdir "$r/agentic/.estado/verify.lock"; echo $$ > "$r/agentic/.estado/verify.lock/pid"
tl_espera 3 "recusa rodar com outro verify vivo" sh -c "cd '$r' && sh '$dir/verify.sh'"
echo 999999 > "$r/agentic/.estado/verify.lock/pid"
tl_espera 0 "recupera lock abandonado" sh -c "cd '$r' && sh '$dir/verify.sh'"

git -C "$r" checkout -q main
tl_espera 0 "na branch principal, sem task: pula escopo (trilha rápida)" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "pulado" "declara a etapa pulada"
tl_contem "aviso: nenhuma task com **Branch:** main" "avisa que o escopo não foi verificado (há tasks)"

# Trilha enxuta: o documento único (template real) é achado pela **Branch:** e o escopo vale.
r=$(repo)
mkdir -p "$r/agentic/.estado" "$r/tests" "$r/src" "$r/agentic/projeto/specs/desc/tasks"
printf 'CMD_VERIFY_STACK="sh tests/stack.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
echo 'exit 0' > "$r/tests/stack.sh"
sed -e 's|<nome>/001-<nome>|desc/001-desc|' -e 's|<caminho/exato>|src/desc.txt|' -e 's|<diretorio/\*>|tests/*|' \
  "$dir/../../core/templates/mudanca.md" > "$r/agentic/projeto/specs/desc/tasks/001-desc.md"
git -C "$r" add -A; git -C "$r" commit -q -m "base"
git -C "$r" checkout -q -b desc/001-desc
echo a > "$r/src/desc.txt"
tl_espera 0 "trilha enxuta: acha o documento pela Branch e respeita o escopo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "escopo: OK (agentic/projeto/specs/desc/tasks/001-desc.md)" "trilha enxuta: escopo verificado pelo documento único"
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
