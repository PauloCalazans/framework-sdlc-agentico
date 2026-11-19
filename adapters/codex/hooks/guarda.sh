#!/bin/sh
# guarda.sh — hook PreToolUse do Codex (Bash e apply_patch). Instalado em .codex/hooks/ pelo ativar-protecoes.sh.
# Bash: nega os prefixos de comandos-negados.txt (também dentro de bash -lc / powershell -Command, onde as regras
# de prefixo do Codex podem não casar) e repassa ao .claude/hooks/pre-tool-use.sh, a única implementação do
# bloqueio de desvio dos githooks. apply_patch: nega patch que toca caminho de caminhos-protegidos.txt.
# Bloqueio = exit 2 com o motivo no stderr. Entrada sem o campo esperado bloqueia: o formato mudou e a falha aparece.
d=$(cd "$(dirname "$0")" && pwd)
if [ ! -f "$d/lib-guarda.sh" ]; then
  echo "agentic: BLOQUEADO — .codex/hooks/lib-guarda.sh ausente; o comando não foi conferido. Avise o humano." >&2
  exit 2
fi
. "$d/lib-guarda.sh"
entrada=$(cat)
ferramenta=$(guarda_texto "$entrada" tool_name)
if ! cmd=$(guarda_texto "$entrada" command); then
  echo "agentic: BLOQUEADO — entrada ilegível no hook do Codex (sem tool_input.command). O formato do Codex pode ter mudado; avise o humano." >&2
  exit 2
fi

case "$ferramenta" in
  apply_patch|Edit|Write)
    printf '%s\n' "$cmd" | tr -d '\r' | sed -nE 's/^\*\*\* (Update File|Add File|Delete File|Move to): *(.*)$/\2/p' | {
      while IFS= read -r c; do
        [ -n "$c" ] || continue
        if guarda_protegido "$c" "$d/caminhos-protegidos.txt"; then
          echo "agentic: BLOQUEADO — $c é arquivo de proteção do kit (agentic/config, mecanismos, hooks, settings). Peça ao humano." >&2
          exit 2
        fi
      done
      exit 0
    }
    exit $?
    ;;
esac

if guarda_negado "$cmd" "$d/comandos-negados.txt"; then
  echo "agentic: BLOQUEADO — comando negado pelo kit (merge, push forçado, reset --hard, ativar-protecoes…). Peça ao humano." >&2
  exit 2
fi
ptu="$d/../../.claude/hooks/pre-tool-use.sh"
if [ ! -f "$ptu" ]; then
  echo "agentic: BLOQUEADO — .claude/hooks/pre-tool-use.sh ausente; o hook do Codex depende dele." >&2
  exit 2
fi
esc=$(printf '%s\n' "$cmd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')
printf '{"tool_input":{"command":"%s"}}' "$esc" | sh "$ptu"
c=$?
# O Codex só bloqueia com 2; outro código de erro deixaria o comando passar sem conferência.
case "$c" in
  0|2) exit "$c" ;;
esac
echo "agentic: BLOQUEADO — .claude/hooks/pre-tool-use.sh falhou (código $c); o comando não foi conferido. Avise o humano." >&2
exit 2
