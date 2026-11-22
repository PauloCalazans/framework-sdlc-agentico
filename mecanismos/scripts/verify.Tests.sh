#!/bin/sh
# Testes do verify.sh do projeto.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

# Os cenários de etapa repetem o verify na mesma árvore; sem isto, a prova do completo os responderia.
# A seção "Prova do completo", no fim, liga a prova de novo.
AGENTIC_VERIFY_SEM_CACHE=1; export AGENTIC_VERIFY_SEM_CACHE

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

# Branches empilhadas: a task declara **Base:** com a branch da task anterior ainda não integrada.
r=$(prepara)
printf 'a\n' > "$r/tests/a.txt"
printf '# T2\n**Status:** em-andamento\n**Branch:** x/002\n**Base:** x/001\n\n## Arquivos\n- src/*\n' > "$r/agentic/projeto/specs/x/tasks/002-t.md"
git -C "$r" add -A; git -C "$r" commit -q -m "task 1"
git -C "$r" checkout -q -b x/002
mkdir -p "$r/src"; printf 'b\n' > "$r/src/b.txt"; git -C "$r" add -A; git -C "$r" commit -q -m "task 2"
tl_espera 0 "branch empilhada: escopo comparado com a ponta da **Base:**" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "escopo: OK" "empilhada: escopo verificado"
tl_contem "base: x/001 (branch empilhada" "declara a base empilhada"
sed -i.bak '/^\*\*Base:\*\*/d' "$r/agentic/projeto/specs/x/tasks/002-t.md"; rm -f "$r/agentic/projeto/specs/x/tasks/002-t.md.bak"
tl_espera 1 "empilhada sem **Base:**: arquivos da task anterior ficam fora do escopo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "tests/a.txt" "aponta o arquivo da task anterior"
git -C "$r" checkout -q -- agentic/projeto/specs/x/tasks/002-t.md
git -C "$r" checkout -q main; git -C "$r" merge -q --no-ff x/001 -m "integra x/001" >/dev/null 2>&1; git -C "$r" checkout -q x/002
tl_espera 0 "**Base:** já integrada: volta a comparar com a principal" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "já integrada ou ausente" "declara a volta à principal"
git -C "$r" branch -q -d x/001
tl_espera 0 "**Base:** removida depois da integração: compara com a principal" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "escopo: OK" "base removida: escopo verificado"

# Etapas na ordem barata: hooks, escopo, decisões, red, stack, skip.
r=$(prepara)
tl_espera 0 "etapas na ordem barata" sh -c "cd '$r' && sh '$dir/verify.sh'"
ord=$(mktemp); cp "$TL_SAIDA" "$ord"
tl_espera 0 "etapas aparecem na ordem hooks, escopo, decisoes, red, stack, skip" sh -c "awk '/^== (hooks|escopo|decisoes|red|stack|skip)/ { o = o \$2 \" \" } END { exit (o == \"hooks escopo decisoes red stack skip \" ? 0 : 1) }' '$ord'"
rm -f "$ord"

# A base da task empilhada chega à stack por AGENTIC_BASE.
r=$(prepara)
printf '# T2
**Status:** em-andamento
**Branch:** x/002
**Base:** x/001

