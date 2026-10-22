#!/bin/sh
# status-projeto.sh — estado do projeto DERIVADO do git e dos campos **Status:**.
# Nada aqui é escrito à mão. Executado no início de cada sessão (hook SessionStart).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 0

echo "## Estado do projeto (derivado — não edite à mão)"
echo "Branch atual: $(git symbolic-ref --short -q HEAD || echo '(detached)')"

echo
echo "### Worktrees"
git worktree list 2>/dev/null

echo
echo "### Branches à frente de $BRANCH_PRINCIPAL"
if git rev-parse --verify -q "$BRANCH_PRINCIPAL" >/dev/null; then
  git for-each-ref --format='%(refname:short)' refs/heads | while read -r b; do
    [ "$b" = "$BRANCH_PRINCIPAL" ] && continue
    n=$(git rev-list --count "$BRANCH_PRINCIPAL..$b" 2>/dev/null || echo "?")
    [ "$n" = "0" ] || echo "- $b: $n commit(s)"
  done
else
  echo "- (branch principal '$BRANCH_PRINCIPAL' ainda não existe)"
fi

echo
echo "### Artefatos"
find agentic/projeto/intent agentic/projeto/specs -name '*.md' ! -name '_*' 2>/dev/null | sort | while read -r f; do
  s=$(grep -m1 '^\*\*Status:\*\*' "$f" | sed 's/^\*\*Status:\*\*[[:space:]]*//')
  # integrada não é um Status escrito (ciclo.md, "Status dos artefatos"): deriva do git. Task publicada cuja versão
  # na principal (local ou, desatualizada ou ausente, a remota) também está publicada foi integrada — o commit
  # docs(task): … publicada é feito na branch da task e só chega à principal pelo merge.
  case "$s" in
    publicada*)
      for p in "$BRANCH_PRINCIPAL" "origin/$BRANCH_PRINCIPAL"; do
        case "$(git show "$p:$f" 2>/dev/null | grep -m1 '^\*\*Status:\*\*')" in
          "**Status:** publicada"*) s="integrada (derivado do git) — $s"; break ;;
        esac
      done
      ;;
  esac
  [ -n "$s" ] && echo "- $f: $s"
done

echo
modo="desligado"
grep -q '^enabled:[[:space:]]*true' agentic/auto-mode 2>/dev/null && modo="ligado"
echo "Modo automático: $modo"
gate1=$(sed -n 's/^gate1:[[:space:]]*//p' agentic/auto-mode 2>/dev/null | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*$//')
if [ "$modo" = "ligado" ] && [ -n "$gate1" ]; then
  echo "Gate 1: delegado ao orquestrador ($gate1)"
else
  echo "Gate 1: humano"
fi
exit 0
