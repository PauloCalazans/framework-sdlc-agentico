#!/bin/sh
# migrar-layout.sh <projeto> — move uma instância do layout antigo (docs/agentic, scripts/agentic, .githooks,
# .agentic, intent/, docs/specs) para o layout atual, tudo sob agentic/. AÇÃO HUMANA: mexe em superfícies
# de política (settings, hooks, config). Trabalha numa branch nova e só stageia — o commit é do humano.
fw=$(cd "$(dirname "$0")/.." && pwd)
alvo=${1:-}
{ [ -n "$alvo" ] && [ -d "$alvo" ]; } || { echo "uso: migrar-layout.sh <projeto>" >&2; exit 2; }
cd "$alvo" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "o alvo não é um repositório git: $alvo" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)" || exit 2
recusa() { echo "migrar-layout: RECUSADO — $*" >&2; exit 1; }

[ -f scripts/agentic/lib-agentic.sh ] || recusa "não é uma instância no layout antigo (falta scripts/agentic/lib-agentic.sh)"
[ ! -e agentic ] || recusa "agentic/ já existe — instância já migrada?"
[ -z "$(git status --porcelain)" ] || recusa "há mudanças não commitadas; commite ou descarte antes"
[ "$(git worktree list | wc -l)" -eq 1 ] || recusa "há worktrees ativos (git worktree list); integre ou remova antes — mover .agentic/worktrees os quebraria"

branch=agentic/migrar-layout
git switch -q -c "$branch" || recusa "não foi possível criar a branch $branch"

move() { # move <origem> <destino>: git mv se rastreado, mv se não; nada se não existe
  [ -e "$1" ] || return 0
  mkdir -p "$(dirname "$2")"
  if [ -n "$(git ls-files -- "$1" | head -n 1)" ]; then git mv -k "$1" "$2"; fi
  [ -e "$1" ] && mv "$1" "$2" # sobra não rastreada (ou diretório só ignorado)
  return 0
}

for f in principios.md ciclo.md entrevista.md papeis templates; do move "docs/agentic/$f" "agentic/processo/$f"; done
move scripts/agentic agentic/mecanismos/scripts
move .githooks agentic/mecanismos/githooks
for f in config auto-mode baseline-skips; do move ".agentic/$f" "agentic/$f"; done
for f in execucao kit-conflitos settings.pendente.json conflitos-instalacao.txt; do move ".agentic/$f" "agentic/.estado/$f"; done
rm -rf .agentic/verify.lock .agentic/worktrees
move intent agentic/projeto/intent
move docs/specs agentic/projeto/specs
for f in decisoes.md bootstrap.md bootstrap-respostas.md; do move "docs/$f" "agentic/projeto/$f"; done
for d in .agentic/* .agentic/.[!.]*; do [ -e "$d" ] && move "$d" "agentic/.estado/${d#.agentic/}"; done
for d in docs/agentic .agentic scripts docs; do rmdir "$d" 2>/dev/null; done

# Mecanismos são do kit (o agente não os edita): entram na versão atual do kit, já no layout novo.
( cd "$fw/mecanismos/scripts" && find . -type f ! -name '*.Tests.sh' ! -name 'testlib.sh' ) | while IFS= read -r f; do
  cp "$fw/mecanismos/scripts/$f" "agentic/mecanismos/scripts/$f"
done
for h in pre-commit pre-merge-commit pre-push; do cp "$fw/mecanismos/githooks/$h" "agentic/mecanismos/githooks/$h"; done

# Reescreve caminhos. Os padrões inequívocos valem em todo arquivo rastreado (ex.: CI chamando
# scripts/agentic/verify.sh); intent/ é palavra comum e só é reescrito nos arquivos do framework.
reescreve() { # reescreve <arquivo> <expressões sed>
  tmp=$(mktemp) || exit 1
  sed -E "$2" "$1" > "$tmp" && ! cmp -s "$tmp" "$1" && cat "$tmp" > "$1"
  rm -f "$tmp"
}
comuns='s#docs/agentic/#agentic/processo/#g
s#docs/agentic([^A-Za-z0-9_/-]|$)#agentic/processo\1#g
s#scripts/agentic/#agentic/mecanismos/scripts/#g
s#\.githooks#agentic/mecanismos/githooks#g
s#\.agentic/(config|auto-mode|baseline-skips)#agentic/\1#g
s#\.agentic/#agentic/.estado/#g
s#docs/specs#agentic/projeto/specs#g
s#docs/(decisoes|bootstrap|bootstrap-respostas)\.md#agentic/projeto/\1.md#g'
framework='s#(^|[^A-Za-z0-9_./-])intent/#\1agentic/projeto/intent/#g'
git add -A
git -c core.quotepath=off grep -I -l -E 'docs/agentic|scripts/agentic|\.githooks|\.agentic/|docs/specs|docs/(decisoes|bootstrap)' -- . ':!.gitignore' \
  | while IFS= read -r f; do reescreve "$f" "$comuns"; done
git -c core.quotepath=off ls-files -- AGENTS.md CLAUDE.md .claude agentic | while IFS= read -r f; do
  case "$f" in agentic/mecanismos/*) ;; *.md|*.json|*.sh) reescreve "$f" "$framework" ;; esac
done

# .gitignore: as entradas de estado viram uma só; .gitattributes segue os githooks.
if [ -f .gitignore ]; then
  reescreve .gitignore '/^\.agentic\/(execucao|verify\.lock|worktrees|kit-conflitos)\/$/d'
  grep -qxF "agentic/.estado/" .gitignore || printf 'agentic/.estado/\n' >> .gitignore
fi

git config core.hooksPath agentic/mecanismos/githooks
git add -A
git add --chmod=+x agentic/mecanismos/githooks/pre-commit agentic/mecanismos/githooks/pre-merge-commit agentic/mecanismos/githooks/pre-push

echo "Layout migrado na branch $branch (stageado, sem commit)."
echo "Próximos passos (ação humana):"
echo "  1. Revise: git diff --cached --stat (e o diff de .claude/settings.json e dos mecanismos)"
echo "  2. git commit -m 'chore: migra o framework agêntico para o layout agentic/'"
echo "  3. git switch <principal> && git merge --ff-only $branch && git branch -d $branch"
echo "  4. sh <framework>/bootstrap/checa-instancia.sh ."
