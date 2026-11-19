#!/bin/sh
# inicio.sh — hook SessionStart do Antigravity: injeta a saída do status-projeto.sh como mensagem de sistema.
d=$(cd "$(dirname "$0")" && pwd)
st="$d/../../agentic/mecanismos/scripts/status-projeto.sh"
if [ -f "$st" ]; then saida=$(cd "$d/../.." && sh "$st" 2>&1); else saida="agentic: status-projeto.sh ausente"; fi
esc=$(printf '%s\n' "$saida" | tr -d '\r' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/ /g' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')
printf '{"injectSteps":[{"systemMessage":{"systemMessage":"%s"}}]}\n' "$esc"
