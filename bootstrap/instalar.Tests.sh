#!/bin/sh
# Testes do instalar.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

r=$(tl_repo)
tl_espera 0 "instala num repositório git" sh "$dir/instalar.sh" "$r"
for f in AGENTS.md CLAUDE.md docs/agentic/ciclo.md docs/agentic/principios.md docs/agentic/entrevista.md \
         docs/agentic/papeis/dev.md docs/agentic/templates/task.md .githooks/pre-commit .githooks/pre-push \
         scripts/agentic/verify.sh scripts/agentic/lib-agentic.sh .claude/agents/revisor.md \
         .claude/commands/bootstrap.md .claude/hooks/pre-tool-use.sh .agentic/config .agentic/auto-mode \
         .agentic/settings.pendente.json; do
  tl_espera 0 "copiou $f" test -f "$r/$f"
done
tl_espera 1 "não instala settings.json direto (ação humana)" test -f "$r/.claude/settings.json"
tl_espera 1 "não copia suítes *.Tests.sh do kit" sh -c "find '$r' -name '*.Tests.sh' | grep -q ."
tl_espera 1 "não copia testlib.sh" sh -c "find '$r' -name 'testlib.sh' | grep -q ."
set -f # os padrões abaixo são literais
for p in .claude/settings.json .claude/hooks/** .agentic/config .agentic/auto-mode .githooks/** \
         scripts/agentic/** .agentic/baseline-skips .gitleaksignore; do
  tl_espera 0 "settings pendente nega Edit (cobre escrita) em $p" sh -c "grep -qF '\"Edit($p)\"' '$r/.agentic/settings.pendente.json'"
done
set +f
for c in "git add" "git commit" "git checkout" "git rebase"; do
  tl_espera 0 "settings pendente permite Bash($c:*)" grep -qF "\"Bash($c:*)\"" "$r/.agentic/settings.pendente.json"
done
if command -v node >/dev/null 2>&1; then
  tl_espera 0 "settings pendente é JSON válido" node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$r/.agentic/settings.pendente.json"
fi
tl_espera 0 "configura core.hooksPath" sh -c "[ \"\$(git -C '$r' config core.hooksPath)\" = .githooks ]"
tl_espera 0 ".gitignore ignora execucao" grep -qxF ".agentic/execucao/" "$r/.gitignore"
set -f
for p in .claude/settings.json .claude/settings.local.json .claude/hooks/** .agentic/config .agentic/auto-mode .githooks/** \
         scripts/agentic/** .agentic/baseline-skips .gitleaksignore; do
  tl_espera 0 "settings pendente nega Edit (cobre escrita) em **/$p (worktree aninhado)" sh -c "grep -qF '\"Edit(**/$p)\"' '$r/.agentic/settings.pendente.json'"
done
set +f
tl_espera 0 ".gitignore ignora worktrees aninhados" grep -qxF ".agentic/worktrees/" "$r/.gitignore"
tl_espera 0 ".gitattributes força LF em sh (Review Focus 1)" grep -qF "*.sh text eol=lf" "$r/.gitattributes"
tl_espera 0 ".gitattributes força LF nos githooks" grep -qF ".githooks/* text eol=lf" "$r/.gitattributes"

tl_espera 0 "reinstalar é idempotente" sh "$dir/instalar.sh" "$r"
tl_espera 1 "sem conflitos na reinstalação" test -f "$r/.agentic/conflitos-instalacao.txt"
tl_espera 0 ".gitignore sem linhas duplicadas" sh -c "[ \$(grep -cxF '.agentic/execucao/' '$r/.gitignore') -eq 1 ]"

r=$(tl_repo); echo "meu claude" > "$r/CLAUDE.md"
tl_espera 0 "instala com arquivo pré-existente" sh "$dir/instalar.sh" "$r"
tl_espera 0 "preserva o CLAUDE.md existente" grep -qx "meu claude" "$r/CLAUDE.md"
tl_espera 0 "registra o conflito" grep -qx "CLAUDE.md" "$r/.agentic/conflitos-instalacao.txt"

r=$(tl_repo); printf 'node_modules/' > "$r/.gitignore"; printf '*.png binary' > "$r/.gitattributes"
tl_espera 0 "instala com .gitignore/.gitattributes sem quebra final" sh "$dir/instalar.sh" "$r"
tl_espera 0 ".gitignore preserva linha original" grep -qxF "node_modules/" "$r/.gitignore"
tl_espera 0 ".gitignore: nova linha isolada" grep -qxF ".agentic/execucao/" "$r/.gitignore"
tl_espera 0 ".gitattributes preserva linha original" grep -qxF "*.png binary" "$r/.gitattributes"
tl_espera 0 ".gitattributes: nova linha isolada" grep -qxF "*.sh text eol=lf" "$r/.gitattributes"
sh "$dir/instalar.sh" "$r" >/dev/null
tl_espera 0 "reinstalação sem duplicar" sh -c "[ \$(wc -l < '$r/.gitignore') -eq 4 ] && [ \$(wc -l < '$r/.gitattributes') -eq 3 ]"

r=$(tl_repo); mkdir -p "$r/.agentic"; echo "velho" > "$r/.agentic/conflitos-instalacao.txt"
tl_espera 0 "instala com conflitos-instalacao.txt obsoleto" sh "$dir/instalar.sh" "$r"
tl_espera 1 "remove arquivo de conflitos obsoleto" test -f "$r/.agentic/conflitos-instalacao.txt"

tl_espera 2 "recusa alvo que não é git" sh "$dir/instalar.sh" "$(mktemp -d)"
tl_espera 2 "recusa sem argumento" sh "$dir/instalar.sh"

tl_fim
