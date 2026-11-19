#!/bin/sh
# Testes do ativar-protecoes.sh (ação humana que instala o settings.json).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(tl_repo); mkdir -p "$r/agentic/.estado"; echo '{"x":1}' > "$r/agentic/.estado/settings.pendente.json"
tl_espera 0 "instala settings quando não existe" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem "git add .claude/settings.json && git commit" "orienta o commit humano do settings.json"
tl_espera 0 "conteúdo copiado" grep -q '"x":1' "$r/.claude/settings.json"

r=$(tl_repo); mkdir -p "$r/agentic/.estado" "$r/.claude"
echo '{"x":1}' > "$r/agentic/.estado/settings.pendente.json"; echo '{"meu":true}' > "$r/.claude/settings.json"
tl_espera 1 "não sobrescreve settings existente" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem "merge" "orienta o merge manual"
tl_espera 0 "settings original preservado" grep -q '"meu":true' "$r/.claude/settings.json"

r=$(tl_repo)
tl_espera 1 "falha sem settings pendente" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
# Proteções pendentes do Codex e do Antigravity (agentic/.estado/protecoes-pendentes/<caminho final>).
pend=agentic/.estado/protecoes-pendentes
# com_pendentes <repo>: settings pendente e um hooks.json pendente de cada ferramenta.
com_pendentes() {
  mkdir -p "$1/$pend/.codex/hooks" "$1/$pend/.agents/hooks"
  echo '{"x":1}' > "$1/agentic/.estado/settings.pendente.json"
  echo '{"codex":1}' > "$1/$pend/.codex/hooks.json"
  echo 'guarda' > "$1/$pend/.codex/hooks/guarda.sh"
  echo '{"ag":1}' > "$1/$pend/.agents/hooks.json"
  echo 'hash  x' > "$1/$pend/.kit-manifesto"
}
r=$(tl_repo); mkdir -p "$r/agentic/.estado"; com_pendentes "$r"
tl_espera 0 "instala settings e proteções pendentes" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem "/hooks" "avisa da confiança e da aprovação dos hooks no Codex"
tl_contem ".codex/hooks.json" "orienta o commit das proteções do Codex"
tl_espera 0 "copiou o hooks.json do Codex" grep -q '"codex":1' "$r/.codex/hooks.json"
tl_espera 0 "copiou o guarda do Codex" test -f "$r/.codex/hooks/guarda.sh"
tl_espera 0 "copiou o hooks.json do Antigravity" grep -q '"ag":1' "$r/.agents/hooks.json"
tl_espera 1 "manifesto dos pendentes não vai para a raiz" test -e "$r/.kit-manifesto"
tl_espera 0 "rodar de novo: destino igual não acusa nada" sh -c "cd '$r' && rm .claude/settings.json && sh '$dir/ativar-protecoes.sh'"

r=$(tl_repo); mkdir -p "$r/agentic/.estado" "$r/.claude"; com_pendentes "$r"; echo '{"meu":true}' > "$r/.claude/settings.json"
tl_espera 1 "settings existente: ainda instala as proteções e sai com 1" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem "merge" "orienta o merge do settings"
tl_espera 0 "settings existente: instalou o do Codex" grep -q '"codex":1' "$r/.codex/hooks.json"

r=$(tl_repo); mkdir -p "$r/agentic/.estado" "$r/.codex"; com_pendentes "$r"; echo '{"meu":2}' > "$r/.codex/hooks.json"
tl_espera 1 "proteção existente e diferente: não sobrescreve" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem ".codex/hooks.json" "lista a proteção diferente"
tl_espera 0 "proteção existente preservada" grep -q '"meu":2' "$r/.codex/hooks.json"
tl_espera 0 "as demais foram instaladas" test -f "$r/.agents/hooks.json"


tl_fim
