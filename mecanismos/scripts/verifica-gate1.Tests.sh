#!/bin/sh
# Testes do verifica-gate1.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() { # prepara <conteúdo do auto-mode> [com-D11]
  r=$(tl_repo); mkdir -p "$r/agentic/projeto"
  printf '%s\n' "$1" > "$r/agentic/auto-mode"
  printf '# Decisões\n\n## Vigentes\n\n### D11 — Delegação\n' > "$r/agentic/projeto/decisoes.md"
  git -C "$r" add -A; git -C "$r" commit -q -m "base"; git -C "$r" checkout -q -b feat/k
  printf '%s\n' "$r"
}
roda() { sh -c "cd '$1' && sh '$dir/verifica-gate1.sh'"; }

r=$(tl_repo)
tl_espera 0 "sem auto-mode: gate1 humano por padrão" roda "$r"
tl_contem "gate1: humano" "declara o modo"

r=$(prepara "enabled: true")
tl_espera 0 "auto-mode sem gate1: humano por padrão" roda "$r"

r=$(prepara "enabled: true
gate1: delegado
gate1_decisao: D11")
tl_espera 0 "delegado com decisão existente passa" roda "$r"
tl_contem "D11" "mostra a decisão"

r=$(prepara "gate1: delegado")
tl_espera 1 "delegado sem gate1_decisao bloqueia" roda "$r"
tl_contem "gate1_decisao" "explica o que falta"

r=$(prepara "gate1: delegado
gate1_decisao: D99")
tl_espera 1 "delegado com decisão inexistente bloqueia" roda "$r"
tl_contem "D99" "nomeia a decisão"

r=$(prepara "gate1: talvez")
tl_espera 1 "valor inválido de gate1 bloqueia" roda "$r"

r=$(prepara "gate1: delegado # delegado por Paulo
gate1_decisao: D11 # ver decisões")
tl_espera 0 "comentário na mesma linha é ignorado" roda "$r"

# commit que declara Gate 1 delegado
r=$(prepara "gate1: humano")
echo x > "$r/a"; git -C "$r" add -A; git -C "$r" commit -q -m "docs(spec): x aprovada (Gate 1 delegado — D11)"
tl_espera 1 "commit de Gate 1 delegado com auto-mode humano bloqueia" roda "$r"

r=$(prepara "gate1: delegado
gate1_decisao: D11")
echo x > "$r/a"; git -C "$r" add -A; git -C "$r" commit -q -m "docs(spec): x aprovada (Gate 1 delegado — D11)"
tl_espera 0 "commit de Gate 1 delegado coerente com o auto-mode passa" roda "$r"
echo y > "$r/b"; git -C "$r" add -A; git -C "$r" commit -q -m "docs(spec): y aprovada (Gate 1 delegado — D7)"
tl_espera 1 "commit que cita outra decisão bloqueia" roda "$r"

r=$(prepara "gate1: humano")
echo x > "$r/a"; git -C "$r" add -A; git -C "$r" commit -q -m "docs(spec): x aprovada (Gate 1)"
tl_espera 0 "commit de Gate 1 humano sempre passa" roda "$r"

tl_fim
