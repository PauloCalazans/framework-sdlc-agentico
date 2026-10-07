#!/bin/sh
# Testes do migrar-layout.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

# antigo: monta uma instância mínima no layout antigo, commitada na main.
antigo() {
  a=$(tl_repo)
  mkdir -p "$a/docs/agentic/papeis" "$a/docs/agentic/templates" "$a/scripts/agentic" "$a/.githooks" "$a/.agentic/execucao/x" \
           "$a/intent" "$a/docs/specs/pedidos/tasks" "$a/.claude/agents" "$a/src" "$a/.github/workflows"
  printf 'Fluxo: intent/NNN.md e docs/specs/<nome>/spec.md\n' > "$a/docs/agentic/ciclo.md"
  printf 'princípios\n' > "$a/docs/agentic/principios.md"
  printf 'entrevista\n' > "$a/docs/agentic/entrevista.md"
  printf 'Contexto preenchido: `npm test`\n' > "$a/docs/agentic/papeis/dev.md"
  printf 'template\n' > "$a/docs/agentic/templates/task.md"
  cp "$dir/../mecanismos/scripts/lib-agentic.sh" "$a/scripts/agentic/lib-agentic.sh"
  printf 'velho\n' > "$a/scripts/agentic/verify.sh"
  for h in pre-commit pre-merge-commit pre-push; do printf '#!/bin/sh\nexit 0\n' > "$a/.githooks/$h"; done
  printf 'CMD_TESTE="npm test"\n' > "$a/.agentic/config"
  printf 'enabled: false\n' > "$a/.agentic/auto-mode"
  printf '# ledger\n' > "$a/.agentic/execucao/x/progress.md"
  printf '# Intent\n**Status:** aprovado\n' > "$a/intent/001-pedidos.md"
  printf '# Spec\n**Intent:** intent/001-pedidos.md\n' > "$a/docs/specs/pedidos/spec.md"
  printf '**Branch:** pedidos/001\n' > "$a/docs/specs/pedidos/tasks/001-criar.md"
  printf '# Decisões\n' > "$a/docs/decisoes.md"
  printf '# Bootstrap\n' > "$a/docs/bootstrap.md"
  printf 'Rode `sh scripts/agentic/verify.sh`. Intents em `intent/`; decisões em `docs/decisoes.md`.\n' > "$a/AGENTS.md"
  printf 'Leia `docs/agentic/papeis/dev.md`.\n' > "$a/.claude/agents/dev.md"
  printf '{"deny":["Edit(.githooks/**)","Edit(.agentic/config)"],"hook":"$CLAUDE_PROJECT_DIR/scripts/agentic/status-projeto.sh"}\n' > "$a/.claude/settings.json"
  printf 'run: sh scripts/agentic/verify.sh\n' > "$a/.github/workflows/ci.yml"
  printf '// rota intent/criar não é do framework\n' > "$a/src/app.js"
  printf 'node_modules/\n.agentic/execucao/\n.agentic/verify.lock/\n.agentic/worktrees/\n.agentic/kit-conflitos/\n' > "$a/.gitignore"
  printf '*.sh text eol=lf\n.githooks/* text eol=lf\n' > "$a/.gitattributes"
  git -C "$a" add -A
  git -C "$a" add --chmod=+x .githooks/pre-commit .githooks/pre-merge-commit .githooks/pre-push
  git -C "$a" commit -q -m "instância antiga"
  git -C "$a" config core.hooksPath .githooks
  printf '%s\n' "$a"
}

r=$(antigo)
tl_espera 0 "migra uma instância no layout antigo" sh "$dir/migrar-layout.sh" "$r"
tl_contem "agentic/migrar-layout" "informa a branch da migração"
tl_espera 0 "trabalha na branch agentic/migrar-layout" sh -c "[ \"\$(git -C '$r' symbolic-ref --short HEAD)\" = agentic/migrar-layout ]"
tl_espera 0 "não commita (stageia para o humano)" sh -c "[ \"\$(git -C '$r' rev-list --count HEAD)\" = 2 ] && [ -n \"\$(git -C '$r' diff --cached --name-only)\" ]"
for f in agentic/processo/ciclo.md agentic/processo/principios.md agentic/processo/entrevista.md agentic/processo/papeis/dev.md \
         agentic/processo/templates/task.md agentic/mecanismos/scripts/verify.sh agentic/mecanismos/githooks/pre-push \
         agentic/config agentic/auto-mode agentic/projeto/intent/001-pedidos.md agentic/projeto/specs/pedidos/spec.md \
         agentic/projeto/specs/pedidos/tasks/001-criar.md agentic/projeto/decisoes.md agentic/projeto/bootstrap.md \
         agentic/.estado/execucao/x/progress.md; do
  tl_espera 0 "moveu para $f" test -f "$r/$f"
