#!/bin/sh
# Testes do instalar.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

r=$(tl_repo)
tl_espera 0 "instala num repositório git" sh "$dir/instalar.sh" "$r"
for f in AGENTS.md CLAUDE.md agentic/processo/ciclo.md agentic/processo/modelos.md agentic/processo/principios.md agentic/processo/entrevista.md \
         agentic/processo/papeis/dev.md agentic/processo/templates/task.md agentic/processo/templates/mudanca.md .claude/commands/mudanca.md agentic/mecanismos/githooks/pre-commit agentic/mecanismos/githooks/pre-push \
         agentic/mecanismos/scripts/verify.sh agentic/mecanismos/scripts/lib-agentic.sh .claude/agents/revisor.md \
         .claude/commands/bootstrap.md .claude/hooks/pre-tool-use.sh agentic/config agentic/auto-mode \
         agentic/.estado/settings.pendente.json; do
  tl_espera 0 "copiou $f" test -f "$r/$f"
done
# Na raiz só entra o que as ferramentas exigem lá; o resto do kit vive em agentic/.
tl_espera 0 "raiz recebe só AGENTS.md, CLAUDE.md, .claude/, agentic/, .gitignore e .gitattributes" sh -c \
  "[ \"\$(ls -A '$r' | grep -vx '.git' | sort | tr '\n' ' ')\" = '.claude .gitattributes .gitignore AGENTS.md CLAUDE.md agentic ' ]"
tl_espera 1 "não instala settings.json direto (ação humana)" test -f "$r/.claude/settings.json"
tl_espera 1 "não copia suítes *.Tests.sh do kit" sh -c "find '$r' -name '*.Tests.sh' | grep -q ."
tl_espera 1 "não copia testlib.sh" sh -c "find '$r' -name 'testlib.sh' | grep -q ."
set -f # os padrões abaixo são literais
for p in .claude/settings.json .claude/hooks/** agentic/config agentic/auto-mode agentic/mecanismos/** \
         agentic/baseline-skips .gitleaksignore; do
  tl_espera 0 "settings pendente nega Edit (cobre escrita) em $p" sh -c "grep -qF '\"Edit($p)\"' '$r/agentic/.estado/settings.pendente.json'"
done
set +f
for c in "git add" "git commit" "git checkout" "git rebase"; do
  tl_espera 0 "settings pendente permite Bash($c:*)" grep -qF "\"Bash($c:*)\"" "$r/agentic/.estado/settings.pendente.json"
done
if command -v node >/dev/null 2>&1; then
  tl_espera 0 "settings pendente é JSON válido" node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$r/agentic/.estado/settings.pendente.json"
fi
tl_espera 0 "configura core.hooksPath" sh -c "[ \"\$(git -C '$r' config core.hooksPath)\" = agentic/mecanismos/githooks ]"
tl_espera 0 ".gitignore ignora agentic/.estado/ (uma linha)" grep -qxF "agentic/.estado/" "$r/.gitignore"
set -f
for p in .claude/settings.json .claude/settings.local.json .claude/hooks/** agentic/config agentic/auto-mode agentic/mecanismos/** \
         agentic/baseline-skips .gitleaksignore; do
  tl_espera 0 "settings pendente nega Edit (cobre escrita) em **/$p (worktree aninhado)" sh -c "grep -qF '\"Edit(**/$p)\"' '$r/agentic/.estado/settings.pendente.json'"
done
set +f
tl_espera 0 ".gitattributes força LF em sh (Review Focus 1)" grep -qF "*.sh text eol=lf" "$r/.gitattributes"
tl_espera 0 ".gitattributes força LF nos githooks" grep -qF "agentic/mecanismos/githooks/* text eol=lf" "$r/.gitattributes"

