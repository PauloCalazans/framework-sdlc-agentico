#!/bin/sh
# Testes do checa-instancia.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

r=$(tl_repo)
sh "$dir/instalar.sh" "$r" >/dev/null
tl_espera 1 "instalação crua não passa (placeholders e settings inativos)" sh "$dir/checa-instancia.sh" "$r"
tl_contem "{{" "aponta placeholders restantes"
tl_contem "settings.json" "aponta settings não ativado"

# Simula um bootstrap completo: preenche placeholders, configura comandos e ativa as proteções.
find "$r/AGENTS.md" "$r/docs/agentic/papeis" "$r/.claude/agents" -type f ! -name '_oraculo.md' \
  -exec sed -i 's/{{[A-Z0-9_]*}}/preenchido/g' {} +
cat > "$r/.agentic/config" <<'EOF'
BRANCH_PRINCIPAL="main"
BRANCHES_PROTEGIDAS="main master"
CMD_VERIFY_STACK="true"
CMD_TESTE="true"
CMD_PREPARAR_TESTE=""
DIRS_TESTE="tests/"
MARCADOR_DESABILITADO=""
MARCADOR_ASSERCAO="assert"
RELATORIO_TESTES=""
GITLEAKS_BIN="gitleaks"
EOF
printf '# Bootstrap\n' > "$r/docs/bootstrap.md"
printf '# Registro de decisões\n' > "$r/docs/decisoes.md"
( cd "$r" && sh scripts/agentic/ativar-protecoes.sh >/dev/null )
# Passo 8.1 da entrevista: stageia o kit com os hooks executáveis no índice.
git -C "$r" add -A
git -C "$r" add --chmod=+x .githooks/pre-commit .githooks/pre-merge-commit .githooks/pre-push
tl_espera 0 "instância completa passa" sh "$dir/checa-instancia.sh" "$r"

git -C "$r" rm -q --cached .claude/settings.json
tl_espera 1 "detecta settings.json não rastreado" sh "$dir/checa-instancia.sh" "$r"
tl_contem "não rastreado" "aponta o settings não rastreado"
git -C "$r" add .claude/settings.json

git -C "$r" update-index --chmod=-x .githooks/pre-push
tl_espera 1 "detecta hook 100644 no índice" sh "$dir/checa-instancia.sh" "$r"
tl_contem ".githooks/pre-push" "aponta o hook sem bit executável"
git -C "$r" update-index --chmod=+x .githooks/pre-push
tl_espera 0 "hooks 100755 no índice passam" sh "$dir/checa-instancia.sh" "$r"

sed -i 's/^CMD_VERIFY_STACK="true"$/CMD_VERIFY_STACK="false"/' "$r/.agentic/config"
tl_espera 1 "verify vermelho na instância é problema" sh "$dir/checa-instancia.sh" "$r"
tl_contem "VERIFY: FALHOU" "mostra a saída do verify (arquivo temporário via mktemp)"
sed -i 's/^CMD_VERIFY_STACK="false"$/CMD_VERIFY_STACK="true"/' "$r/.agentic/config"

git -C "$r" config core.hooksPath .outro
tl_espera 1 "detecta hooksPath errado" sh "$dir/checa-instancia.sh" "$r"
tl_contem "core.hooksPath" "aponta o hooksPath"

tl_fim
