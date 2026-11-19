#!/bin/sh
# Testes do guarda.sh e do inicio.sh do Antigravity: monta .agents/hooks/ e .claude/hooks/ num repositório temporário.
dir=$(cd "$(dirname "$0")" && pwd)
kit=$(cd "$dir/../../.." && pwd)
. "$kit/mecanismos/scripts/testlib.sh"

r=$(tl_repo)
mkdir -p "$r/.agents/hooks" "$r/.claude/hooks" "$r/agentic/mecanismos/scripts"
cp "$dir/guarda.sh" "$dir/inicio.sh" "$kit/adapters/comum/lib-guarda.sh" "$kit/adapters/comum/caminhos-protegidos.txt" \
   "$kit/adapters/comum/comandos-negados.txt" "$r/.agents/hooks/"
cp "$kit/adapters/claude-code/hooks/pre-tool-use.sh" "$r/.claude/hooks/"
printf '%s\n' '#!/bin/sh' 'echo "Projeto: teste \"x\""' 'echo "Fase: RED"' > "$r/agentic/mecanismos/scripts/status-projeto.sh"

# roda <json>: o guarda com o JSON na entrada; o código vai para o arquivo $r/codigo.
roda() { printf "%s" "$1" | (cd "$r" && sh .agents/hooks/guarda.sh) > "$r/saida"; echo $? > "$r/codigo"; cat "$r/saida"; }
saiu0() { [ "$(cat "$r/codigo")" = 0 ]; }
# um_objeto: a última saída é uma linha só, um objeto JSON, sem aspas soltas no reason.
um_objeto() { [ "$(wc -l < "$r/saida")" -eq 1 ] && grep -qE '^\{"decision":"(allow|deny)"(,"reason":"([^"\\]|\\.)*")?\}$' "$r/saida"; }
cmd() { roda "{\"toolCall\":{\"name\":\"run_command\",\"args\":{\"CommandLine\":\"$1\",\"Cwd\":\"C:\\\\proj\"}},\"workspacePaths\":[\"C:\\\\proj\"]}"; }
esc() { roda "{\"toolCall\":{\"name\":\"$1\",\"args\":{\"TargetFile\":\"$2\"}}}"; }

tl_espera 0 "run_command --no-verify" cmd 'git push origin main --no-verify'
tl_contem '"decision":"deny"' "--no-verify: deny"
tl_espera 0 "deny: um objeto JSON" um_objeto
tl_espera 0 "deny: sai com 0" saiu0
tl_espera 0 "run_command && gh pr merge" cmd 'git add . && gh pr merge 1'
tl_contem '"decision":"deny"' "&& gh pr merge: deny"
tl_espera 0 "run_command reset --hard" cmd 'git reset --hard HEAD~1'
tl_contem '"decision":"deny"' "reset --hard: deny"
tl_espera 0 "run_command commit -m com aspas e --no-verify" cmd 'git commit -m \"a\" --no-verify'
tl_contem '"decision":"deny"' "commit com aspas: deny"
tl_espera 0 "deny com aspas no comando: um objeto JSON" um_objeto
win() { GUARDA_RAIZ=C:/proj; export GUARDA_RAIZ; esc write_to_file 'C:\\proj\\agentic\\config'; unset GUARDA_RAIZ; }
tl_espera 0 "write_to_file com caminho do Windows (raiz C:/proj)" win
tl_contem '"decision":"deny"' "TargetFile do Windows: deny"
tl_espera 0 "replace_file_content .agents/hooks.json" esc replace_file_content '.agents/hooks.json'
tl_contem '"decision":"deny"' ".agents/hooks.json: deny"
tl_espera 0 "run_command sem CommandLine" roda '{"toolCall":{"name":"run_command","args":{"Cwd":"x"}}}'
tl_contem 'entrada ilegível' "sem CommandLine: deny com motivo"
tl_contem '"decision":"deny"' "sem CommandLine: deny"
tl_espera 0 "ferramenta desconhecida" roda '{"toolCall":{"name":"outra","args":{}}}'
tl_contem '"decision":"deny"' "ferramenta desconhecida: deny"
tl_espera 0 "npm test" cmd 'npm test'
tl_contem '"decision":"allow"' "npm test: allow"
tl_espera 0 "allow: um objeto JSON" um_objeto
tl_espera 0 "write_to_file src/a.js" esc write_to_file 'src/a.js'
tl_contem '"decision":"allow"' "src/a.js: allow"

# inicio.sh: o status vira mensagem de sistema.
ini() { (cd "$r" && sh .agents/hooks/inicio.sh); }
tl_espera 0 "inicio.sh roda" ini
tl_contem '{"injectSteps":[{"systemMessage":{"systemMessage":"' "inicio: formato injectSteps"
tl_contem 'Fase: RED' "inicio: traz o status"
tl_contem 'teste \"x\"' "inicio: aspas escapadas"

# O comando do PreToolUse do hooks.json, exatamente como está escrito (o lançador do Windows), nega --no-verify.
cp "$dir/../hooks.json" "$r/.agents/hooks.json"
hc=$(tr -d '\r' < "$r/.agents/hooks.json" | grep -o '"command": *"[^"]*guarda\.sh"' | sed -E 's/^"command": *"(.*)"$/\1/')
tl_espera 0 "hooks.json: comando do PreToolUse encontrado" test -n "$hc"
hook() { printf '%s' '{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit --no-verify -m x"}}}' | (cd "$r/.agents" && sh -c "$hc"); }
tl_espera 0 "hooks.json: lançador roda o guarda (de uma subpasta)" hook
tl_contem '"decision":"deny"' "hooks.json: lançador nega --no-verify"

# Escapes que o JSON permite e o comando não pode esconder: & como escape unicode.
tl_espera 0 "run_command && como escape unicode" roda '{"toolCall":{"name":"run_command","args":{"CommandLine":"git add . \u0026\u0026 gh pr merge 1"}}}'
tl_contem '"decision":"deny"' "&& em escape unicode: deny"
# pre-tool-use.sh com erro (código diferente de 2) nega: erro não vira liberação.
cp "$r/.claude/hooks/pre-tool-use.sh" "$r/ptu.bak"
printf '%s\n' '#!/bin/sh' 'echo falhou >&2' 'exit 1' > "$r/.claude/hooks/pre-tool-use.sh"
tl_espera 0 "run_command com pre-tool-use.sh com erro" cmd 'git status'
tl_contem '"decision":"deny"' "erro do pre-tool-use: deny"
tl_espera 0 "erro do pre-tool-use: um objeto JSON" um_objeto
cp "$r/ptu.bak" "$r/.claude/hooks/pre-tool-use.sh"

# lib-guarda.sh ausente nega, com um objeto JSON.
mv "$r/.agents/hooks/lib-guarda.sh" "$r/lib.bak"
tl_espera 0 "run_command com lib-guarda.sh ausente" cmd 'git status'
tl_contem '"decision":"deny"' "lib ausente: deny"
tl_espera 0 "lib ausente: um objeto JSON" um_objeto
mv "$r/lib.bak" "$r/.agents/hooks/lib-guarda.sh"

rm -rf "$r"
tl_fim