tl_espera 0 "reinstalar é idempotente" sh "$dir/instalar.sh" "$r"
tl_espera 1 "sem conflitos na reinstalação" test -f "$r/agentic/.estado/conflitos-instalacao.txt"
tl_espera 0 ".gitignore sem linhas duplicadas" sh -c "[ \$(grep -cxF 'agentic/.estado/' '$r/.gitignore') -eq 1 ]"

r=$(tl_repo); echo "meu claude" > "$r/CLAUDE.md"
tl_espera 0 "instala com arquivo pré-existente" sh "$dir/instalar.sh" "$r"
tl_espera 0 "preserva o CLAUDE.md existente" grep -qx "meu claude" "$r/CLAUDE.md"
tl_espera 0 "registra o conflito" grep -qx "CLAUDE.md" "$r/agentic/.estado/conflitos-instalacao.txt"

r=$(tl_repo); printf 'node_modules/' > "$r/.gitignore"; printf '*.png binary' > "$r/.gitattributes"
tl_espera 0 "instala com .gitignore/.gitattributes sem quebra final" sh "$dir/instalar.sh" "$r"
tl_espera 0 ".gitignore preserva linha original" grep -qxF "node_modules/" "$r/.gitignore"
tl_espera 0 ".gitignore: nova linha isolada" grep -qxF "agentic/.estado/" "$r/.gitignore"
tl_espera 0 ".gitattributes preserva linha original" grep -qxF "*.png binary" "$r/.gitattributes"
tl_espera 0 ".gitattributes: nova linha isolada" grep -qxF "*.sh text eol=lf" "$r/.gitattributes"
sh "$dir/instalar.sh" "$r" >/dev/null
tl_espera 0 "reinstalação sem duplicar" sh -c "[ \$(wc -l < '$r/.gitignore') -eq 2 ] && [ \$(wc -l < '$r/.gitattributes') -eq 3 ]"

r=$(tl_repo); mkdir -p "$r/agentic/.estado"; echo "velho" > "$r/agentic/.estado/conflitos-instalacao.txt"
tl_espera 0 "instala com conflitos-instalacao.txt obsoleto" sh "$dir/instalar.sh" "$r"
tl_espera 1 "remove arquivo de conflitos obsoleto" test -f "$r/agentic/.estado/conflitos-instalacao.txt"

tl_espera 1 "agente-template não vive em .claude/agents" test -e "$r/.claude/agents/_oraculo.md"
tl_espera 0 "template do agente oráculo vai para agentic/processo/templates" test -f "$r/agentic/processo/templates/agente-oraculo.md"

r=$(tl_repo); mkdir -p "$r/.claude"; echo '{"meu":1}' > "$r/.claude/settings.json"; echo "meu claude" > "$r/CLAUDE.md"
tl_espera 0 "instala com settings.json pré-existente" sh "$dir/instalar.sh" "$r"
tl_espera 0 "settings.json existente entra nos conflitos" grep -qx ".claude/settings.json" "$r/agentic/.estado/conflitos-instalacao.txt"
tl_espera 0 "settings.json existente preservado" grep -qF '"meu":1' "$r/.claude/settings.json"
tl_espera 0 "guarda a versão do kit do CLAUDE.md" cmp -s "$dir/../adapters/claude-code/CLAUDE.md" "$r/agentic/.estado/kit-conflitos/CLAUDE.md"
tl_espera 0 "guarda o template de settings do kit" test -f "$r/agentic/.estado/kit-conflitos/.claude/settings.json"
rm "$r/CLAUDE.md"; rm "$r/.claude/settings.json"
tl_espera 0 "reinstala sem conflitos" sh "$dir/instalar.sh" "$r"
tl_espera 1 "kit-conflitos removido no início da execução" test -e "$r/agentic/.estado/kit-conflitos"

tl_espera 2 "recusa alvo que não é git" sh "$dir/instalar.sh" "$(mktemp -d)"
tl_espera 2 "recusa sem argumento" sh "$dir/instalar.sh"

tl_fim
