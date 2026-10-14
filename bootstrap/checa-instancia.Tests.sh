#!/bin/sh
# Testes do checa-instancia.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

r=$(tl_repo)
sh "$dir/instalar.sh" "$r" >/dev/null
tl_espera 1 "instalação crua não passa (placeholders e settings inativos)" sh "$dir/checa-instancia.sh" "$r"
tl_contem "{{" "aponta placeholders restantes"
tl_contem "settings.json" "aponta settings não ativado"
tl_contem "agentic/projeto/papeis" "aponta perfis com placeholders"

# Simula um bootstrap completo: preenche placeholders, configura comandos e ativa as proteções.
find "$r/AGENTS.md" "$r/agentic/processo/papeis" "$r/agentic/projeto/papeis" "$r/.claude/agents" -type f ! -name '_oraculo.md' \
  -exec sed -i 's/{{[A-Z0-9_]*}}/preenchido/g' {} +
cat > "$r/agentic/config" <<'EOF'
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
mkdir -p "$r/agentic/projeto"
printf '# Bootstrap\n' > "$r/agentic/projeto/bootstrap.md"
printf '# Registro de decisões\n' > "$r/agentic/projeto/decisoes.md"
( cd "$r" && sh agentic/mecanismos/scripts/ativar-protecoes.sh >/dev/null )
# Passo 8.1 da entrevista: stageia o kit com os hooks executáveis no índice.
git -C "$r" add -A
git -C "$r" add --chmod=+x agentic/mecanismos/githooks/pre-commit agentic/mecanismos/githooks/pre-merge-commit agentic/mecanismos/githooks/pre-push
tl_espera 0 "instância completa passa" sh "$dir/checa-instancia.sh" "$r"

# Perfis dos papéis: obrigatórios, sem placeholder, e todo caminho citado entre crases existe.
mv "$r/agentic/projeto/papeis/testes.md" "$r/.testes.md"
tl_espera 1 "detecta perfil ausente" sh "$dir/checa-instancia.sh" "$r"
tl_contem "perfil ausente: agentic/projeto/papeis/testes.md" "aponta o perfil ausente"
mv "$r/.testes.md" "$r/agentic/projeto/papeis/testes.md"

cp "$r/agentic/projeto/papeis/dev.md" "$r/.dev.md"
mkdir -p "$r/docs" && printf 'x\n' > "$r/docs/existe.md" && printf 'x\n' > "$r/package.json"
cat >> "$r/agentic/projeto/papeis/dev.md" <<'EOF'
- Leia `docs/existe.md`, `package.json` e `docs/` antes; contrato em `agentic/processo/papeis/dev.md`.
- Comandos e nomes, não caminhos: `npm test`, `npx jest test/a.test.js`, `CMD_VERIFY_STACK`, `org.junit.Test`, `@sap/cds`, `https://exemplo.invalid/a.md`.
- Globs e placeholders: `src/**/*.js`, `agentic/projeto/specs/<nome>/spec.md`, `$HOME/x.md`.
EOF
git -C "$r" add -A
tl_espera 0 "perfil com caminhos existentes, comandos, globs e placeholders passa" sh "$dir/checa-instancia.sh" "$r"
printf -- '- Estrutura em `docs/architecture/ui5-cap-structure.md` e em `docs/existe.md:12`.\n' >> "$r/agentic/projeto/papeis/dev.md"
tl_espera 1 "detecta caminho inexistente citado no perfil" sh "$dir/checa-instancia.sh" "$r"
tl_contem "agentic/projeto/papeis/dev.md cita docs/architecture/ui5-cap-structure.md, que não existe" "aponta perfil e caminho"
tl_espera 1 "caminho com :linha é conferido sem a linha" grep -q "existe.md:12" "$TL_SAIDA"
cp "$r/.dev.md" "$r/agentic/projeto/papeis/dev.md"; rm "$r/.dev.md"
git -C "$r" add -A

# Contrato do kit editado na instância: a personalização vai para o perfil.
cp "$r/agentic/processo/papeis/revisor.md" "$r/.revisor.md"
printf '\n## Contexto da stack\nUI5 + CAP.\n' >> "$r/agentic/processo/papeis/revisor.md"
tl_espera 1 "detecta contrato editado na instância" sh "$dir/checa-instancia.sh" "$r"
tl_contem "contrato editado na instância: mova a personalização para agentic/projeto/papeis/revisor.md" "aponta o contrato e o perfil"
cp "$r/.revisor.md" "$r/agentic/processo/papeis/revisor.md"; rm "$r/.revisor.md"
cr=$(printf '\r'); sed -i "s/\$/$cr/" "$r/agentic/processo/papeis/dev.md"
tl_espera 0 "contrato com CRLF (checkout no Windows) não é edição" sh "$dir/checa-instancia.sh" "$r"
sed -i "s/$cr\$//" "$r/agentic/processo/papeis/dev.md"
mv "$r/agentic/processo/.kit-manifesto" "$r/.manifesto"
tl_espera 0 "instância sem manifesto (antiga) só recebe aviso" sh "$dir/checa-instancia.sh" "$r"
tl_contem "AVISO: sem agentic/processo/.kit-manifesto" "avisa a falta do manifesto"
mv "$r/.manifesto" "$r/agentic/processo/.kit-manifesto"

git -C "$r" rm -q --cached .claude/settings.json
tl_espera 1 "detecta settings.json não rastreado" sh "$dir/checa-instancia.sh" "$r"
tl_contem "não rastreado" "aponta o settings não rastreado"
git -C "$r" add .claude/settings.json

git -C "$r" update-index --chmod=-x agentic/mecanismos/githooks/pre-push
tl_espera 1 "detecta hook 100644 no índice" sh "$dir/checa-instancia.sh" "$r"
tl_contem "agentic/mecanismos/githooks/pre-push" "aponta o hook sem bit executável"
git -C "$r" update-index --chmod=+x agentic/mecanismos/githooks/pre-push
tl_espera 0 "hooks 100755 no índice passam" sh "$dir/checa-instancia.sh" "$r"

sed -i 's/^CMD_VERIFY_STACK="true"$/CMD_VERIFY_STACK="false"/' "$r/agentic/config"
tl_espera 1 "verify vermelho na instância é problema" sh "$dir/checa-instancia.sh" "$r"
tl_contem "VERIFY: FALHOU" "mostra a saída do verify (arquivo temporário via mktemp)"
sed -i 's/^CMD_VERIFY_STACK="false"$/CMD_VERIFY_STACK="true"/' "$r/agentic/config"

git -C "$r" config core.hooksPath .outro
tl_espera 1 "detecta hooksPath errado" sh "$dir/checa-instancia.sh" "$r"
tl_contem "core.hooksPath" "aponta o hooksPath"

tl_fim
