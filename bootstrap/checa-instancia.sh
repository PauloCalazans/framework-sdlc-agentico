#!/bin/sh
# checa-instancia.sh <projeto> — checagem estrutural de uma instância do framework após o /bootstrap.
. "$(cd "$(dirname "$0")" && pwd)/lib-kit.sh"
alvo=${1:-}
[ -n "$alvo" ] && [ -d "$alvo" ] || { echo "uso: checa-instancia.sh <projeto>" >&2; exit 2; }
cd "$alvo" || exit 2
problemas=0
problema() { echo "PROBLEMA: $*"; problemas=$((problemas + 1)); }
aviso() { echo "AVISO: $*"; }

for f in AGENTS.md CLAUDE.md agentic/processo/ciclo.md agentic/processo/principios.md agentic/projeto/bootstrap.md agentic/projeto/decisoes.md \
         agentic/config agentic/auto-mode .claude/settings.json agentic/mecanismos/scripts/verify.sh agentic/mecanismos/githooks/pre-commit; do
  [ -f "$f" ] || problema "arquivo obrigatório ausente: $f (se for .claude/settings.json: rode sh agentic/mecanismos/scripts/ativar-protecoes.sh)"
done

for p in dominio arquiteto testes dev revisor; do
  [ -f "agentic/processo/papeis/$p.md" ] && [ -f ".claude/agents/$p.md" ] || problema "papel incompleto: $p"
done

for p in dominio arquiteto testes dev revisor; do
  [ -f "agentic/projeto/papeis/$p.md" ] || problema "perfil ausente: agentic/projeto/papeis/$p.md (copie agentic/processo/templates/perfil-papel.md e preencha)"
done

restantes=$(grep -rl '{{' AGENTS.md CLAUDE.md agentic/processo/papeis agentic/projeto/papeis .claude/agents agentic/config agentic/projeto/bootstrap.md agentic/projeto/decisoes.md 2>/dev/null \
  | grep -v 'papeis/_oraculo.md$') # o contrato-base do oráculo é template; o agente-template fica em agentic/processo/templates
[ -z "$restantes" ] || problema "placeholders {{...}} não preenchidos em: $(echo $restantes)"

# Caminhos citados nos perfis existem. Critério: trecho entre crases, sem espaço, que contém "/" ou termina
# em extensão minúscula (.md, .json, .properties); um sufixo :linha é ignorado. Ficam de fora globs (*),
# placeholders (<...>, {...}, $VAR), URLs (://) e nomes iniciados por @ ou -.
citados=$(mktemp) || { echo "PROBLEMA: mktemp falhou"; exit 1; }
for f in agentic/projeto/papeis/*.md; do
  [ -f "$f" ] || continue
  grep -o '`[^`]*`' "$f" | tr -d '`' | while IFS= read -r c; do
    case "$c" in *[[:space:]]*|*'*'*|*'<'*|*'>'*|*'{'*|*'$'*|*://*|@*|-*|'') continue ;; esac
    c=$(printf '%s\n' "$c" | sed 's/:[0-9][0-9-]*$//')
    case "$c" in */*) ;; *) printf '%s\n' "$c" | grep -q '\.[a-z0-9]\{1,10\}$' || continue ;; esac
    [ -e "$c" ] || printf '%s cita %s, que não existe\n' "$f" "$c"
  done
done > "$citados"
while IFS= read -r l; do problema "$l"; done < "$citados"
rm -f "$citados"

# Contrato do kit editado na instância: compara com o hash gravado pelo instalar.sh.
if [ -f agentic/processo/.kit-manifesto ]; then
  for p in dominio arquiteto testes dev revisor; do
    c=agentic/processo/papeis/$p.md
    [ -f "$c" ] || continue
    h=$(kit_hash_manifesto agentic/processo/.kit-manifesto "$c")
    if [ -z "$h" ]; then
      aviso "$c fora do manifesto; não deu para conferir se foi editado"
    elif [ "$h" != "$(kit_hash "$c")" ]; then
      problema "contrato editado na instância: mova a personalização para agentic/projeto/papeis/$p.md e restaure $c do kit"
    fi
  done
else
  aviso "sem agentic/processo/.kit-manifesto (instância anterior ao manifesto); contratos não conferidos. Reinstale o kit para gravá-lo."
fi

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