done
tl_espera 0 "raiz sem pastas do layout antigo" sh -c "[ \"\$(ls -A '$r' | grep -vx '.git' | sort | tr '\n' ' ')\" = '.claude .gitattributes .github .gitignore AGENTS.md agentic src ' ]"
tl_espera 0 "preserva o contexto do papel" grep -qF 'Contexto preenchido: `npm test`' "$r/agentic/processo/papeis/dev.md"
tl_espera 0 "mecanismos entram na versão do kit" cmp -s "$dir/../mecanismos/scripts/verify.sh" "$r/agentic/mecanismos/scripts/verify.sh"
tl_espera 0 "githooks entram na versão do kit" cmp -s "$dir/../mecanismos/githooks/pre-commit" "$r/agentic/mecanismos/githooks/pre-commit"
tl_espera 0 "spec aponta o intent no lugar novo" grep -qxF '**Intent:** agentic/projeto/intent/001-pedidos.md' "$r/agentic/projeto/specs/pedidos/spec.md"
tl_espera 0 "ciclo reescrito" grep -qxF 'Fluxo: agentic/projeto/intent/NNN.md e agentic/projeto/specs/<nome>/spec.md' "$r/agentic/processo/ciclo.md"
tl_espera 0 "AGENTS.md reescrito" grep -qxF 'Rode `sh agentic/mecanismos/scripts/verify.sh`. Intents em `agentic/projeto/intent/`; decisões em `agentic/projeto/decisoes.md`.' "$r/AGENTS.md"
tl_espera 0 "agente reescrito" grep -qF 'agentic/processo/papeis/dev.md' "$r/.claude/agents/dev.md"
tl_espera 0 "settings reescrito" grep -qxF '{"deny":["Edit(agentic/mecanismos/githooks/**)","Edit(agentic/config)"],"hook":"$CLAUDE_PROJECT_DIR/agentic/mecanismos/scripts/status-projeto.sh"}' "$r/.claude/settings.json"
tl_espera 0 "CI reescrito" grep -qxF 'run: sh agentic/mecanismos/scripts/verify.sh' "$r/.github/workflows/ci.yml"
tl_espera 0 "código de produto intocado" grep -qxF '// rota intent/criar não é do framework' "$r/src/app.js"
tl_espera 0 ".gitignore com uma linha de estado" sh -c "[ \"\$(cat '$r/.gitignore' | tr '\n' ' ')\" = 'node_modules/ agentic/.estado/ ' ]"
tl_espera 0 ".gitattributes segue os githooks" grep -qxF 'agentic/mecanismos/githooks/* text eol=lf' "$r/.gitattributes"
tl_espera 0 "core.hooksPath aponta o lugar novo" sh -c "[ \"\$(git -C '$r' config core.hooksPath)\" = agentic/mecanismos/githooks ]"
tl_espera 0 "githooks 100755 no índice" sh -c "[ \"\$(git -C '$r' ls-files -s agentic/mecanismos/githooks | cut -d' ' -f1 | sort -u)\" = 100755 ]"
tl_espera 0 "renomes preservam histórico" sh -c "git -C '$r' diff --cached -M --name-status | grep -q '^R.*intent/001-pedidos.md'"

tl_espera 1 "recusa instância já migrada" sh "$dir/migrar-layout.sh" "$r"
tl_contem "RECUSADO" "explica a recusa"

r=$(antigo); echo sujo >> "$r/AGENTS.md"
tl_espera 1 "recusa árvore com mudanças não commitadas" sh "$dir/migrar-layout.sh" "$r"
tl_espera 0 "não mexe em nada ao recusar" test -d "$r/scripts/agentic"

r=$(antigo); git -C "$r" worktree add -q "$r/.agentic/worktrees/w" -b w
tl_espera 1 "recusa com worktrees ativos" sh "$dir/migrar-layout.sh" "$r"
tl_contem "worktree" "aponta os worktrees"

tl_espera 1 "recusa projeto fora do layout antigo" sh "$dir/migrar-layout.sh" "$(tl_repo)"
tl_espera 2 "recusa alvo que não é git" sh "$dir/migrar-layout.sh" "$(mktemp -d)"
tl_espera 2 "recusa sem argumento" sh "$dir/migrar-layout.sh"

tl_fim
