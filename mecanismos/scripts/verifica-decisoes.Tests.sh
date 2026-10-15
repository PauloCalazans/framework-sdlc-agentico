#!/bin/sh
# Testes do verifica-decisoes.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

reg() { # reg <repo> <ids...>: escreve o registro com uma decisão "### D<n>" por id
  r=$1; shift
  mkdir -p "$r/agentic/projeto"
  { printf '# Registro de decisões\n\n## Vigentes\n\n'; for n in "$@"; do printf '### D%s — t\n- **Decisão:** x\n\n' "$n"; done; printf '## Decisões revogadas\n\n<nenhuma>\n'; } > "$r/agentic/projeto/decisoes.md"
}
confirma() { git -C "$1" add -A; git -C "$1" commit -q -m "$2"; }
roda() { sh -c "cd '$1' && sh '$dir/verifica-decisoes.sh' $2"; }

r=$(tl_repo)
tl_espera 0 "sem registro de decisões: pulado" roda "$r"
tl_contem "pulado" "declara que pulou"

r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
mkdir -p "$r/agentic/projeto/specs/x"; printf 'Conforme D1 e (D2); veja D1.\n' > "$r/agentic/projeto/specs/x/design.md"
tl_espera 0 "referências a decisões existentes passam" roda "$r"

printf 'Decisão D7 pendente.\n' >> "$r/agentic/projeto/specs/x/design.md"
tl_espera 1 "referência a decisão inexistente bloqueia" roda "$r"
tl_contem "D7 (em agentic/projeto/specs/x/design.md)" "aponta a decisão e o arquivo"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf 'enabled: true\n# delegado (decisão D3)\n' > "$r/agentic/auto-mode"
tl_espera 1 "referência órfã no auto-mode bloqueia" roda "$r"
tl_contem "D3 (em agentic/auto-mode)" "aponta o auto-mode"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf 'ID1, AD7, D, D1a, XD9, D_8 e d5 não são referências.\n' > "$r/agentic/projeto/nota.md"
tl_espera 0 "tokens parecidos com D<n> não são referências" roda "$r"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf 'Tratado em D1\n' > "$r/agentic/projeto/nota.md"; printf '\n### D9 — extensão\n' >> "$r/agentic/projeto/decisoes.md"
sed -i.bak 's/D1$/D1, D9/' "$r/agentic/projeto/nota.md"; rm -f "$r/agentic/projeto/nota.md.bak"
tl_espera 0 "título de decisão com sufixo (D9 — extensão) conta como definida" roda "$r"

# (2) decisão da base que sumiu
r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
reg "$r" 1; confirma "$r" "perde a D2"
tl_espera 1 "decisão da base ausente em HEAD bloqueia" roda "$r"
tl_contem "D2" "nomeia a decisão perdida"

r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
reg "$r" 1 2 3; confirma "$r" "acrescenta a D3"
tl_espera 0 "acrescentar decisão passa" roda "$r"

# perda por merge: a principal ganha a D3 depois do fork; a branch faz merge e resolve descartando-a
r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
git -C "$r" checkout -q main; reg "$r" 1 2 3; confirma "$r" "main ganha D3"
git -C "$r" checkout -q feat/k; reg "$r" 1 2; printf 'x\n' > "$r/a.txt"; confirma "$r" "trabalho na branch"
tl_espera 0 "branch atrás da principal (sem a D3 nova) não é perda" roda "$r"
git -C "$r" merge -q -s ours main -m "merge descartando a D3" >/dev/null 2>&1
tl_espera 1 "merge que descarta decisão da principal bloqueia" roda "$r"
tl_contem "D3" "nomeia a decisão descartada no merge"

