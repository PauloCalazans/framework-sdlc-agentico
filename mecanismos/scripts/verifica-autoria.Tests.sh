#!/bin/sh
# Testes do verifica-autoria.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo); echo base > "$r/base"; mkdir -p "$r/agentic"; printf 'AUTORIA="%s"\n' "${1:-exigida}" > "$r/agentic/config"
  git -C "$r" add -A; git -C "$r" commit -q -m base
  git -C "$r" checkout -q -b feat/k; printf '%s\n' "$r"
}
# c <repo> <assunto> [trailers...]: commit com trailers (um por argumento)
c() {
  cr=$1; cs=$2; shift 2
  echo "$cs" >> "$cr/f"; git -C "$cr" add -A
  { printf '%s\n' "$cs"; if [ $# -gt 0 ]; then printf '\n'; for t in "$@"; do printf '%s\n' "$t"; done; fi; } | git -C "$cr" commit -q -F -
}
roda() { sh -c "cd '$1' && sh '$dir/verifica-autoria.sh' $2"; }
RED="Papel: testes"; KIRO="Agente: Kiro/Claude Sonnet 5"; GEM="Agente: Antigravity/Gemini 3.8 Flash"

r=$(prepara)
tl_espera 0 "branch sem commits de trabalho: nada a verificar" roda "$r"

r=$(prepara); c "$r" "test(red): x" "$RED" "$KIRO"; c "$r" "feat(green): x" "Papel: dev" "$KIRO"
tl_espera 0 "trailers corretos passam (sem revisão ainda)" roda "$r"
tl_contem "ainda sem registro de revisão" "avisa que falta a revisão"
tl_contem "testes: Kiro/Claude Sonnet 5" "imprime o resumo Papel → Agente"
tl_espera 1 "--publicar sem revisão bloqueia" roda "$r" --publicar

r=$(prepara); c "$r" "test(red): x"
tl_espera 1 "commit de trabalho sem trailers bloqueia" roda "$r"
tl_contem "sem trailers" "explica"

r=$(prepara); c "$r" "test(red): x" "Papel: dev" "$KIRO"
tl_espera 1 "Papel incompatível com o tipo do commit bloqueia" roda "$r"
tl_contem "incompatível" "explica"

r=$(prepara); c "$r" "feat(green): x" "Papel: dev" "Agente: Kiro"
tl_espera 1 "Agente fora do formato produto/modelo bloqueia" roda "$r"
tl_contem "<produto>/<modelo>" "explica o formato"

r=$(prepara); c "$r" "test(red): x" "$RED" "$KIRO"; c "$r" "fix: ajusta o teste" "$RED" "$KIRO"; c "$r" "fix: corrige o código" "Papel: dev" "$KIRO"
tl_espera 0 "fix aceita Papel testes ou dev" roda "$r"

r=$(prepara); c "$r" "docs(spec): x aprovada (Gate 1)"; c "$r" "chore: y"
tl_espera 0 "docs e chore não exigem trailers" roda "$r"

# independência
r=$(prepara); c "$r" "test(red): x" "$RED" "$KIRO"; c "$r" "feat(green): x" "Papel: dev" "$KIRO"
c "$r" "docs(task): x em-revisão" "Revisor: Antigravity/Gemini 3.8 Flash" "Veredito: APROVADO"
tl_espera 0 "revisor de outro produto/modelo é independente" roda "$r" --publicar
tl_contem "revisor: Antigravity/Gemini 3.8 Flash" "inclui o revisor no resumo"

r=$(prepara); c "$r" "test(red): x" "$RED" "$KIRO"; c "$r" "feat(green): x" "Papel: dev" "$KIRO"
c "$r" "docs(task): x em-revisão" "Revisor: Kiro/Claude Sonnet 5" "Veredito: APROVADO"
tl_espera 1 "revisor igual ao autor bloqueia" roda "$r"
tl_contem "não é independente" "explica"

r=$(prepara); c "$r" "test(red): x" "$RED" "$KIRO"; c "$r" "feat(green): x" "Papel: dev" "$KIRO"
c "$r" "docs(task): x em-revisão" "Revisor: Kiro/Claude Opus 5.5" "Veredito: APROVADO"
tl_espera 0 "mesmo produto, modelo diferente: independente no padrão (agente)" roda "$r"
printf 'REVISOR_DISTINTO_POR="produto"\n' >> "$r/agentic/config"
tl_espera 1 "REVISOR_DISTINTO_POR=produto exige produto diferente" roda "$r"

# publicação
r=$(prepara); c "$r" "feat(green): x" "Papel: dev" "$KIRO"
c "$r" "docs(task): x em-revisão" "Revisor: Antigravity/Gemini 3.8 Flash" "Veredito: DEVOLVIDO"
tl_espera 1 "--publicar com veredito DEVOLVIDO bloqueia" roda "$r" --publicar
tl_contem "APROVADO" "explica"

r=$(prepara); c "$r" "feat(green): x" "Papel: dev" "$KIRO"
c "$r" "docs(task): x em-revisão" "Revisor: Antigravity/Gemini 3.8 Flash" "Veredito: APROVADO"
c "$r" "fix: depois da revisão" "Papel: dev" "$KIRO"
tl_espera 1 "--publicar com revisão anterior ao último trabalho bloqueia" roda "$r" --publicar
tl_contem "anterior" "explica"

r=$(prepara); c "$r" "feat(green): x" "Papel: dev" "$KIRO"
git -C "$r" branch -m main trunk
tl_espera 0 "sem principal: degradado, não falha" roda "$r"
tl_contem "degradado" "declara"

# opt-in: desligada (padrão) não verifica nada; aviso nunca bloqueia
r=$(tl_repo); git -C "$r" checkout -q -b feat/k; c "$r" "test(red): x"
tl_espera 0 "sem AUTORIA configurada (padrão desligada): não verifica" roda "$r"
tl_contem "desligada" "declara que está desligada"

r=$(prepara aviso); c "$r" "test(red): x"; c "$r" "feat(green): x" "Papel: dev" "$KIRO"
c "$r" "docs(task): x em-revisão" "Revisor: Kiro/Claude Sonnet 5" "Veredito: APROVADO"
tl_espera 0 "AUTORIA=aviso não bloqueia nem trailers ausentes nem revisor igual" roda "$r" --publicar
tl_contem "aviso: " "mas avisa"
tl_contem "não é independente" "inclusive a independência"


r=$(prepara); printf 'AUTORIA="talvez"\n' > "$r/agentic/config"
tl_espera 1 "valor inválido de AUTORIA bloqueia" roda "$r"

tl_fim
