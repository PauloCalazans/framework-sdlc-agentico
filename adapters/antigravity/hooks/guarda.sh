#!/bin/sh
# guarda.sh — hook PreToolUse do Antigravity (run_command e ferramentas de escrita). Instalado em .agents/hooks/
# pelo ativar-protecoes.sh. O Antigravity não tem lista de bloqueio no repositório; este hook faz esse papel.
# run_command: nega os prefixos de comandos-negados.txt e repassa ao .claude/hooks/pre-tool-use.sh (desvio dos
# githooks, varredura de disco). Escrita: nega TargetFile de caminhos-protegidos.txt.
# Responde sempre com um objeto JSON no stdout ({"decision":"allow"|"deny","reason":…}) e sai com 0.
# Entrada sem o campo esperado nega: o formato mudou e a falha aparece.
d=$(cd "$(dirname "$0")" && pwd)
. "$d/lib-guarda.sh"

# responde <allow|deny> [motivo]
responde() {
  if [ -n "${2:-}" ]; then
    m=$(printf '%s' "$2" | tr '\r\n' '  ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    printf '{"decision":"%s","reason":"%s"}\n' "$1" "$m"
  else
    printf '{"decision":"%s"}\n' "$1"
  fi
  exit 0
}

entrada=$(cat)
ferramenta=$(printf '%s' "$entrada" | tr -d '\r\n' \
  | grep -oE '"name"[[:space:]]*:[[:space:]]*"(run_command|write_to_file|replace_file_content|multi_replace_file_content)"' \
  | head -n 1 | sed -E 's/.*"([a-z_]+)"$/\1/')

case "$ferramenta" in
  run_command)
    cmd=$(guarda_texto "$entrada" CommandLine) \
      || responde deny "agentic: entrada ilegível no hook do Antigravity (sem toolCall.args.CommandLine). O formato pode ter mudado; avise o humano."
    if guarda_negado "$cmd" "$d/comandos-negados.txt" 2>/dev/null; then
      responde deny "agentic: BLOQUEADO — comando negado pelo kit (merge, push forçado, reset --hard, ativar-protecoes…). Peça ao humano."
    fi
    ptu="$d/../../.claude/hooks/pre-tool-use.sh"
    [ -f "$ptu" ] || responde deny "agentic: BLOQUEADO — .claude/hooks/pre-tool-use.sh ausente; o hook do Antigravity depende dele."
    esc=$(printf '%s\n' "$cmd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')
    motivo=$(printf '{"tool_input":{"command":"%s"}}' "$esc" | sh "$ptu" 2>&1 >/dev/null)
    [ $? -eq 2 ] && responde deny "$motivo"
    responde allow
    ;;
  write_to_file|replace_file_content|multi_replace_file_content)
    alvo=$(guarda_texto "$entrada" TargetFile) \
      || responde deny "agentic: entrada ilegível no hook do Antigravity (sem toolCall.args.TargetFile). O formato pode ter mudado; avise o humano."
    if guarda_protegido "$alvo" "$d/caminhos-protegidos.txt" 2>/dev/null; then
      responde deny "agentic: BLOQUEADO — $alvo é arquivo de proteção do kit (agentic/config, mecanismos, hooks, settings). Peça ao humano."
    fi
    responde allow
    ;;
  *)
    responde deny "agentic: entrada ilegível no hook do Antigravity (ferramenta não reconhecida em toolCall.name). Avise o humano."
    ;;
esac
