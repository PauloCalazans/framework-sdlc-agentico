#!/bin/sh
# pre-tool-use.sh — hook PreToolUse (Bash) MÍNIMO de propósito: bloqueia varredura de disco a partir
# da raiz, do home ou de um drive, e o desvio dos githooks. Proteções de git vivem nos agentic/mecanismos/githooks
# (valem para qualquer autor); interpretar texto de comando para reproduzi-las é uma corrida que não se ganha.
# O que os githooks não conseguem impedir é ser pulados: o deny do settings casa por prefixo e deixa passar
# "git push origin main --no-verify". Por isso, e só por isso, o hook barra num comando git: --no-verify (e as
# abreviações que o git aceita), a opção -n do commit, e qualquer menção a core.hooksPath, --config-env ou
# GIT_CONFIG_ (troca da pasta de hooks). Olha só o campo "command", sem trechos entre aspas e sem corpo de
# heredoc nas opções; core.hooksPath é procurado no comando inteiro. Limite declarado: comando montado em tempo de execução escapa.
entrada=$(cat)
bruto=$(printf '%s' "$entrada" | sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | head -n 1 \
  | awk '{ gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }')
# Para opções: sem corpo de heredoc e sem trechos entre aspas (mensagem de commit não é opção).
cmd=$(printf '%s\n' "$bruto" | awk 'h { next } /<</ { sub(/<<.*/, ""); h = 1 } { print }' | sed "s/\"[^\"]*\"//g; s/'[^']*'//g")
if printf '%s' "$bruto" | grep -qE '(^|[;&|(`[:space:]])git([[:space:]]|$)'; then
  if printf '%s' "$bruto" | grep -qiE 'core\.hookspath|--config-env|GIT_CONFIG_' \
    || printf '%s' "$cmd" | grep -qiE '(^|[[:space:]])--no-v(e(r(i(f(y)?)?)?)?)?([[:space:]=;&|)]|$)' \
    || printf '%s' "$cmd" | grep -qE '(^|[;&|(`[:space:]])git([[:space:]]+[^;&|[:space:]]+)*[[:space:]]+commit([[:space:]]+[^;&|[:space:]]+)*[[:space:]]+-[A-Za-z]*n[A-Za-z]*([[:space:];&|)]|$)'; then
    echo "agentic: BLOQUEADO — comando git que pula ou troca os githooks (--no-verify, commit -n, core.hooksPath, --config-env, GIT_CONFIG_). Os githooks são a proteção da branch protegida e dos segredos." >&2
    exit 2
  fi
fi
padrao='(^|[;&|[:space:]"])(find|du|tree|ls[[:space:]]+-[A-Za-z]*R[A-Za-z]*|grep[[:space:]]+-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]+[^;&|"[:space:]]+)*[[:space:]]+(/|~|[A-Za-z]:(/|\\\\)?)([[:space:]";&|]|$)'
if printf '%s' "$entrada" | grep -qE "$padrao"; then
  echo "agentic: BLOQUEADO — varredura de disco a partir da raiz/home/drive. Restrinja a busca ao repositório ou a um caminho específico." >&2
  exit 2
fi
exit 0
