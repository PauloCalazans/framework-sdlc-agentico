#!/bin/sh
# ativar-protecoes.sh — AÇÃO HUMANA: instala .agentic/settings.pendente.json como .claude/settings.json.
# Permissões do agente pertencem ao humano (princípio 5); por isso o agente não faz este passo.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
[ -f .agentic/settings.pendente.json ] || { echo "Não há .agentic/settings.pendente.json (rode bootstrap/instalar.sh)."; exit 1; }
if [ -f .claude/settings.json ]; then
  echo "Já existe .claude/settings.json — não sobrescrito."
  echo "Faça o merge manual de .agentic/settings.pendente.json (permissions.deny, hooks, enabledPlugins) e rode de novo depois de remover o pendente."
  exit 1
fi
mkdir -p .claude
cp .agentic/settings.pendente.json .claude/settings.json
echo "Proteções ativadas em .claude/settings.json. Reinicie a sessão do Claude Code."
