#!/bin/sh
# checa-instancia.sh <projeto> — checagem estrutural de uma instância do framework após o /bootstrap.
alvo=${1:-}
[ -n "$alvo" ] && [ -d "$alvo" ] || { echo "uso: checa-instancia.sh <projeto>" >&2; exit 2; }
cd "$alvo" || exit 2
problemas=0
problema() { echo "PROBLEMA: $*"; problemas=$((problemas + 1)); }

for f in AGENTS.md CLAUDE.md agentic/processo/ciclo.md agentic/processo/principios.md agentic/projeto/bootstrap.md agentic/projeto/decisoes.md \
         agentic/config agentic/auto-mode .claude/settings.json agentic/mecanismos/scripts/verify.sh agentic/mecanismos/githooks/pre-commit; do
  [ -f "$f" ] || problema "arquivo obrigatório ausente: $f (se for .claude/settings.json: rode sh agentic/mecanismos/scripts/ativar-protecoes.sh)"
done

for p in dominio arquiteto testes dev revisor; do
  [ -f "agentic/processo/papeis/$p.md" ] && [ -f ".claude/agents/$p.md" ] || problema "papel incompleto: $p"
done

restantes=$(grep -rl '{{' AGENTS.md CLAUDE.md agentic/processo/papeis .claude/agents agentic/config agentic/projeto/bootstrap.md agentic/projeto/decisoes.md 2>/dev/null \
  | grep -v 'papeis/_oraculo.md$') # o contrato-base do oráculo é template; o agente-template fica em agentic/processo/templates
[ -z "$restantes" ] || problema "placeholders {{...}} não preenchidos em: $(echo $restantes)"

[ "$(git config core.hooksPath)" = "agentic/mecanismos/githooks" ] || problema "core.hooksPath não aponta para agentic/mecanismos/githooks"

# O settings.json precisa ser versionado: senão some em clones/worktrees e as proteções não valem lá.
if [ -f .claude/settings.json ]; then
  git ls-files --error-unmatch .claude/settings.json >/dev/null 2>&1 || \
    problema ".claude/settings.json não rastreado pelo git; commite (ação humana): git add .claude/settings.json && git commit -m 'chore: ativa proteções do agente'"
fi

# Hooks precisam estar no índice como executáveis (100755); senão, num clone Unix, o git os ignora em silêncio.
for h in agentic/mecanismos/githooks/pre-commit agentic/mecanismos/githooks/pre-merge-commit agentic/mecanismos/githooks/pre-push; do
  modo=$(git ls-files -s -- "$h" 2>/dev/null | cut -d' ' -f1)
  [ "$modo" = "100755" ] || problema "hook $h não está no índice como 100755 (modo: ${modo:-ausente}); rode: git add --chmod=+x $h"
done

if [ -f agentic/config ]; then
  ( . ./agentic/config; [ -n "$CMD_VERIFY_STACK" ] && [ -n "$CMD_TESTE" ] ) || problema "CMD_VERIFY_STACK/CMD_TESTE vazios em agentic/config"
fi

if [ "$problemas" -eq 0 ]; then
  saida_verify=$(mktemp) || { echo "PROBLEMA: mktemp falhou"; exit 1; }
  if sh agentic/mecanismos/scripts/verify.sh >"$saida_verify" 2>&1; then
    echo "verify.sh: OK"
  else
    problema "verify.sh falhou (saída abaixo)"
    sed 's/^/  | /' "$saida_verify"
  fi
  rm -f "$saida_verify"
fi

if [ "$problemas" -eq 0 ]; then echo "INSTÂNCIA: OK"; else echo "INSTÂNCIA: $problemas problema(s)"; exit 1; fi
