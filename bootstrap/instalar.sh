#!/bin/sh
# instalar.sh <projeto-alvo> [--copilot] [--codex] [--antigravity] — copia o kit do framework para o projeto.
# --copilot acrescenta o adaptador do GitHub Copilot em .github/ (instruções, agentes, prompts, setup do agente de nuvem).
# --codex e --antigravity acrescentam os agentes (.codex/agents, .agents/agents) e as skills (.agents/skills); hooks e
# regras ficam pendentes em agentic/.estado/protecoes-pendentes até o ativar-protecoes.sh (ação humana).
# Reinstalar sem opção mantém os adaptadores que o manifesto anterior registra.
# Não pergunta nada e não sobrescreve edição da instância: conflitos vão para agentic/.estado/conflitos-instalacao.txt
# e são resolvidos no /bootstrap. Arquivo do kit intacto desde a instalação anterior (hash igual ao do
# manifesto agentic/processo/.kit-manifesto) recebe a versão nova sem merge.
# Os perfis em agentic/projeto/papeis/ são da instância: criados do template só se ausentes, nunca sobrescritos.
fw=$(cd "$(dirname "$0")/.." && pwd)
. "$fw/bootstrap/lib-kit.sh"
uso="uso: instalar.sh <projeto-alvo> [--copilot] [--codex] [--antigravity]"
alvo=${1:-}
copilot=""
codex=""
antigravity=""
[ $# -gt 0 ] && shift
for o in "$@"; do
  case "$o" in
    --copilot) copilot=1 ;;
    --codex) codex=1 ;;
    --antigravity) antigravity=1 ;;
    *) echo "$uso" >&2; exit 2 ;;
  esac
done
{ [ -n "$alvo" ] && [ -d "$alvo" ]; } || { echo "$uso" >&2; exit 2; }
git -C "$alvo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "o alvo não é um repositório git: $alvo" >&2; exit 2; }
alvo=$(cd "$alvo" && pwd)
rm -f "$alvo/agentic/.estado/conflitos-instalacao.txt" # o arquivo reflete só a execução atual
rm -rf "$alvo/agentic/.estado/kit-conflitos"
conflitos=$(mktemp)
atualizados=$(mktemp)
manifesto=agentic/processo/.kit-manifesto
manifesto_novo=$(mktemp)

# Reinstalação lembra os adaptadores: o manifesto anterior diz quais foram instalados (sem estado novo).
lembra() { # lembra <nome> <prefixo no manifesto>
  grep -q "  $2" "$alvo/$manifesto" 2>/dev/null || return 1
  echo "Reinstalação: mantendo o adaptador $1 (instalado antes, conforme $manifesto)."
}
[ -z "$copilot" ] && lembra copilot '\.github/agents/' && copilot=1
[ -z "$codex" ] && lembra codex '\.codex/agents/' && codex=1
[ -z "$antigravity" ] && lembra antigravity '\.agents/agents/' && antigravity=1

