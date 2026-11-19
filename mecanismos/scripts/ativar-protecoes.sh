#!/bin/sh
# ativar-protecoes.sh — AÇÃO HUMANA: instala agentic/.estado/settings.pendente.json como .claude/settings.json e
# as proteções pendentes do Codex e do Antigravity (agentic/.estado/protecoes-pendentes/<caminho final>).
# Permissões do agente pertencem ao humano (princípio 5); por isso o agente não faz este passo.
# Nunca sobrescreve: arquivo existente e diferente é listado para merge manual, e o script sai com 1.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
pend=agentic/.estado/protecoes-pendentes
falhou=0
instalados=""
if [ ! -f agentic/.estado/settings.pendente.json ] && [ ! -d "$pend" ]; then
  echo "Não há agentic/.estado/settings.pendente.json nem $pend (rode bootstrap/instalar.sh)."
  exit 1
fi

if [ -f agentic/.estado/settings.pendente.json ]; then
  if [ -f .claude/settings.json ]; then
    if ! cmp -s agentic/.estado/settings.pendente.json .claude/settings.json; then
      echo "Já existe .claude/settings.json — não sobrescrito."
      echo "Faça o merge manual de agentic/.estado/settings.pendente.json (permissions.deny, hooks, enabledPlugins) em .claude/settings.json, commite o resultado e apague o pendente; não é preciso rodar este script de novo."
      falhou=1
    fi
  else
    mkdir -p .claude
    cp agentic/.estado/settings.pendente.json .claude/settings.json
    echo "Proteções ativadas em .claude/settings.json."
    instalados=".claude/settings.json"
  fi
fi

if [ -d "$pend" ]; then
  # .kit-manifesto é do instalar.sh (hash de cada pendente), não uma proteção
  lista=$(cd "$pend" && find . -type f ! -path ./.kit-manifesto | sed 's|^\./||' | LC_ALL=C sort)
  diferentes=""
  for f in $lista; do
    if [ -f "$f" ]; then
      cmp -s "$pend/$f" "$f" || diferentes="$diferentes $f"
    else
      mkdir -p "$(dirname "$f")"
      cp "$pend/$f" "$f"
      instalados="$instalados $f"
    fi
  done
  if [ -n "$diferentes" ]; then
    echo "Proteções já existentes e diferentes (NÃO sobrescritas) — faça o merge manual a partir de $pend/:"
    for f in $diferentes; do echo "  $f"; done
    falhou=1
  fi
fi

if [ -n "$instalados" ]; then
  echo "Commite agora (ação humana): git add$(printf ' %s' $instalados) && git commit -m 'chore: ativa proteções do agente'"
  echo "Depois integre a branch, reinicie a sessão e abra o Claude Code interativamente neste projeto uma vez, aceitando o diálogo de confiança do workspace (sem isso as regras permissions.allow são ignoradas e o modo auto trava em prompts)."
fi
if [ -f .codex/hooks.json ]; then
  echo "No Codex: marque o projeto como confiável e aprove os hooks em /hooks; sem isso nenhum bloqueio do Codex vale."
fi
exit "$falhou"
