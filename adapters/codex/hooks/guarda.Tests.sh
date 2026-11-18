#!/bin/sh
# Testes do guarda.sh do Codex: monta .codex/hooks/ e .claude/hooks/ num repositório temporário, como na instância.
dir=$(cd "$(dirname "$0")" && pwd)
kit=$(cd "$dir/../../.." && pwd)
. "$kit/mecanismos/scripts/testlib.sh"

r=$(tl_repo)
mkdir -p "$r/.codex/hooks" "$r/.claude/hooks"
cp "$dir/guarda.sh" "$kit/adapters/comum/lib-guarda.sh" "$kit/adapters/comum/caminhos-protegidos.txt" \
   "$kit/adapters/comum/comandos-negados.txt" "$r/.codex/hooks/"
cp "$kit/adapters/claude-code/hooks/pre-tool-use.sh" "$r/.claude/hooks/"

# roda <json>: o guarda com o JSON na entrada, a partir da raiz do repositório temporário.
roda() { printf '%s' "$1" | (cd "$r" && sh .codex/hooks/guarda.sh); }

tl_espera 2 "bash: --no-verify" roda '{"tool_name":"Bash","tool_input":{"command":"git commit -m x --no-verify"}}'
tl_contem "agentic:" "bash: motivo começa por agentic:"
tl_espera 2 "bash: --no-verify na forma de lista" roda '{"tool_name":"Bash","tool_input":{"command":["git","commit","--no-verify"]}}'
tl_espera 2 "bash: gh pr merge (lista de negados)" roda '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 3"}}'
tl_espera 2 "bash: gh pr merge dentro de powershell -Command" roda '{"tool_name":"Bash","tool_input":{"command":["powershell.exe","-Command","gh pr merge 3"]}}'
tl_espera 2 "bash: ativar-protecoes pelo lançador" roda '{"tool_name":"Bash","tool_input":{"command":"git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/ativar-protecoes.sh"}}'
tl_espera 0 "bash: git status passa" roda '{"tool_name":"Bash","tool_input":{"command":"git status"}}'
tl_espera 0 "bash: verify pelo lançador passa" roda '{"tool_name":"Bash","tool_input":{"command":"git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/verify.sh"}}'

tl_espera 2 "patch: Update File agentic/config" roda '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: agentic/config\n@@\n-a\n+b\n*** End Patch"}}'
tl_contem "agentic/config" "patch: motivo cita o caminho"
tl_espera 2 "patch: Add File .codex/hooks.json" roda '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Add File: .codex/hooks.json\n+{}\n*** End Patch"}}'
tl_espera 2 "patch: Move to agentic/auto-mode" roda '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: notas.md\n*** Move to: agentic/auto-mode\n*** End Patch"}}'
tl_espera 2 "patch: Delete File com caminho do Windows" roda '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Delete File: agentic\\mecanismos\\scripts\\verify.sh\n*** End Patch"}}'
tl_espera 0 "patch: só src/a.js passa" roda '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: src/a.js\n@@\n-a\n+b\n*** End Patch"}}'

tl_espera 2 "entrada sem command bloqueia" roda '{"tool_name":"Bash","tool_input":{}}'
tl_contem "entrada ilegível" "entrada sem command: motivo"
tl_espera 2 "patch sem command bloqueia" roda '{"tool_name":"apply_patch","tool_input":{"patch":"x"}}'

# O comando do PreToolUse do hooks.json, exatamente como está escrito (o lançador do Windows), também bloqueia.
cp "$dir/../hooks.json" "$r/.codex/hooks.json"
cmd=$(tr -d '\r' < "$r/.codex/hooks.json" | grep -o '"command": *"[^"]*guarda\.sh"' | sed -E 's/^"command": *"(.*)"$/\1/')
tl_espera 0 "hooks.json: comando do PreToolUse encontrado" test -n "$cmd"
hook() { printf '%s' "$1" | (cd "$r/.codex" && sh -c "$cmd"); }
tl_espera 2 "hooks.json: lançador roda o guarda e bloqueia --no-verify (de uma subpasta)" hook '{"tool_name":"Bash","tool_input":{"command":"git push origin main --no-verify"}}'
tl_espera 0 "hooks.json: lançador deixa passar git status" hook '{"tool_name":"Bash","tool_input":{"command":"git status"}}'

rm -rf "$r"
tl_fim
