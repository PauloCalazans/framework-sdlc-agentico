#!/bin/sh
# Testes do lib-guarda.sh: caminhos protegidos e comandos negados dos adaptadores Codex e Antigravity.
dir=$(cd "$(dirname "$0")" && pwd)
raiz=$(cd "$dir/../.." && pwd)
. "$raiz/mecanismos/scripts/testlib.sh"
. "$dir/lib-guarda.sh"

tmp=$(mktemp -d)
printf '%s\n' '# caminhos de teste' 'agentic/config' 'agentic/mecanismos/**' '' '.claude/hooks/**' > "$tmp/caminhos.txt"
printf '%s\n' '# comandos de teste' 'gh pr merge' 'sh agentic/mecanismos/scripts/ativar-protecoes.sh' > "$tmp/comandos.txt"
C="$tmp/caminhos.txt"
N="$tmp/comandos.txt"

# com_raiz <raiz> <comando...>: roda com GUARDA_RAIZ fingida e a desfaz.
com_raiz() { GUARDA_RAIZ=$1; export GUARDA_RAIZ; shift; "$@"; tl_r=$?; unset GUARDA_RAIZ; return $tl_r; }

tl_espera 0 "protegido: agentic/config" guarda_protegido 'agentic/config' "$C"
tl_espera 0 "protegido: caminho do Windows com \ e drive" com_raiz 'C:/proj' guarda_protegido 'C:\proj\agentic\config' "$C"
tl_espera 0 "protegido: drive em minúscula" com_raiz 'C:/proj' guarda_protegido 'c:/proj/agentic/config' "$C"
tl_espera 0 "protegido: absoluto sob a raiz" com_raiz '/r' guarda_protegido '/r/agentic/mecanismos/scripts/verify.sh' "$C"
tl_espera 0 "protegido: dentro de um worktree" guarda_protegido 'agentic/.estado/worktrees/t/agentic/config' "$C"
tl_espera 0 "protegido: .claude/hooks/**" guarda_protegido '.claude/hooks/pre-tool-use.sh' "$C"
tl_espera 0 "protegido: ./ no começo" guarda_protegido './agentic/config' "$C"
tl_espera 1 "livre: agentic/configuracao.md" guarda_protegido 'agentic/configuracao.md' "$C"
tl_espera 1 "livre: src/agentic/config.js" guarda_protegido 'src/agentic/config.js' "$C"
tl_espera 1 "livre: agentic/projeto/decisoes.md" guarda_protegido 'agentic/projeto/decisoes.md' "$C"
tl_espera 1 "livre: agentic/mecanismos sem barra não é a pasta" guarda_protegido 'agentic/mecanismos-velhos.md' "$C"

tl_espera 0 "negado: gh pr merge 3" guarda_negado 'gh pr merge 3' "$N"
tl_espera 0 "negado: depois de &&" guarda_negado 'git add . && gh pr merge 3' "$N"
tl_espera 0 "negado: depois de ;" guarda_negado 'echo a; gh pr merge' "$N"
tl_espera 0 "negado: espaços na ponta" guarda_negado '  gh pr merge' "$N"
tl_espera 0 "negado: pelo lançador do Windows" guarda_negado 'git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/ativar-protecoes.sh' "$N"
tl_espera 0 "negado: dentro de bash -lc" guarda_negado 'bash -lc "gh pr merge 3"' "$N"
tl_espera 0 "negado: dentro de powershell -Command" guarda_negado 'powershell.exe -NoProfile -Command gh pr merge 3' "$N"
tl_espera 0 "negado: dentro de cmd /c" guarda_negado 'cmd /c gh pr merge 3' "$N"
tl_espera 1 "não negado: gh pr view 3" guarda_negado 'gh pr view 3' "$N"
tl_espera 1 "não negado: echo gh pr merge" guarda_negado 'echo gh pr merge' "$N"
tl_espera 1 "não negado: gh pr mergeX" guarda_negado 'gh pr mergeX' "$N"

# guarda_texto <json> <campo>: valor em texto (com escapes desfeitos) ou lista juntada com espaço; ausente → 1.
tl_espera 0 "texto: campo string" guarda_texto '{"tool_input":{"command":"git commit -m \"a b\"\nx"}}' command
tl_contem 'git commit -m "a b"' "texto: aspas desescapadas"
tl_espera 0 "texto: campo lista" guarda_texto '{"tool_input":{"command":["git","commit","--no-verify"]}}' command
tl_contem 'git commit --no-verify' "texto: lista juntada"
tl_espera 0 "texto: barra invertida" guarda_texto '{"args":{"TargetFile":"C:\\proj\\a"}}' TargetFile
tl_contem 'C:\proj\a' "texto: \\\\ do JSON vira \\"
tl_espera 1 "texto: campo ausente" guarda_texto '{"tool_input":{}}' command
tl_espera 0 "lista ausente bloqueia (caminho)" guarda_protegido x /nao/existe
tl_contem "lista de proteção ausente" "lista ausente: mensagem"
tl_espera 0 "lista ausente bloqueia (comando)" guarda_negado 'ls' /nao/existe

rm -rf "$tmp"
tl_fim
