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
tl_espera 2 "bloqueia raiz de drive com barra invertida" roda 'find C:\ -name x'
tl_espera 2 "bloqueia ls -R no home" roda 'ls -R ~'
tl_espera 0 "permite find no diretório atual" roda 'find . -name x'
tl_espera 0 "permite find em caminho absoluto específico" roda 'find /tmp/x -name y'
tl_espera 0 "permite grep -r num diretório do projeto" roda 'grep -r foo src/'
tl_espera 0 "permite ls não recursivo da raiz" roda 'ls -la /'
tl_espera 0 "permite comandos comuns" roda 'git log --format=%H'

tl_fim
