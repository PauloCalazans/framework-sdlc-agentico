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
mkdir -p "$r/agentic/.estado"; echo 'GITLEAKS_BIN="/nao/existe/gitleaks"' > "$r/agentic/config"
echo ok > "$r/h.txt"; git -C "$r" add h.txt
tl_espera 1 "fail-closed quando o gitleaks não está instalado" git -C "$r" commit -q -m "x"
tl_contem "gitleaks" "mensagem orienta a instalar o gitleaks"

# Camada 2 fail-closed: se 'git diff --cached' falhar (índice corrompido), bloqueia.
r=$(novo_repo)
mkdir -p "$r/agentic/.estado"; echo 'GITLEAKS_BIN="true"' > "$r/agentic/config"
echo lixo > "$r/indice-corrompido"
tl_espera 1 "bloqueia quando git diff --cached falha" \
  sh -c "cd '$r' && GIT_INDEX_FILE='$r/indice-corrompido' sh '$dir/pre-commit'"
tl_contem "git diff --cached falhou" "explica a falha da camada 2"
tl_espera 0 "camada 2 com índice válido e sem achados passa (controle)" sh -c "cd '$r' && sh '$dir/pre-commit'"

# --- Camada 2: casos medidos no projeto de referência (valor sem aspas, chave hifenizada, placeholders).
# commita_caso <esperado> <descricao> <arquivo> <linha>: grava a linha num repositório novo e tenta o commit.
commita_caso() {
  cc_r=$(novo_repo)
  printf '%s\n' "$4" > "$cc_r/$3"; git -C "$cc_r" add -- "$3"
  tl_espera "$1" "$2" git -C "$cc_r" commit -q -m "x"
}
PW="PASS""WORD"
sec="sec""ret"
lit="Super""Secreto123"

commita_caso 1 "bloqueia YAML sem aspas ($pw: <literal>)" application.yml "$pw: $lit"
tl_contem "possível segredo" "YAML sem aspas: bloqueado pela camada 2"
commita_caso 1 "bloqueia env/sh sem aspas (PG$PW=<literal>)" run.sh "PG$PW=hunter2""hunter2"
tl_contem "possível segredo" "env/sh: bloqueado pela camada 2"
commita_caso 1 "bloqueia properties (spring.datasource.$pw=<literal>)" application.properties "spring.datasource.$pw=$lit"
tl_contem "possível segredo" "properties: bloqueado pela camada 2"
commita_caso 1 "bloqueia atribuição com aspas ($pw = \"<literal>\")" b.py "$pw = \"$lit\""
tl_contem "possível segredo" "aspas: bloqueado pela camada 2"
commita_caso 1 "bloqueia JSON (\"$pw\": \"<literal>\")" config.json "{\"$pw\": \"$lit\"}"
tl_contem "possível segredo" "JSON: bloqueado pela camada 2"
commita_caso 0 "permite referência a variável entre aspas (SPRING_DATASOURCE_$PW: \"\${DB_$PW}\")" docker-compose.yml "SPRING_DATASOURCE_$PW: \"\${DB_$PW}\""
commita_caso 0 "permite referência a variável sem aspas ($pw: \${DB_$PW})" application.yml "$pw: \${DB_$PW}"
commita_caso 0 "permite referência com default vazio ($pw: \${DB_$PW:-})" application.yml "$pw: \${DB_$PW:-}"
commita_caso 1 "bloqueia default literal embutido ($pw: \"\${DB_$PW:<literal>}\")" application.yml "$pw: \"\${DB_$PW:Fake""Value123}\""
tl_contem "possível segredo" "default literal: bloqueado pela camada 2"
commita_caso 1 "bloqueia default literal estilo shell ($pw=\${DB_$PW:-<literal>})" run.sh "$pw=\${DB_$PW:-Fake""Value123}"
commita_caso 0 "permite placeholder changeme" application.yml "$pw: change""me"
commita_caso 0 "permite placeholder <senha>" application.yml "$pw: <senha>"
commita_caso 0 "permite placeholder {{SENHA}}" application.yml "$pw: {{SENHA}}"
commita_caso 0 "permite valor vazio (\"\")" application.yml "$pw: \"\""
commita_caso 0 "permite placeholder placeholder/example/xxx/secret" application.yml "$(printf '%s: %s\n' "$pw" placeholder api_key example token xxxxxxxx "$pw" "$sec")"
commita_caso 0 "permite placeholder %SENHA%" application.yml "$pw: %SENHA%"
commita_caso 0 "permite \${{ secrets.X }} do CI sem aspas internas" ci.yml "  DB_$PW: \${{ ${sec}s.DB_$PW }}"
commita_caso 1 "bloqueia \${{ }} com literal entre aspas internas" ci.yml "  DB_$PW: \${{ 'Super''Secreto123' }}"
commita_caso 0 "permite substituição de comando no shell" run.sh "PG$PW=\"\$(cat /run/${sec}s/db)\""
commita_caso 1 "bloqueia chave hifenizada (jwt-$sec-key: <literal>)" application.yml "jwt-$sec-key: abcdefghij"
tl_contem "possível segredo" "chave hifenizada: bloqueada pela camada 2"
commita_caso 0 "permite literal sem aspas curto (< 8)" application.yml "$pw: abc1234"
commita_caso 0 "valor sem aspas em código é expressão, não literal" Servico.kt "class S(private val ${pw}Encoder: ${PW}Encoder)"
commita_caso 0 "linha marcada como permitida passa (sem aspas)" application.yml "$pw: $lit  # agentic:permitir-segredo"

tl_fim
