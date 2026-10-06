#!/bin/sh
# Testes da varredura de segredos do pre-commit. Segredos de teste são montados por concatenação
# para que este arquivo não contenha nenhum segredo literal.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../scripts/testlib.sh"

novo_repo() {
  r=$(tl_repo)
  git -C "$r" config core.hooksPath "$dir"
  git -C "$r" checkout -q -b feat/s
  printf '%s\n' "$r"
}

pw="pass""word"
pat="ghp_""1a2B3c4D5e6F7g8H9i0J1k2L3m4N5o6P7q8R"

r=$(novo_repo)
printf 'token_github = "%s"\n' "$pat" > "$r/a.py"; git -C "$r" add a.py
tl_espera 1 "bloqueia token detectado pelo gitleaks" git -C "$r" commit -q -m "x"

r=$(novo_repo)
printf '%s = "SuperSecreto123"\n' "$pw" > "$r/b.py"; git -C "$r" add b.py
tl_espera 1 "bloqueia senha literal que o gitleaks não pega (palavra-chave)" git -C "$r" commit -q -m "x"
tl_contem "possível segredo" "mensagem cita possível segredo"

r=$(novo_repo)
printf '%s = os.environ["DB_PW"]\n' "$pw" > "$r/c.py"; git -C "$r" add c.py
tl_espera 0 "não bloqueia leitura de variável de ambiente" git -C "$r" commit -q -m "x"

r=$(novo_repo)
printf 'token_count = "abc"\n' > "$r/d.py"; git -C "$r" add d.py
tl_espera 0 "não bloqueia valor curto em nome parecido" git -C "$r" commit -q -m "x"

r=$(novo_repo)
printf '%s = "abcdefgh"  # agentic:permitir-segredo\n' "$pw" > "$r/e.py"; git -C "$r" add e.py
tl_espera 0 "linha marcada como permitida passa" git -C "$r" commit -q -m "x"

r=$(novo_repo)
printf '%s\n' "$pat" > "$r/g.txt"; git -C "$r" add g.txt
tl_espera 1 "bloqueia token nú (sem keyword) — testa camada 1" git -C "$r" commit -q -m "x"

r=$(novo_repo)
mkdir -p "$r/.agentic"; echo 'GITLEAKS_BIN="/nao/existe/gitleaks"' > "$r/.agentic/config"
echo ok > "$r/h.txt"; git -C "$r" add h.txt
tl_espera 1 "fail-closed quando o gitleaks não está instalado" git -C "$r" commit -q -m "x"
tl_contem "gitleaks" "mensagem orienta a instalar o gitleaks"

tl_fim
