#!/bin/sh
# Testes de pre-commit (proteção de branch) e pre-merge-commit.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../scripts/testlib.sh"

novo_repo() {
  r=$(tl_repo)
  git -C "$r" config core.hooksPath "$dir"
  printf '%s\n' "$r"
}

# --- proteção de branch no commit
r=$(novo_repo)
echo a > "$r/a.txt"; git -C "$r" add a.txt
tl_espera 1 "bloqueia commit direto em main" git -C "$r" commit -q -m "x"
tl_contem "agentic: BLOQUEADO" "mensagem de bloqueio padronizada"

git -C "$r" checkout -q -b feat/x
tl_espera 0 "permite commit em branch de trabalho" git -C "$r" commit -q -m "x"

# --- branches protegidas vêm do .agentic/config
r=$(novo_repo)
mkdir -p "$r/.agentic"; echo 'BRANCHES_PROTEGIDAS="develop"' > "$r/.agentic/config"
git -C "$r" checkout -q -b develop
echo a > "$r/a.txt"; git -C "$r" add a.txt
tl_espera 1 "bloqueia branch protegida declarada no config" git -C "$r" commit -q -m "x"
git -C "$r" checkout -q main
tl_espera 0 "main deixa de ser protegida quando o config redefine a lista" git -C "$r" commit -q -m "x"

# --- merge local em branch protegida
r=$(novo_repo)
git -C "$r" checkout -q -b feat/y
echo y > "$r/y.txt"; git -C "$r" add y.txt; git -C "$r" commit -q -m "y"
git -C "$r" checkout -q main
git -C "$r" commit -q --allow-empty --no-verify -m "diverge"
tl_espera 1 "bloqueia merge local em main" git -C "$r" merge -q --no-ff --no-edit feat/y
git -C "$r" merge --abort 2>/dev/null

tl_fim
