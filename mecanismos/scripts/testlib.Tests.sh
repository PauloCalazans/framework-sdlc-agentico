#!/bin/sh
# Testes da própria testlib: um caso que passa e a detecção de um caso que falha.
. "$(dirname "$0")/testlib.sh"

repo=$(tl_repo)
tl_espera 0 "tl_repo cria repositório com commit inicial em main" git -C "$repo" rev-parse --verify -q main
tl_espera 0 "tl_espera aceita código esperado" sh -c 'exit 0'
tl_espera 3 "tl_espera compara código diferente de zero" sh -c 'echo saida-x; exit 3'
tl_contem "saida-x" "tl_contem encontra texto na saída do último comando"

# Uma falha proposital, executada num subshell isolado, deve fazer tl_fim retornar 1.
( . "$(dirname "$0")/testlib.sh"; tl_espera 0 "falha proposital" sh -c 'exit 1' >/dev/null; tl_fim >/dev/null )
tl_espera 1 "tl_fim retorna 1 quando há falha" sh -c "exit $?"

tl_fim