## Arquivos
- src/*
' > "$r/agentic/projeto/specs/x/tasks/002-t.md"
printf 'CMD_VERIFY_STACK="echo base=\$AGENTIC_BASE"
DIRS_TESTE="tests/"
' > "$r/agentic/config"
git -C "$r" add -A; git -C "$r" commit -q -m "task 1"
git -C "$r" checkout -q -b x/002
mkdir -p "$r/src"; printf 'b
' > "$r/src/b.txt"; git -C "$r" add -A; git -C "$r" commit -q -m "task 2"
tl_espera 0 "stack recebe AGENTIC_BASE da task empilhada" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "base=x/001" "stack vê a base empilhada"
git -C "$r" checkout -q main; git -C "$r" merge -q --no-ff x/001 -m "integra x/001" >/dev/null 2>&1; git -C "$r" checkout -q x/002
git -C "$r" branch -q -d x/001
tl_espera 0 "Base apagada depois de integrada cai para a principal" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "base: principal" "Base integrada e apagada: declara a principal"
tl_contem "VERIFY: OK" "Base integrada e apagada: verify ok"


# --- Nível rápido: hooks → escopo → decisões → red → stack-rapido; sem skip; rótulo próprio.
r=$(prepara)
# o config é reescrito a cada cenário: entra no escopo da task deste repositório de teste
echo "- agentic/config" >> "$r/agentic/projeto/specs/x/tasks/001-t.md"
printf 'CMD_VERIFY_STACK="echo STACK_COMPLETA"\nCMD_VERIFY_RAPIDO="echo STACK_RAPIDA"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
tl_espera 0 "rápido usa CMD_VERIFY_RAPIDO" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido"
tl_contem "STACK_RAPIDA" "roda o comando rápido"
tl_contem "VERIFY RÁPIDO: OK" "linha final própria"
copia=$(mktemp); cp "$TL_SAIDA" "$copia"
tl_espera 1 "rápido não imprime VERIFY: OK" grep -q "^VERIFY: OK" "$copia"
tl_espera 1 "rápido não roda skip" grep -q "== skip" "$copia"
tl_espera 1 "rápido não roda a stack completa" grep -q "STACK_COMPLETA" "$copia"
tl_espera 0 "completo continua com o rótulo de sempre" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: OK" "completo: VERIFY: OK"
tl_contem "STACK_COMPLETA" "completo roda a stack completa"
printf 'CMD_VERIFY_STACK="echo STACK_COMPLETA"\nCMD_VERIFY_RAPIDO="exit 1"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
tl_espera 1 "rápido falha quando o comando rápido falha" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido"
tl_contem "VERIFY RÁPIDO: FALHOU em: stack-rapido" "nomeia a etapa stack-rapido"
printf 'CMD_VERIFY_STACK="echo STACK_COMPLETA"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
tl_espera 0 "rápido sem a variável usa o stack completo com aviso" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido"
tl_contem "aviso: CMD_VERIFY_RAPIDO não configurado — usando CMD_VERIFY_STACK" "avisa"
tl_contem "STACK_COMPLETA" "usou o stack completo"
printf 'CMD_VERIFY_STACK="echo STACK_COMPLETA"\nCMD_VERIFY_RAPIDO="{{CMD_VERIFY_RAPIDO}}"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
tl_espera 0 "rápido com placeholder não preenchido conta como não configurado" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido"
tl_contem "aviso: CMD_VERIFY_RAPIDO" "avisa com placeholder"
tl_espera 0 "--task e --rapido em qualquer ordem (1)" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido --task agentic/projeto/specs/x/tasks/001-t.md"
tl_contem "escopo: OK" "--rapido --task: escopo verificado"
tl_espera 0 "--task e --rapido em qualquer ordem (2)" sh -c "cd '$r' && sh '$dir/verify.sh' --task agentic/projeto/specs/x/tasks/001-t.md --rapido"
tl_contem "VERIFY RÁPIDO: OK" "--task --rapido: rótulo rápido"
tl_espera 2 "opção desconhecida é erro de uso" sh -c "cd '$r' && sh '$dir/verify.sh' --foo"
tl_contem "uso: verify.sh [--rapido] [--task <task.md>]" "mostra o uso"

# --- Interrupção: TERM/INT não deixam o verify seguir para a etapa seguinte, nem soltar o lock com ele vivo.
# interrompe <repo> <sinal>: sobe o verify, espera a etapa stack começar, manda o sinal e devolve o código de saída.
# A saída do verify vai para a saída padrão; o estado do lock no instante do sinal, para <repo>/lock-no-sinal.
interrompe() {
  i_log=$(mktemp)
  ( cd "$1" && exec sh "$dir/verify.sh" ) > "$i_log" 2>&1 &
  i_pid=$!
  i_n=0
  until grep -q '^== stack' "$i_log" || [ "$i_n" -ge 60 ]; do sleep 1; i_n=$((i_n + 1)); done
  kill -s "$2" "$i_pid"
  if [ -d "$1/agentic/.estado/verify.lock" ]; then echo preso; else echo solto; fi > "$1/lock-no-sinal"
  wait "$i_pid"; i_rc=$?
  cat "$i_log"; rm -f "$i_log"
  return "$i_rc"
}
r=$(prepara)
echo "- agentic/config" >> "$r/agentic/projeto/specs/x/tasks/001-t.md"
printf 'CMD_VERIFY_STACK="sh tests/lenta.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
printf 'sleep 4\necho STACK_TERMINOU\n' > "$r/tests/lenta.sh"
tl_espera 143 "TERM no meio da stack: sai com 143" interrompe "$r" TERM
tl_contem "VERIFY: INTERROMPIDO" "declara a interrupção"
copia=$(mktemp); cp "$TL_SAIDA" "$copia"
tl_espera 1 "interrompido não segue para a etapa seguinte (skip)" grep -q "^== skip" "$copia"
tl_espera 1 "interrompido não imprime VERIFY: OK" grep -q "^VERIFY: OK" "$copia"
tl_espera 0 "o lock continua preso enquanto a etapa em curso não termina" grep -qx preso "$r/lock-no-sinal"
tl_espera 1 "o lock é solto na saída" test -d "$r/agentic/.estado/verify.lock"
rm -f "$r/lock-no-sinal"
tl_espera 0 "depois da interrupção, o verify roda de novo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: OK" "verify seguinte à interrupção passa"

# --- Tempo por etapa: cada linha de fechamento traz a duração em segundos.
r=$(prepara)
tl_espera 0 "verify com tempo por etapa" sh -c "cd '$r' && sh '$dir/verify.sh'"
copia=$(mktemp); cp "$TL_SAIDA" "$copia"
for e in hooks escopo decisoes red stack skip; do
  tl_espera 0 "etapa $e fecha com a duração" grep -qE "^-- $e: OK \([0-9]+ s\)$" "$copia"
done

# --- Log: a saída inteira fica em agentic/.estado/verify.log (rápido: verify-rapido.log), e a etapa que
# falhou é repetida no fim, logo antes da linha VERIFY. Um `| tail` basta para ver o motivo.
r=$(prepara)
echo "- agentic/config" >> "$r/agentic/projeto/specs/x/tasks/001-t.md"
printf 'CMD_VERIFY_STACK="echo SAIDA_COMPLETA"\nCMD_VERIFY_RAPIDO="echo SAIDA_RAPIDA"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
tl_espera 0 "completo grava o log" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "log: agentic/.estado/verify.log" "aponta o log"
tl_espera 0 "o log tem a saída da stack" grep -q SAIDA_COMPLETA "$r/agentic/.estado/verify.log"
tl_espera 0 "o log termina com a linha VERIFY" sh -c "tail -n 1 '$r/agentic/.estado/verify.log' | grep -qx 'VERIFY: OK'"
tl_espera 0 "rápido grava o próprio log" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido"
tl_contem "log: agentic/.estado/verify-rapido.log" "rápido aponta o próprio log"
tl_espera 0 "rápido: o log tem a saída rápida" grep -q SAIDA_RAPIDA "$r/agentic/.estado/verify-rapido.log"
tl_espera 0 "rápido não sobrescreve o log do completo" grep -q SAIDA_COMPLETA "$r/agentic/.estado/verify.log"
tl_espera 0 "o log não conta como arquivo fora do escopo" sh -c "cd '$r' && sh '$dir/verify.sh'"
cat > "$r/tests/longa.sh" <<'EOF'
i=0; while [ $i -lt 200 ]; do echo "linha $i"; i=$((i + 1)); done
echo MOTIVO_DA_FALHA
exit 1
EOF
printf 'CMD_VERIFY_STACK="sh tests/longa.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
tl_espera 1 "stack longa que falha" sh -c "cd '$r' && sh '$dir/verify.sh'"
copia=$(mktemp); cp "$TL_SAIDA" "$copia"
tl_espera 0 "o motivo da falha aparece nas últimas linhas da saída" sh -c "tail -n 8 '$copia' | grep -q MOTIVO_DA_FALHA"
tl_espera 0 "a linha VERIFY continua a última" sh -c "tail -n 1 '$copia' | grep -qx 'VERIFY: FALHOU em: stack'"
tl_espera 0 "o fim repete só o trecho final da etapa" sh -c "[ \$(grep -c '^linha 10\$' '$copia') -eq 1 ]"

# --- Prova do completo: OK numa árvore limpa fica guardada em <git-common-dir>/agentic/verify-provados;
# o completo seguinte na mesma árvore, base e config não roda de novo.
unset AGENTIC_VERIFY_SEM_CACHE
prova() {
  r=$(prepara)
  printf 'agentic/.estado/\n' > "$r/.gitignore"
  printf 'echo x >> "%s/contagem"\n' "$r/.git" > "$r/tests/conta.sh"
  echo "- agentic/config" >> "$r/agentic/projeto/specs/x/tasks/001-t.md"
  echo "- .gitignore" >> "$r/agentic/projeto/specs/x/tasks/001-t.md"
  printf 'CMD_VERIFY_STACK="sh tests/conta.sh"\nCMD_VERIFY_RAPIDO="sh tests/conta.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/agentic/config"
  git -C "$r" add -A; git -C "$r" commit -q -m "config com contagem"
  printf '%s\n' "$r"
}
contagem() { [ "$(wc -l < "$1/.git/contagem" | tr -d ' ')" -eq "$2" ]; }
r=$(prova)
tl_espera 0 "1º completo roda" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "2º completo na mesma árvore" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: OK (já provado nesta árvore)" "declara a prova reaproveitada"
tl_contem "AGENTIC_VERIFY_SEM_CACHE=1" "diz como refazer"
tl_espera 0 "a stack rodou uma vez só" contagem "$r" 1
tl_espera 0 "a prova fica no git-common-dir" test -s "$r/.git/agentic/verify-provados"
tl_espera 0 "AGENTIC_VERIFY_SEM_CACHE=1 roda de novo" env AGENTIC_VERIFY_SEM_CACHE=1 sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "sem cache: a stack rodou" contagem "$r" 2
tl_espera 0 "rápido nunca usa a prova" sh -c "cd '$r' && sh '$dir/verify.sh' --rapido"
tl_espera 0 "rápido: a stack rodou" contagem "$r" 3
d=$(mktemp -d)/wt; git -C "$r" worktree add -q --detach "$d" x/001 2>/dev/null
git -C "$d" config core.hooksPath agentic/mecanismos/githooks
tl_espera 0 "outro worktree no mesmo commit reaproveita a prova" sh -c "cd '$d' && sh '$dir/verify.sh' --task agentic/projeto/specs/x/tasks/001-t.md"
tl_contem "já provado nesta árvore" "worktree: prova reaproveitada"
tl_espera 0 "worktree: a stack não rodou" contagem "$r" 3
printf 'a\n' > "$r/tests/novo.txt"; git -C "$r" add -A; git -C "$r" commit -q -m "muda a árvore"
tl_espera 0 "árvore nova roda de novo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "árvore nova: a stack rodou" contagem "$r" 4
printf 'b\n' > "$r/tests/solto.txt"
tl_espera 0 "árvore suja roda" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "árvore suja não usa a prova" contagem "$r" 5
tl_espera 0 "árvore suja de novo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "árvore suja não guarda prova" contagem "$r" 6
rm "$r/tests/solto.txt"

r=$(prova)
printf 'echo x >> "%s/contagem"\nexit 1\n' "$r/.git" > "$r/tests/conta.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "stack vermelha"
tl_espera 1 "falha não vira prova (1)" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 1 "falha não vira prova (2)" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "falha: a stack rodou as duas vezes" contagem "$r" 2

r=$(prova)
printf 'echo x >> "%s/contagem"\necho y > tests/gerado.txt\n' "$r/.git" > "$r/tests/conta.sh"; git -C "$r" add -A; git -C "$r" commit -q -m "stack suja a árvore"
tl_espera 0 "stack que suja a árvore" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "prova do completo não guardada" "avisa que a stack sujou a árvore"
tl_contem "tests/gerado.txt" "nomeia o arquivo"
tl_espera 0 "stack que suja: roda de novo" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "stack que suja: a stack rodou as duas vezes" contagem "$r" 2

r=$(prova)
tl_espera 0 "prova guardada na branch x/001" sh -c "cd '$r' && sh '$dir/verify.sh'"
inicial=$(git -C "$r" rev-list --max-parents=0 HEAD)
tl_espera 0 "mesma árvore com outra base" env AGENTIC_BASE="$inicial" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_espera 0 "outra base: a stack rodou" contagem "$r" 2

# A config fora da árvore (ignorada): só a assinatura distingue uma mudança nas chaves TESTE_<n>_*.
# refaz <repo>: o completo passa e não responde pela prova guardada.
refaz() { o=$(sh -c "cd '$1' && sh '$dir/verify.sh'") || { echo "$o"; return 1; }; ! printf '%s' "$o" | grep -q 'já provado nesta árvore'; }
r=$(prova)
printf 'agentic/.estado/\nagentic/config\n' > "$r/.gitignore"
git -C "$r" rm -q --cached agentic/config; git -C "$r" add -A; git -C "$r" commit -q -m "config fora da árvore"
tl_espera 0 "config ignorada: 1º completo" sh -c "cd '$r' && sh '$dir/verify.sh'"
printf 'TESTE_1_PADROES="tests/a_*"\nTESTE_1_COMANDO="sh {}"\n' >> "$r/agentic/config"
tl_espera 0 "prova do completo: ligar TESTE_1_* roda tudo de novo" refaz "$r"
tl_espera 0 "prova do completo: mesma config TESTE_1_* reaproveita" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "já provado nesta árvore" "prova do completo: a assinatura com TESTE_1_* foi guardada"
printf 'TESTE_1_COMANDO="sh -x {}"\n' >> "$r/agentic/config"
tl_espera 0 "prova do completo: mudar TESTE_1_COMANDO roda tudo de novo" refaz "$r"
tl_espera 0 "prova do completo: a stack rodou nas três mudanças" contagem "$r" 3

tl_fim
