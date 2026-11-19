#!/bin/sh
# Testes do lib-guarda.sh: caminhos protegidos e comandos negados dos adaptadores Codex e Antigravity.
dir=$(cd "$(dirname "$0")" && pwd)
raiz=$(cd "$dir/../.." && pwd)
. "$raiz/mecanismos/scripts/testlib.sh"
. "$dir/lib-guarda.sh"

tmp=$(mktemp -d)
printf '%s\n' '# caminhos de teste' 'agentic/config' 'agentic/mecanismos/**' '' '.claude/hooks/**' > "$tmp/caminhos.txt"
printf '%s\n' '# comandos de teste' 'gh pr merge' 'git push --force' 'git reset --hard' 'sh agentic/mecanismos/scripts/ativar-protecoes.sh' > "$tmp/comandos.txt"
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
# Formas do mesmo caminho: o Windows ignora ponto e espaço no fim do nome; . e .. se resolvem.
for p in 'agentic/./config' 'agentic//config' 'agentic/x/../config' 'agentic/../agentic/config' 'agentic/config.' \
         'agentic/config ' 'Agentic\Config.' 'agentic./config' '.claude/hooks/../hooks/x.sh'; do
  tl_espera 0 "protegido: forma equivalente '$p'" guarda_protegido "$p" "$C"
done
tl_espera 1 "livre: agentic/config.d (ponto no meio)" guarda_protegido 'agentic/config.d' "$C"
tl_espera 1 "livre: agentic/x/../configx" guarda_protegido 'agentic/x/../configx' "$C"

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
# Embrulhos e formas compostas: o trecho negado aparece depois de subshell, palavra-chave, env, opção global do git…
for c in '(gh pr merge 1)' 'echo $(gh pr merge 1)' 'echo `gh pr merge 1`' 'if true; then gh pr merge 1; fi' \
         '{ gh pr merge 1; }' 'env gh pr merge 1' 'FOO=1 gh pr merge 1' 'env FOO=1 command gh pr merge 1' \
         'git  push --force' "git	push --force" 'Git Push --force' 'GH PR MERGE 1' \
         'pwsh -c "gh pr merge 1"' 'powershell -NoProfile -ExecutionPolicy Bypass -Command "gh pr merge 1"' \
         'bash --login -c "gh pr merge 1"' 'cmd /c bash -lc "gh pr merge 1"' \
         'git -C . reset --hard' 'git -c x=y reset --hard' 'git --no-pager -C sub push --force' \
         'bash agentic/mecanismos/scripts/ativar-protecoes.sh' 'sh.exe agentic/mecanismos/scripts/ativar-protecoes.sh'; do
  tl_espera 0 "negado: $c" guarda_negado "$c" "$N"
done
tl_espera 1 "não negado: git -C . status" guarda_negado 'git -C . status' "$N"
tl_espera 1 "não negado: env FOO=1 ls" guarda_negado 'env FOO=1 ls' "$N"
tl_espera 1 "não negado: powershell -Command git status" guarda_negado 'powershell -Command "git status"' "$N"

# guarda_texto <json> <campo>: valor em texto (com escapes desfeitos) ou lista juntada com espaço; ausente → 1.
tl_espera 0 "texto: campo string" guarda_texto '{"tool_input":{"command":"git commit -m \"a b\"\nx"}}' command
tl_contem 'git commit -m "a b"' "texto: aspas desescapadas"
tl_espera 0 "texto: campo lista" guarda_texto '{"tool_input":{"command":["git","commit","--no-verify"]}}' command
tl_contem 'git commit --no-verify' "texto: lista juntada"
tl_espera 0 "texto: barra invertida" guarda_texto '{"args":{"TargetFile":"C:\\proj\\a"}}' TargetFile
tl_contem 'C:\proj\a' "texto: \\\\ do JSON vira \\"
tl_espera 1 "texto: campo ausente" guarda_texto '{"tool_input":{}}' command
# texto_igual <json> <campo> <esperado>
texto_igual() { [ "$(guarda_texto "$1" "$2")" = "$3" ]; }
tl_espera 0 'texto: \u0026 vira &' texto_igual '{"c":"git add . \u0026\u0026 gh pr merge 1"}' c 'git add . && gh pr merge 1'
tl_espera 0 'texto: \u003c \u003e \u0027 \u0022 \u003B' texto_igual '{"c":"\u003c\u003e\u0027\u0022\u003B"}' c "<>'\";"
tl_espera 0 'texto: \\u0026 fica literal' texto_igual '{"c":"a\\u0026"}' c 'a\u0026'
tl_espera 0 'texto: \r some' texto_igual '{"c":"agentic/config\r"}' c 'agentic/config'
tl_espera 0 'texto: \u000d some' texto_igual '{"c":"agentic/config\u000d"}' c 'agentic/config'
tl_espera 0 'texto: \/ vira /' texto_igual '{"c":"agentic\/config"}' c 'agentic/config'
tl_espera 0 "lista ausente bloqueia (caminho)" guarda_protegido x /nao/existe
tl_contem "lista de proteção ausente" "lista ausente: mensagem"
tl_espera 0 "lista ausente bloqueia (comando)" guarda_negado 'ls' /nao/existe

rm -rf "$tmp"
tl_fim