guarda_kit() { # guarda_kit <origem> <caminho relativo> — versão do kit para o /bootstrap comparar
  mkdir -p "$(dirname "$alvo/agentic/.estado/kit-conflitos/$2")"
  cp "$1" "$alvo/agentic/.estado/kit-conflitos/$2"
}
copia() { # copia <origem> <destino relativo ao alvo>
  case "$2" in agentic/.estado/*) ;; *) printf '%s  %s\n' "$(kit_hash "$1")" "$2" >> "$manifesto_novo" ;; esac
  if [ -e "$alvo/$2" ]; then
    cmp -s "$1" "$alvo/$2" && return 0
    anterior=$(kit_hash_manifesto "$alvo/$manifesto" "$2")
    if [ -n "$anterior" ] && [ "$anterior" = "$(kit_hash "$alvo/$2")" ]; then
      cp "$1" "$alvo/$2" # intacto desde a instalação anterior: atualiza sem merge
      printf '%s\n' "$2" >> "$atualizados"
    else
      printf '%s\n' "$2" >> "$conflitos"
      guarda_kit "$1" "$2"
    fi
    return 0
  fi
  mkdir -p "$(dirname "$alvo/$2")"
  cp "$1" "$alvo/$2"
}
copia_dir() { # copia_dir <diretório origem> <diretório destino relativo>
  # As suítes *.Tests.sh e o testlib.sh são do framework: não vão para a instância.
  ( cd "$1" && find . -type f ! -name '*.Tests.sh' ! -name 'testlib.sh' | sed 's|^\./||' ) | while IFS= read -r f; do
    copia "$1/$f" "$2/$f"
  done
}
acrescenta() { # acrescenta <arquivo relativo> <linha> — sem duplicar
  grep -qxF "$2" "$alvo/$1" 2>/dev/null && return 0
  # arquivo existente sem quebra de linha final: fecha a última linha antes de acrescentar
  if [ -s "$alvo/$1" ] && [ -n "$(tail -c 1 "$alvo/$1" | tr -d '\n')" ]; then
    printf '\n' >> "$alvo/$1"
  fi
  printf '%s\n' "$2" >> "$alvo/$1"
}

copia "$fw/core/principios.md" agentic/processo/principios.md
copia "$fw/core/processo/ciclo.md" agentic/processo/ciclo.md
copia "$fw/core/processo/modelos.md" agentic/processo/modelos.md
copia_dir "$fw/core/papeis" agentic/processo/papeis
copia_dir "$fw/core/templates" agentic/processo/templates
copia "$fw/core/templates/AGENTS.md" AGENTS.md
copia "$fw/bootstrap/entrevista.md" agentic/processo/entrevista.md
copia_dir "$fw/mecanismos/githooks" agentic/mecanismos/githooks
copia_dir "$fw/mecanismos/scripts" agentic/mecanismos/scripts
copia_dir "$fw/adapters/claude-code/agents" .claude/agents
copia_dir "$fw/adapters/claude-code/commands" .claude/commands
copia_dir "$fw/adapters/claude-code/hooks" .claude/hooks
copia "$fw/adapters/claude-code/CLAUDE.md" CLAUDE.md
copia "$fw/adapters/claude-code/agente-oraculo.tmpl.md" agentic/processo/templates/agente-oraculo.md
copia "$fw/adapters/claude-code/settings.json.tmpl" agentic/.estado/settings.pendente.json
copia "$fw/bootstrap/config.padrao" agentic/config
copia "$fw/bootstrap/auto-mode.padrao" agentic/auto-mode
if [ -n "$copilot" ]; then
  copia "$fw/adapters/copilot/copilot-instructions.md" .github/copilot-instructions.md
  copia_dir "$fw/adapters/copilot/agents" .github/agents
  copia_dir "$fw/adapters/copilot/prompts" .github/prompts
  copia "$fw/adapters/copilot/copilot-setup-steps.yml" .github/workflows/copilot-setup-steps.yml
  copia "$fw/adapters/copilot/agente-oraculo.tmpl.md" agentic/processo/templates/agente-oraculo-copilot.md
fi
# Proteções (hooks, regras, listas) do Codex e do Antigravity ficam pendentes: quem as instala é o humano,
# pelo ativar-protecoes.sh. São cópia do kit, fora do manifesto, e sempre atualizadas.
pendentes=agentic/.estado/protecoes-pendentes
pendente() { # pendente <origem> <caminho final relativo ao alvo>
  mkdir -p "$(dirname "$alvo/$pendentes/$2")"
  cp "$1" "$alvo/$pendentes/$2"
}
if [ -n "$codex" ] || [ -n "$antigravity" ]; then
  copia_dir "$fw/adapters/agents-skills" .agents/skills
fi
if [ -n "$codex" ]; then
  copia_dir "$fw/adapters/codex/agents" .codex/agents
  copia "$fw/adapters/codex/agente-oraculo.tmpl.toml" agentic/processo/templates/agente-oraculo-codex.toml
  pendente "$fw/adapters/codex/hooks.json" .codex/hooks.json
  pendente "$fw/adapters/codex/rules/agentic.rules" .codex/rules/agentic.rules
  pendente "$fw/adapters/codex/hooks/guarda.sh" .codex/hooks/guarda.sh
  for f in lib-guarda.sh caminhos-protegidos.txt comandos-negados.txt; do
    pendente "$fw/adapters/comum/$f" ".codex/hooks/$f"
  done
fi
if [ -n "$antigravity" ]; then
  copia_dir "$fw/adapters/antigravity/agents" .agents/agents
  copia "$fw/adapters/antigravity/agente-oraculo.tmpl.md" agentic/processo/templates/agente-oraculo-antigravity.md
  pendente "$fw/adapters/antigravity/hooks.json" .agents/hooks.json
  for f in guarda.sh inicio.sh; do
    pendente "$fw/adapters/antigravity/hooks/$f" ".agents/hooks/$f"
  done
  for f in lib-guarda.sh caminhos-protegidos.txt comandos-negados.txt; do
    pendente "$fw/adapters/comum/$f" ".agents/hooks/$f"
  done
fi

for p in dominio arquiteto testes dev revisor; do
  [ -e "$alvo/agentic/projeto/papeis/$p.md" ] && continue
  mkdir -p "$alvo/agentic/projeto/papeis"
  sed "s/{{PAPEL}}/$p/g" "$fw/core/templates/perfil-papel.md" > "$alvo/agentic/projeto/papeis/$p.md"
done
LC_ALL=C sort "$manifesto_novo" > "$alvo/$manifesto"
rm -f "$manifesto_novo"

acrescenta .gitignore "agentic/.estado/"
acrescenta .gitattributes "*.sh text eol=lf"
acrescenta .gitattributes "agentic/mecanismos/githooks/* text eol=lf"

# settings.json existente não é copiado, mas o ativar-protecoes.sh depende da ausência dele
if [ -e "$alvo/.claude/settings.json" ]; then
  printf '%s\n' ".claude/settings.json" >> "$conflitos"
  guarda_kit "$fw/adapters/claude-code/settings.json.tmpl" ".claude/settings.json"
fi

git -C "$alvo" config core.hooksPath agentic/mecanismos/githooks

if [ -s "$conflitos" ]; then
  cp "$conflitos" "$alvo/agentic/.estado/conflitos-instalacao.txt"
  echo "Arquivos já existentes e diferentes (NÃO sobrescritos) — listados em agentic/.estado/conflitos-instalacao.txt:"
  sed 's/^/  /' "$conflitos"
fi
if [ -s "$atualizados" ]; then
  echo "Arquivos do kit atualizados (intactos desde a instalação anterior, conforme $manifesto):"
  sed 's/^/  /' "$atualizados"
fi
rm -f "$conflitos" "$atualizados"
echo "Kit instalado em $alvo."
echo "Próximo passo: abra o Claude Code (ou o Antigravity) no projeto e rode /bootstrap; no Codex, \$bootstrap."
if [ -n "$codex" ] || [ -n "$antigravity" ]; then
  echo "Proteções do Codex/Antigravity pendentes em $pendentes: ative-as com sh agentic/mecanismos/scripts/ativar-protecoes.sh (ação humana)."
fi
