#!/bin/sh
# pre-tool-use.sh — hook PreToolUse (Bash) MÍNIMO de propósito: bloqueia varredura de disco a partir
# da raiz, do home ou de um drive, e o desvio dos githooks. Proteções de git vivem nos agentic/mecanismos/githooks
# (valem para qualquer autor); interpretar texto de comando para reproduzi-las é uma corrida que não se ganha.
# O que os githooks não conseguem impedir é ser pulados: o deny do settings casa por prefixo e deixa passar
# "git push origin main --no-verify". Por isso, e só por isso, o hook barra --no-verify (e abreviações) em
# qualquer posição, "git commit -n" e a troca de core.hooksPath por -c.
entrada=$(cat)
if printf '%s' "$entrada" | grep -qE '(^|[;&|[:space:]"])git[[:space:]]' \
  && printf '%s' "$entrada" | grep -qE '(^|[[:space:]"])--no-v[a-z]*([[:space:]"=;&|]|$)|(^|[;&|[:space:]"])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]+[^;&|[:space:]]+)*[[:space:]]+-[A-Za-z]*n[A-Za-z]*([[:space:]";&|]|$)|-c[[:space:]]*core\.hooks[Pp]ath'; then
  echo "agentic: BLOQUEADO — comando git que pula os githooks (--no-verify, commit -n ou -c core.hooksPath). Os githooks são a proteção da branch protegida e dos segredos." >&2
  exit 2
fi
padrao='(^|[;&|[:space:]"])(find|du|tree|ls[[:space:]]+-[A-Za-z]*R[A-Za-z]*|grep[[:space:]]+-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]+[^;&|"[:space:]]+)*[[:space:]]+(/|~|[A-Za-z]:(/|\\\\)?)([[:space:]";&|]|$)'
if printf '%s' "$entrada" | grep -qE "$padrao"; then
  echo "agentic: BLOQUEADO — varredura de disco a partir da raiz/home/drive. Restrinja a busca ao repositório ou a um caminho específico." >&2
  exit 2
fi
exit 0
