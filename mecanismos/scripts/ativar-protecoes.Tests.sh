#!/bin/sh
# Testes do ativar-protecoes.sh (ação humana que instala o settings.json).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(tl_repo); mkdir -p "$r/.agentic"; echo '{"x":1}' > "$r/.agentic/settings.pendente.json"
tl_espera 0 "instala settings quando não existe" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_espera 0 "conteúdo copiado" grep -q '"x":1' "$r/.claude/settings.json"

r=$(tl_repo); mkdir -p "$r/.agentic" "$r/.claude"
echo '{"x":1}' > "$r/.agentic/settings.pendente.json"; echo '{"meu":true}' > "$r/.claude/settings.json"
tl_espera 1 "não sobrescreve settings existente" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem "merge" "orienta o merge manual"
tl_espera 0 "settings original preservado" grep -q '"meu":true' "$r/.claude/settings.json"

r=$(tl_repo)
tl_espera 1 "falha sem settings pendente" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"

tl_fim
