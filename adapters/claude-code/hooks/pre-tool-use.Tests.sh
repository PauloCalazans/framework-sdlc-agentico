#!/bin/sh
# Testes do hook PreToolUse mínimo (varredura de disco).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../../../mecanismos/scripts/testlib.sh"

json() { printf '{"tool_name":"Bash","tool_input":{"command":"%s","description":"d"}}' "$1"; }
roda() { json "$1" | sh "$dir/pre-tool-use.sh"; }

tl_espera 2 "bloqueia find /" roda 'find / -name x'
tl_contem "varredura" "explica o bloqueio"
tl_espera 2 "bloqueia grep -r na raiz" roda 'grep -rn senha /'
tl_espera 2 "bloqueia find na raiz de drive" roda 'find C:/ -name x'
tl_espera 2 "bloqueia raiz de drive com barra invertida" roda 'find C:\\ -name x'
tl_espera 2 "bloqueia ls -R no home" roda 'ls -R ~'
tl_espera 0 "permite find no diretório atual" roda 'find . -name x'
tl_espera 0 "permite find em caminho absoluto específico" roda 'find /tmp/x -name y'
tl_espera 0 "permite grep -r num diretório do projeto" roda 'grep -r foo src/'
tl_espera 0 "permite ls não recursivo da raiz" roda 'ls -la /'
tl_espera 0 "permite comandos comuns" roda 'git log --format=%H'

# Desvio dos githooks: o deny casa por prefixo; o hook olha o comando inteiro.
tl_espera 2 "bloqueia push com --no-verify depois do refspec" roda 'git push origin main --no-verify'
tl_contem "githooks" "explica o bloqueio do desvio"
tl_espera 2 "bloqueia abreviação --no-veri" roda 'git push --no-veri origin x'
tl_espera 2 "bloqueia commit -m ... --no-verify" roda 'git commit -m msg --no-verify'
tl_espera 2 "bloqueia commit -n no fim" roda 'git commit -m msg -n'
tl_espera 2 "bloqueia commit -nm" roda 'git commit -nm msg'
tl_espera 2 "bloqueia -c core.hooksPath" roda 'git -c core.hooksPath=/dev/null push origin main'
tl_espera 2 "bloqueia desvio depois de &&" roda 'git add -A && git commit -m x --no-verify'
tl_espera 0 "permite push comum" roda 'git push -u origin feat/x'
tl_espera 0 "permite commit com mensagem que tem -n no texto entre aspas simples" roda "git commit -m 'teste'"
tl_espera 0 "permite push -n (dry-run)" roda 'git push -n origin feat/x'
tl_espera 0 "permite git log -n 5" roda 'git log -n 5'

tl_espera 2 "bloqueia git -C dir commit -n" roda 'git -C sub commit -n -m x'
tl_espera 2 "bloqueia -c core.HooksPath (maiúscula)" roda 'git -c core.HooksPath=/x push'
tl_espera 2 "bloqueia -c entre aspas" roda 'git -c \"core.hooksPath=/x\" commit -m y'
tl_espera 2 "bloqueia --config-env" roda 'git --config-env=core.hooksPath=X push'
tl_espera 2 "bloqueia GIT_CONFIG_*" roda 'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/x git push'
tl_espera 2 "bloqueia git config --local core.hooksPath" roda 'git config --local core.hooksPath /x'
tl_espera 0 "permite -n dentro da mensagem entre aspas" roda 'git commit -m \"remove -n e --no-verify do texto\"'
tl_espera 0 "permite heredoc com -n no corpo" roda 'git commit -F - <<EOF\nusa head -n 1\nEOF'
tl_espera 2 "bloqueia --no-verify na linha que abre o heredoc" roda 'git commit --no-verify -F - <<EOF\nmsg\nEOF'
tl_espera 0 "permite comando sem git com descrição citando git" sh -c "printf '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls -n\",\"description\":\"git commit -n\"}}' | sh '$dir/pre-tool-use.sh'"

tl_fim
