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
tl_contem "Gate 1: humano" "gate1 ausente = humano"
printf 'enabled: true\ngate1: delegado\ngate1_decisao: D11 # nota\n' > "$r/agentic/auto-mode"
tl_espera 0 "status com Gate 1 delegado" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Gate 1: delegado (D11)" "mostra o Gate 1 delegado e a decisão"
echo "enabled: true" > "$r/agentic/auto-mode"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "ignora arquivos _modelo" grep -q "_template" "$copia_saida"

# Review Focus 2: repositório sem a branch principal.
r2=$(mktemp -d); git -C "$r2" init -q -b trabalho
tl_espera 0 "não quebra sem a branch principal e sem commits" sh -c "cd '$r2' && sh '$dir/status-projeto.sh'"
tl_contem "Modo automático: desligado" "auto-mode ausente = desligado"

tl_fim
