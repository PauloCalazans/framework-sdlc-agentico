#!/bin/sh
# Testes das funções de classificação e de executores do lib-agentic.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

# cfg <conteúdo>: repo novo com agentic/config igual ao conteúdo.
cfg() {
  r=$(tl_repo)
  mkdir -p "$r/agentic"
  printf '%s\n' "$1" > "$r/agentic/config"
}
# lib <comando>: roda o comando na raiz do repo, com a lib carregada.
lib() { sh -c "cd '$r' && . '$dir/lib-agentic.sh' && $1"; }

cfg 'DIRS_TESTE="tests/"
TESTE_1_PADROES="frontend/src/*.spec.ts"
TESTE_2_PADROES="backend/a/src/test/* backend/b/src/test/*"'
tl_espera 0 "e_teste: prefixo de DIRS_TESTE" lib 'agentic_e_teste tests/x.sh'
tl_espera 0 "e_teste: colocalizado casa padrão" lib 'agentic_e_teste frontend/src/app/x/x.component.spec.ts'
tl_espera 1 "e_teste: produção ao lado não casa" lib 'agentic_e_teste frontend/src/app/x/x.component.ts'
tl_espera 0 "executor: segundo padrão do bloco 2" lib '[ "$(agentic_executor backend/b/src/test/T.kt)" = 2 ]'
tl_espera 1 "executor: nenhum bloco" lib 'agentic_executor src/main.kt'
tl_espera 0 "executores: 1 e 2" lib '[ "$(agentic_executores | tr "\n" " ")" = "1 2 " ]'
tl_espera 0 "e_teste: padrão não expande contra o disco" sh -c "mkdir -p '$r/frontend/src' && touch '$r/frontend/src/a.spec.ts' && cd '$r' && . '$dir/lib-agentic.sh' && agentic_e_teste frontend/src/b.spec.ts"
tl_espera 0 "e_teste: preserva o set -f de quem chama" lib 'set -f; agentic_e_teste tests/x.sh; case $- in *f*) ;; *) exit 1 ;; esac'

cfg 'TESTE_1_PADROES="a/*"
TESTE_3_PADROES="c/*"'
tl_espera 0 "executores: para no buraco" lib '[ "$(agentic_executores 2>/dev/null)" = 1 ] && agentic_executores >/dev/null'
tl_contem "aviso: TESTE_3_PADROES ignorado — falta TESTE_2_PADROES" "executores: avisa o bloco ignorado"
tl_espera 1 "campo: n não numérico" lib 'agentic_executor_campo x COMANDO'
tl_espera 1 "campo: campo fora da lista" lib 'agentic_executor_campo 1 OUTRO'
tl_espera 0 "campo: lê o campo do bloco" lib '[ "$(agentic_executor_campo 1 PADROES)" = "a/*" ]'

cfg 'DIRS_TESTE="tests/"'
tl_espera 0 "executores: sem bloco, nada" lib '[ -z "$(agentic_executores)" ]'
tl_espera 0 "ambiente: TESTE_<n>_* exportado não vira executor (só o agentic/config vale)" env TESTE_1_PADROES='*' TESTE_1_COMANDO='exit 1' TESTE_2_PREPARO=x sh -c "cd '$r' && . '$dir/lib-agentic.sh' && [ -z \"\$(agentic_executores)\" ] && [ -z \"\${TESTE_2_PREPARO:-}\" ] && ! agentic_e_teste src/prod.sh"
tl_espera 1 "e_teste: sem bloco, só DIRS_TESTE" lib 'agentic_e_teste src/x.spec.ts'

tl_fim
