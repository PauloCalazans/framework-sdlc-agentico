#!/bin/sh
# Testes do pre-push.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../scripts/testlib.sh"

remoto=$(mktemp -d); git init -q --bare "$remoto"
r=$(tl_repo)
git -C "$r" remote add origin "$remoto"
git -C "$r" push -q origin main            # antes de ligar os hooks: o remoto passa a ter main
git -C "$r" config core.hooksPath "$dir"
git -C "$r" checkout -q -b feat/p
git -C "$r" commit -q --allow-empty --no-verify -m "p1"

tl_espera 0 "permite push de branch de trabalho nova" git -C "$r" push -q origin feat/p
git -C "$r" commit -q --allow-empty --no-verify -m "p2"
tl_espera 0 "permite push fast-forward" git -C "$r" push -q origin feat/p
tl_espera 1 "bloqueia push para main" git -C "$r" push -q origin feat/p:main
tl_contem "agentic: BLOQUEADO" "mensagem de bloqueio padronizada"

git -C "$r" commit -q --amend --allow-empty --no-verify -m "p2-reescrito"
tl_espera 1 "bloqueia force-push (não fast-forward)" git -C "$r" push -q --force origin feat/p
tl_espera 1 "bloqueia exclusão de branch protegida" git -C "$r" push -q origin :main
tl_espera 0 "permite exclusão de branch de trabalho" git -C "$r" push -q origin :feat/p

tl_fim
