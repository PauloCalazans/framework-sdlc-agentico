#!/bin/sh
# instalar.sh <projeto-alvo> — copia o kit do framework para o projeto.
# Não pergunta nada e não sobrescreve nada: conflitos vão para agentic/.estado/conflitos-instalacao.txt
# e são resolvidos no /bootstrap.
fw=$(cd "$(dirname "$0")/.." && pwd)
alvo=${1:-}
{ [ -n "$alvo" ] && [ -d "$alvo" ]; } || { echo "uso: instalar.sh <projeto-alvo>" >&2; exit 2; }
git -C "$alvo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "o alvo não é um repositório git: $alvo" >&2; exit 2; }
alvo=$(cd "$alvo" && pwd)
rm -f "$alvo/agentic/.estado/conflitos-instalacao.txt" # o arquivo reflete só a execução atual
rm -rf "$alvo/agentic/.estado/kit-conflitos"
conflitos=$(mktemp)

guarda_kit() { # guarda_kit <origem> <caminho relativo> — versão do kit para o /bootstrap comparar
  mkdir -p "$(dirname "$alvo/agentic/.estado/kit-conflitos/$2")"
  cp "$1" "$alvo/agentic/.estado/kit-conflitos/$2"
}
copia() { # copia <origem> <destino relativo ao alvo>
  if [ -e "$alvo/$2" ]; then
    if ! cmp -s "$1" "$alvo/$2"; then
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
rm -f "$conflitos"
echo "Kit instalado em $alvo."
echo "Próximo passo: abra o Claude Code no projeto e rode /bootstrap."
