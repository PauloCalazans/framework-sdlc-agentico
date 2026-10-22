#!/bin/sh
# Testes do status-projeto.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(tl_repo)
mkdir -p "$r/agentic/projeto/intent" "$r/agentic/projeto/specs/pedidos/tasks" "$r/agentic/.estado"
printf '# Intent: pedidos\n**Status:** aprovado\n' > "$r/agentic/projeto/intent/001-pedidos.md"
printf '# Task 001\n**Status:** em-andamento\n**Branch:** pedidos/001\n' > "$r/agentic/projeto/specs/pedidos/tasks/001-criar.md"
printf '# modelo\n**Status:** <x>\n' > "$r/agentic/projeto/specs/_template.md"
echo "enabled: true" > "$r/agentic/auto-mode"
git -C "$r" checkout -q -b pedidos/001
git -C "$r" commit -q --allow-empty -m "w1"

tl_espera 0 "status sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Branch atual: pedidos/001" "mostra a branch atual"
tl_contem "agentic/projeto/intent/001-pedidos.md: aprovado" "lista status de intent"
tl_contem "agentic/projeto/specs/pedidos/tasks/001-criar.md: em-andamento" "lista status de task"
tl_contem "pedidos/001: 1 commit(s)" "mostra branch à frente da principal"
tl_contem "Modo automático: ligado" "lê o auto-mode"
tl_contem "Gate 1: humano" "sem gate1, o Gate 1 é humano"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "ignora arquivos _modelo" grep -q "_template" "$copia_saida"

# Review Focus 2: repositório sem a branch principal.
r2=$(mktemp -d); git -C "$r2" init -q -b trabalho
tl_espera 0 "não quebra sem a branch principal e sem commits" sh -c "cd '$r2' && sh '$dir/status-projeto.sh'"
tl_contem "Modo automático: desligado" "auto-mode ausente = desligado"
tl_contem "Gate 1: humano" "auto-mode ausente = Gate 1 humano"

printf 'enabled: true\ngate1: D4\n' > "$r/agentic/auto-mode"
tl_espera 0 "status com Gate 1 delegado sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Gate 1: delegado ao orquestrador (D4)" "mostra a decisão que delega o Gate 1"
printf 'enabled: false\ngate1: D4\n' > "$r/agentic/auto-mode"
tl_espera 0 "status com modo automático desligado sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Gate 1: humano" "delegação só vale com o modo automático ligado"

# integrada deriva do git: task publicada cuja versão na principal (local ou origin/) também está publicada.
r3=$(tl_repo)
t=agentic/projeto/specs/pedidos/tasks
mkdir -p "$r3/$t"
printf '# Task 001\n**Status:** pendente\n' > "$r3/$t/001-integrada.md"
printf '# Task 002\n**Status:** pendente\n' > "$r3/$t/002-aberta.md"
printf '# Task 003\n**Status:** em-andamento\n' > "$r3/$t/003-andamento.md"
printf '# Task 004\n**Status:** pendente\n' > "$r3/$t/004-remota.md"
git -C "$r3" add -A; git -C "$r3" commit -q -m "Gate 1"
printf '# Task 001\n**Status:** publicada — PR #1\n' > "$r3/$t/001-integrada.md"
git -C "$r3" commit -q -am "docs(task): 001 publicada"   # merge na principal
printf '# Task 004\n**Status:** publicada\n' > "$r3/$t/004-remota.md"
git -C "$r3" commit -q -am "docs(task): 004 publicada"
git -C "$r3" update-ref refs/remotes/origin/main HEAD    # 004 integrada no remoto
git -C "$r3" reset -q --hard HEAD~1                      # main local ainda sem o merge da 004
git -C "$r3" checkout -q -b pedidos/002
printf '# Task 002\n**Status:** publicada\n' > "$r3/$t/002-aberta.md"
printf '# Task 004\n**Status:** publicada\n' > "$r3/$t/004-remota.md"
git -C "$r3" commit -q -am "docs(task): 002 publicada (PR aberto)"
tl_espera 0 "status com tasks publicadas sai com 0" sh -c "cd '$r3' && sh '$dir/status-projeto.sh'"
tl_contem "001-integrada.md: integrada (derivado do git) — publicada — PR #1" "publicada também na principal: integrada"
tl_contem "002-aberta.md: publicada" "publicada só na branch (PR aberto): continua publicada"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "PR aberto não aparece como integrada" grep -q "002-aberta.md: integrada" "$copia_saida"
tl_espera 0 "status diferente de publicada não muda" grep -q "003-andamento.md: em-andamento$" "$copia_saida"
tl_espera 0 "publicada na principal remota (local desatualizada): integrada" grep -q "004-remota.md: integrada (derivado do git) — publicada$" "$copia_saida"

tl_fim