# revogada continua definida
r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf '# Registro\n\n## Vigentes\n\n### D1 — t\n\n## Decisões revogadas\n\n### D2 — t (revogada em 2026-10-10: motivo)\n' > "$r/agentic/projeto/decisoes.md"
printf 'D2\n' > "$r/agentic/projeto/nota.md"; confirma "$r" "revoga a D2"
tl_espera 0 "decisão movida para revogadas continua definida" roda "$r"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
tl_espera 1 "base explícita inválida bloqueia" roda "$r" nao-existe-xyz
tl_contem "base inválida" "explica base inválida"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" branch -m main trunk
tl_espera 0 "sem principal: degradado, não falha" roda "$r"
tl_contem "degradado" "declara a verificação degradada"

# Gate 1 delegado: gate1: D<n> no auto-mode aponta uma decisão vigente
vig() { # vig <repo> "<vigentes>" "<revogadas>"
  r=$1; mkdir -p "$r/agentic/projeto"
  { printf '# Registro\n\n## Vigentes\n\n'; for n in $2; do printf '### D%s — t\n\n' "$n"; done
    printf '## Decisões revogadas\n\n'; for n in $3; do printf '### D%s — t (revogada em 2026-10-10: motivo)\n\n' "$n"; done; } > "$r/agentic/projeto/decisoes.md"
}
modo() { printf '%s\n' "$2" > "$1/agentic/auto-mode"; }

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: true
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
tl_espera 0 "Gate 1 delegado por decisão vigente passa" roda "$r"

r=$(tl_repo); vig "$r" "1" "2"; modo "$r" 'enabled: true
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
tl_espera 1 "Gate 1 delegado por decisão revogada bloqueia" roda "$r"
tl_contem "D2, que não está vigente" "explica que a delegação perdeu a vigência"

r=$(tl_repo); vig "$r" "1" ""; modo "$r" 'enabled: true
gate1: sim'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
tl_espera 1 "gate1 sem D<n> bloqueia" roda "$r"
tl_contem "gate1: em agentic/auto-mode" "explica o formato de gate1"

r=$(tl_repo); vig "$r" "1" ""; modo "$r" 'enabled: true
gate1:'; confirma "$r" "humano"; git -C "$r" checkout -q -b feat/k
tl_espera 0 "gate1 vazio: Gate 1 humano, passa" roda "$r"

# commit de registro do Gate 1 delegado exige a delegação vigente
gate() { mkdir -p "$1/agentic/projeto/specs/x"; printf 'x\n' > "$1/agentic/projeto/specs/x/spec.md"; confirma "$1" "$2"; }

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: true
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
gate "$r" "docs(spec): x aprovada (Gate 1 delegado, D2)"
tl_espera 0 "commit de Gate 1 delegado com delegação vigente passa" roda "$r"

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: false
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
gate "$r" "docs(spec): x aprovada (Gate 1 delegado, D2)"
tl_espera 1 "commit de Gate 1 delegado com o modo automático desligado bloqueia" roda "$r"
tl_contem "registra Gate 1 delegado sem delegação vigente" "explica o bloqueio do commit"

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: true
gate1:'; confirma "$r" "humano"; git -C "$r" checkout -q -b feat/k
gate "$r" "docs(mudanca): x aprovada (Gate 1 delegado, D2)"
tl_espera 1 "commit de Gate 1 delegado sem gate1 no auto-mode bloqueia" roda "$r"

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: true
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
gate "$r" "docs(spec): x aprovada (Gate 1 delegado, D1)"
tl_espera 1 "commit de Gate 1 delegado citando outra decisão bloqueia" roda "$r"

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: true
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
gate "$r" "docs(spec): x aprovada (Gate 1 delegado)"
tl_espera 1 "commit de Gate 1 delegado sem D<n> bloqueia" roda "$r"

r=$(tl_repo); vig "$r" "1 2" ""; modo "$r" 'enabled: true
gate1: D2'; confirma "$r" "delega"; git -C "$r" checkout -q -b feat/k
gate "$r" "docs(spec): x aprovada (Gate 1 delegado, D2)"
vig "$r" "1" "2"; modo "$r" 'enabled: true
gate1:'; confirma "$r" "revoga a delegação"
tl_espera 1 "delegação revogada antes da integração bloqueia o Gate 1 delegado da branch" roda "$r"

tl_fim
