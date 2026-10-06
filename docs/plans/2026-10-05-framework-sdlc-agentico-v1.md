# Framework de SDLC Agêntico v1 — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir o kit do framework (núcleo neutro, mecanismos determinísticos, adaptador Claude Code, bootstrap) e validá-lo em dois projetos-exemplo.

**Architecture:** Três camadas: `core/` (Markdown neutro: princípios, ciclo, papéis, templates), `mecanismos/` (githooks e scripts POSIX `sh`, cada um com `.Tests.sh`), `adapters/claude-code/` (agentes finos, comandos, hooks, settings). `bootstrap/instalar.sh` copia o kit para um projeto; o comando `/bootstrap` entrevista o profissional e instancia os placeholders `{{...}}`.

**Tech Stack:** POSIX `sh` (executado via Git Bash no Windows), git ≥ 2.40, gitleaks 8.x, Markdown. Exemplos usam Python 3 (`unittest`) e Node ≥ 20 (`node --test`).

**Spec:** `docs/specs/2026-10-05-framework-sdlc-agentico-design.md`

## Global Constraints

- Documentação e contratos em português; scripts em POSIX `sh` com `#!/bin/sh`, sem bashismos (`[[`, arrays, `local`, `function`).
- Scripts e hooks com fim de linha LF (`.gitattributes`); um CRLF quebra o `sh`.
- Todo script/hook em `mecanismos/` e `adapters/claude-code/hooks/` tem um `<nome>.Tests.sh` ao lado, com casos que **devem** bloquear e casos que **não devem** bloquear.
- Mecanismos são **fail-closed**: dependência ausente, configuração ausente ou erro interno resultam em bloqueio com mensagem, nunca em sucesso silencioso.
- Mensagens de bloqueio começam com `agentic: BLOQUEADO — `.
- Placeholders de instanciação do bootstrap usam `{{NOME}}`; campos de templates de artefato (preenchidos a cada intent/spec/task) usam `<descrição>`.
- Campos de estado nos artefatos usam exatamente `**Status:** <valor>` (lidos por `status-projeto.sh`); tasks têm `**Branch:** <nome>` (lido por `verify.sh`).
- Arquivos de teste nunca contêm segredos literais: strings de teste que pareçam segredo são montadas por concatenação em tempo de execução (senão o próprio pre-commit bloqueia o kit no projeto alvo).
- Nada fora deste repositório é modificado (os projetos de referência são só leitura; o teste de fogo usa worktree descartável).
- O kit nunca contém código de produto.

## Review Focus

1. **CRLF no Windows** — usuário clona com `core.autocrlf=true`; scripts e hooks sem extensão viram CRLF e o `sh` falha com `$'\r': command not found`. Esperado: `.gitattributes` força LF no framework e o `instalar.sh` acrescenta as regras no projeto alvo. Pinado na Task 14 (`instalar.Tests.sh`: `.gitattributes` contém as regras).
2. **Repositório sem a branch principal ou sem commits** — `status-projeto.sh` e `verify.sh` rodados num repositório recém-criado. Esperado: saem com informação degradada, sem quebrar. Pinado na Task 5 (status sem `main`) e Task 9 (verify em `main`).
3. **Nomes de arquivo com espaço** — `verifica-escopo.sh` com arquivo `docs/a b.md` alterado. Esperado: o arquivo é reportado inteiro como fora do escopo, sem quebrar em dois. Pinado na Task 6.
4. **gitleaks ausente** — máquina sem gitleaks. Esperado: commit bloqueado com instrução de instalação (fail-closed). Pinado na Task 3 via `GITLEAKS_BIN` em `.agentic/config`.
5. **Execução fora da raiz** — `verify.sh` chamado de um subdiretório. Esperado: resolve a raiz pelo git e funciona igual. Pinado na Task 9.

## Estrutura de arquivos

```
.gitattributes                         LF para sh e hooks
README.md                              o que é, início rápido, estrutura
scripts/verify.sh                      roda todas as suítes *.Tests.sh do framework
core/principios.md                     7 princípios-meta com "Verificado por"
core/processo/ciclo.md                 trilhas, fases, gates, N3, regras de fluxo, orquestração
core/papeis/{dominio,arquiteto,testes,dev,revisor,_oraculo}.md
core/templates/{intent,spec,design,task,decisoes,pr,AGENTS}.md
mecanismos/githooks/{pre-commit,pre-merge-commit,pre-push}(+ .Tests.sh)
mecanismos/scripts/testlib.sh(+ .Tests.sh)      mini framework de testes
mecanismos/scripts/lib-agentic.sh               config + funções comuns
mecanismos/scripts/{status-projeto,verifica-escopo,verifica-skip,verifica-red,verify,ativar-protecoes}.sh (+ .Tests.sh)
adapters/claude-code/CLAUDE.md
adapters/claude-code/settings.json.tmpl
adapters/claude-code/hooks/pre-tool-use.sh(+ .Tests.sh)
adapters/claude-code/agents/{dominio,arquiteto,testes,dev,revisor,_oraculo}.md
adapters/claude-code/commands/{bootstrap,intent,nova-task,verify,status}.md
bootstrap/instalar.sh(+ .Tests.sh)
bootstrap/checa-instancia.sh(+ .Tests.sh)
bootstrap/config.padrao  bootstrap/auto-mode.padrao  bootstrap/entrevista.md
exemplos/python-cli-novo/…  exemplos/node-servico-existente/…
scripts/montar-exemplo.sh
docs/origem.md  docs/validacao-v1.md
```

**Notas de desvio da spec (simplificações conscientes):**
- A spec cita `verify.tmpl`. O plano usa um `verify.sh` genérico que lê os comandos da stack de `.agentic/config`; não há templating de script, só de configuração.
- A spec cita baseline do gitleaks em projeto existente. Como o gitleaks roda só sobre o conteúdo **staged**, segredos legados não bloqueiam commits novos; não há baseline de gitleaks. O baseline existe para testes pulados (`.agentic/baseline-skips`) e para a ferramenta de arquitetura (mecanismo próprio dela, registrado em `decisoes.md`).
- Acrescenta-se o comando `/intent` (entrada da Fase 0), ausente da lista da spec.
- `settings.json` é instalado como `.agentic/settings.pendente.json` e ativado pelo **humano** com `ativar-protecoes.sh` (princípio 5: permissões são do humano; também evita que o deny bloqueie o próprio `/bootstrap`).

---

### Task 1: Esqueleto, testlib e verify do framework

**Files:**
- Create: `.gitattributes`
- Create: `README.md`
- Create: `scripts/verify.sh`
- Create: `mecanismos/scripts/testlib.sh`
- Test: `mecanismos/scripts/testlib.Tests.sh`

**Interfaces:**
- Produces: `testlib.sh` com `tl_repo` (imprime caminho de repo git temporário com commit inicial em `main`), `tl_espera <codigo> <descricao> <cmd...>`, `tl_contem <texto> <descricao>` (confere a saída do último `tl_espera`), `tl_fim` (imprime resumo; retorna 1 se houve falha). `scripts/verify.sh` roda todo `*.Tests.sh` sob `mecanismos/`, `adapters/`, `bootstrap/`.

- [ ] **Step 1: Criar `.gitattributes`**

```
*.sh text eol=lf
*.tmpl text eol=lf
*.padrao text eol=lf
mecanismos/githooks/* text eol=lf
```

- [ ] **Step 2: Escrever o teste da testlib (falhando, pois a testlib não existe)**

`mecanismos/scripts/testlib.Tests.sh`:
```sh
#!/bin/sh
# Testes da própria testlib: um caso que passa e a detecção de um caso que falha.
. "$(dirname "$0")/testlib.sh"

repo=$(tl_repo)
tl_espera 0 "tl_repo cria repositório com commit inicial em main" git -C "$repo" rev-parse --verify -q main
tl_espera 0 "tl_espera aceita código esperado" sh -c 'exit 0'
tl_espera 3 "tl_espera compara código diferente de zero" sh -c 'echo saida-x; exit 3'
tl_contem "saida-x" "tl_contem encontra texto na saída do último comando"

# Uma falha proposital, executada num subshell isolado, deve fazer tl_fim retornar 1.
( . "$(dirname "$0")/testlib.sh"; tl_espera 0 "falha proposital" sh -c 'exit 1' >/dev/null; tl_fim >/dev/null )
tl_espera 1 "tl_fim retorna 1 quando há falha" sh -c "exit $?"

tl_fim
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `sh mecanismos/scripts/testlib.Tests.sh`
Expected: erro `testlib.sh: No such file or directory`.

- [ ] **Step 4: Implementar a testlib**

`mecanismos/scripts/testlib.sh`:
```sh
# testlib.sh — mini framework de testes dos mecanismos do framework.
# Uso: . "$(dirname "$0")/testlib.sh" ; tl_espera ... ; tl_contem ... ; tl_fim
TL_TOTAL=0
TL_FALHAS=0
TL_SAIDA=$(mktemp)

# tl_repo: cria um repositório git temporário com commit inicial em main e imprime o caminho.
tl_repo() {
  tl_d=$(mktemp -d)
  git -C "$tl_d" init -q -b main
  git -C "$tl_d" config user.email teste@exemplo.invalid
  git -C "$tl_d" config user.name teste
  git -C "$tl_d" config commit.gpgsign false
  git -C "$tl_d" config core.autocrlf false
  git -C "$tl_d" commit -q --allow-empty -m "inicial"
  printf '%s\n' "$tl_d"
}

# tl_espera <codigo> <descricao> <comando...>: roda o comando e confere o código de saída.
tl_espera() {
  tl_esperado=$1
  tl_desc=$2
  shift 2
  TL_TOTAL=$((TL_TOTAL + 1))
  "$@" >"$TL_SAIDA" 2>&1
  tl_obtido=$?
  if [ "$tl_obtido" -eq "$tl_esperado" ]; then
    printf 'ok    %s\n' "$tl_desc"
  else
    TL_FALHAS=$((TL_FALHAS + 1))
    printf 'FALHA %s (esperado %s, obtido %s)\n' "$tl_desc" "$tl_esperado" "$tl_obtido"
    sed 's/^/      | /' "$TL_SAIDA"
  fi
}

# tl_contem <texto> <descricao>: confere que a saída do último tl_espera contém o texto.
tl_contem() {
  TL_TOTAL=$((TL_TOTAL + 1))
  if grep -qF -- "$1" "$TL_SAIDA"; then
    printf 'ok    %s\n' "$2"
  else
    TL_FALHAS=$((TL_FALHAS + 1))
    printf 'FALHA %s (saída não contém: %s)\n' "$2" "$1"
    sed 's/^/      | /' "$TL_SAIDA"
  fi
}

# tl_fim: imprime o resumo e retorna 1 se houve alguma falha.
tl_fim() {
  rm -f "$TL_SAIDA"
  printf '%s testes, %s falhas\n' "$TL_TOTAL" "$TL_FALHAS"
  [ "$TL_FALHAS" -eq 0 ]
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `sh mecanismos/scripts/testlib.Tests.sh`
Expected: todas as linhas `ok`, `5 testes, 0 falhas`.

- [ ] **Step 6: Criar `scripts/verify.sh` do framework**

```sh
#!/bin/sh
# verify.sh do framework — roda todas as suítes *.Tests.sh. Só reporta; nunca conserta.
raiz=$(cd "$(dirname "$0")/.." && pwd)
falhas=0
suites=$(find "$raiz/mecanismos" "$raiz/adapters" "$raiz/bootstrap" -name '*.Tests.sh' 2>/dev/null | sort)
for t in $suites; do
  printf '\n== %s\n' "${t#"$raiz"/}"
  sh "$t" || falhas=$((falhas + 1))
done
printf '\n'
if [ "$falhas" -eq 0 ]; then
  echo "verify: OK"
else
  echo "verify: $falhas suíte(s) falharam"
  exit 1
fi
```

- [ ] **Step 7: Criar `README.md`**

```markdown
# Framework de SDLC Agêntico

Referência reutilizável de SDLC agêntico: papéis de agentes, artefatos, gates e mecanismos de controle para desenvolver **qualquer tipo de software** com IA. Contém apenas a estrutura agêntica — nunca código de produto.

## Início rápido

1. `sh bootstrap/instalar.sh <caminho-do-projeto>` — copia o kit (não pergunta nada, não sobrescreve nada).
2. No projeto, abra o Claude Code e rode `/bootstrap` — entrevista sobre contexto e stack; instancia agentes e controles.
3. Ative as proteções (ação humana): `sh scripts/agentic/ativar-protecoes.sh`.
4. Comece pelo primeiro intent: `/intent`.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `core/` | Neutro: princípios, ciclo, contratos de papéis, templates de artefatos |
| `mecanismos/` | Controle determinístico: githooks e scripts `sh`, cada um com testes |
| `adapters/claude-code/` | Adaptador fino para Claude Code: agentes, comandos, hooks, settings |
| `bootstrap/` | Instalador, entrevista, checagem estrutural |
| `exemplos/` | Projetos usados para validar o agnosticismo |
| `docs/` | Spec, plano, origem de cada regra, validação |

## Verificação do framework

`sh scripts/verify.sh` — roda todas as suítes de teste dos mecanismos.

Design completo: `docs/specs/2026-10-05-framework-sdlc-agentico-design.md`.
```

- [ ] **Step 8: Rodar o verify do framework**

Run: `sh scripts/verify.sh`
Expected: suíte `mecanismos/scripts/testlib.Tests.sh` com `0 falhas` e `verify: OK`.

- [ ] **Step 9: Commit**

```bash
git add .gitattributes README.md scripts/verify.sh mecanismos/scripts/testlib.sh mecanismos/scripts/testlib.Tests.sh
git commit -m "feat: esqueleto do framework, testlib e verify"
```

---

### Task 2: lib-agentic e proteção de branch (pre-commit, pre-merge-commit)

**Files:**
- Create: `mecanismos/scripts/lib-agentic.sh`
- Create: `mecanismos/githooks/pre-commit`
- Create: `mecanismos/githooks/pre-merge-commit`
- Test: `mecanismos/githooks/pre-commit.Tests.sh`

**Interfaces:**
- Consumes: `testlib.sh` (Task 1).
- Produces: `lib-agentic.sh` — ao ser carregado (`. lib-agentic.sh`) define `agentic_raiz` (raiz do repo) e as variáveis de configuração com padrões (`BRANCH_PRINCIPAL=main`, `BRANCHES_PROTEGIDAS="main master"`, `DIRS_TESTE="tests/ test/"`, `MARCADOR_DESABILITADO=""`, `MARCADOR_ASSERCAO="assert|expect"`, `RELATORIO_TESTES=""`, `CMD_PREPARAR_TESTE=""`, `CMD_TESTE=""`, `CMD_VERIFY_STACK=""`, `GITLEAKS_BIN=gitleaks`), sobrescritas por `<raiz>/.agentic/config`; funções `agentic_branch_protegida <branch>` (retorna 0 se protegida), `agentic_falha <msg>` (imprime `agentic: BLOQUEADO — <msg>` no stderr e sai 1), `agentic_base` (imprime `git merge-base HEAD $BRANCH_PRINCIPAL`). Hooks localizam a lib em `$(dirname "$0")/../scripts/agentic/lib-agentic.sh` (layout do projeto) ou `$(dirname "$0")/../scripts/lib-agentic.sh` (layout do framework).

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/githooks/pre-commit.Tests.sh`:
```sh
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
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/githooks/pre-commit.Tests.sh`
Expected: `FALHA bloqueia commit direto em main (esperado 1, obtido 0)` (hooks ainda não existem).

- [ ] **Step 3: Implementar `lib-agentic.sh`**

`mecanismos/scripts/lib-agentic.sh`:
```sh
# lib-agentic.sh — configuração e funções comuns aos hooks e scripts do framework.
# Carregar com ". lib-agentic.sh". Lê <raiz>/.agentic/config sobre os padrões abaixo.
agentic_raiz=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "agentic: BLOQUEADO — fora de um repositório git" >&2
  exit 1
}

BRANCH_PRINCIPAL="main"
BRANCHES_PROTEGIDAS="main master"
DIRS_TESTE="tests/ test/"
MARCADOR_DESABILITADO=""
MARCADOR_ASSERCAO="assert|expect"
RELATORIO_TESTES=""
CMD_PREPARAR_TESTE=""
CMD_TESTE=""
CMD_VERIFY_STACK=""
GITLEAKS_BIN="gitleaks"

if [ -f "$agentic_raiz/.agentic/config" ]; then
  . "$agentic_raiz/.agentic/config"
fi

# agentic_branch_protegida <branch>: retorna 0 se a branch está em BRANCHES_PROTEGIDAS.
agentic_branch_protegida() {
  for agentic_b in $BRANCHES_PROTEGIDAS; do
    [ "$1" = "$agentic_b" ] && return 0
  done
  return 1
}

# agentic_falha <mensagem>: bloqueia com mensagem padronizada.
agentic_falha() {
  printf 'agentic: BLOQUEADO — %s\n' "$*" >&2
  exit 1
}

# agentic_base: ponto de divergência entre HEAD e a branch principal.
agentic_base() {
  git merge-base HEAD "$BRANCH_PRINCIPAL" 2>/dev/null
}
```

- [ ] **Step 4: Implementar `pre-commit` (só a parte de branch nesta task)**

`mecanismos/githooks/pre-commit`:
```sh
#!/bin/sh
# pre-commit — bloqueia commit em branch protegida. Fail-closed.
agentic_lib=""
for agentic_c in "$(dirname "$0")/../scripts/agentic/lib-agentic.sh" "$(dirname "$0")/../scripts/lib-agentic.sh"; do
  if [ -f "$agentic_c" ]; then agentic_lib=$agentic_c; break; fi
done
[ -n "$agentic_lib" ] || { echo "agentic: BLOQUEADO — lib-agentic.sh não encontrada (fail-closed)" >&2; exit 1; }
. "$agentic_lib"

branch=$(git symbolic-ref --short -q HEAD) || branch=""
if [ -n "$branch" ] && agentic_branch_protegida "$branch"; then
  agentic_falha "commit direto em '$branch' (branch protegida). Trabalhe numa branch e integre via PR."
fi

exit 0
```

- [ ] **Step 5: Implementar `pre-merge-commit`**

`mecanismos/githooks/pre-merge-commit`:
```sh
#!/bin/sh
# pre-merge-commit — bloqueia merge local que cria commit numa branch protegida.
# Limite declarado: merge fast-forward não dispara hooks; a proteção do remoto fica no pre-push.
agentic_lib=""
for agentic_c in "$(dirname "$0")/../scripts/agentic/lib-agentic.sh" "$(dirname "$0")/../scripts/lib-agentic.sh"; do
  if [ -f "$agentic_c" ]; then agentic_lib=$agentic_c; break; fi
done
[ -n "$agentic_lib" ] || { echo "agentic: BLOQUEADO — lib-agentic.sh não encontrada (fail-closed)" >&2; exit 1; }
. "$agentic_lib"

branch=$(git symbolic-ref --short -q HEAD) || branch=""
if [ -n "$branch" ] && agentic_branch_protegida "$branch"; then
  agentic_falha "merge local em '$branch' (branch protegida). A integração é do humano, via PR."
fi

exit 0
```

- [ ] **Step 6: Rodar e ver passar**

Run: `sh mecanismos/githooks/pre-commit.Tests.sh`
Expected: todas `ok`, `0 falhas`.

- [ ] **Step 7: Commit**

```bash
git add mecanismos/scripts/lib-agentic.sh mecanismos/githooks/pre-commit mecanismos/githooks/pre-merge-commit mecanismos/githooks/pre-commit.Tests.sh
git commit -m "feat(mecanismos): lib-agentic e proteção de branch em commit e merge"
```

---

### Task 3: Varredura de segredos no pre-commit

**Files:**
- Modify: `mecanismos/githooks/pre-commit` (acrescentar antes do `exit 0` final)
- Test: `mecanismos/githooks/pre-commit-segredos.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh` (`GITLEAKS_BIN`, `agentic_falha`, `agentic_raiz`).
- Produces: pre-commit bloqueia (exit 1) quando (a) `GITLEAKS_BIN` não existe, (b) gitleaks acha vazamento no conteúdo staged, (c) linha adicionada casa o padrão de palavra-chave sem a marca `agentic:permitir-segredo`.

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/githooks/pre-commit-segredos.Tests.sh`:
```sh
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
printf '%s = "ValorDeFixture99"  # agentic:permitir-segredo\n' "$pw" > "$r/e.py"; git -C "$r" add e.py
tl_espera 0 "linha marcada como permitida passa" git -C "$r" commit -q -m "x"

r=$(novo_repo)
mkdir -p "$r/.agentic"; echo 'GITLEAKS_BIN="/nao/existe/gitleaks"' > "$r/.agentic/config"
echo ok > "$r/f.txt"; git -C "$r" add f.txt
tl_espera 1 "fail-closed quando o gitleaks não está instalado" git -C "$r" commit -q -m "x"
tl_contem "gitleaks" "mensagem orienta a instalar o gitleaks"

tl_fim
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/githooks/pre-commit-segredos.Tests.sh`
Expected: `FALHA bloqueia token detectado pelo gitleaks (esperado 1, obtido 0)` e as demais de bloqueio falhando.

- [ ] **Step 3: Implementar a varredura**

Em `mecanismos/githooks/pre-commit`, substituir o comentário do topo por `# pre-commit — bloqueia commit em branch protegida e segredos no conteúdo staged. Fail-closed.` e inserir, imediatamente antes do `exit 0` final:
```sh
# --- Segredos: camada 1, gitleaks sobre o conteúdo staged.
command -v "$GITLEAKS_BIN" >/dev/null 2>&1 || \
  agentic_falha "gitleaks não encontrado ('$GITLEAKS_BIN'). Instale: https://github.com/gitleaks/gitleaks (fail-closed)."
"$GITLEAKS_BIN" git --pre-commit --staged --redact --no-banner --exit-code 3 "$agentic_raiz" >/dev/null 2>&1
agentic_rc=$?
if [ "$agentic_rc" -eq 3 ]; then
  agentic_falha "gitleaks encontrou segredo no conteúdo staged. Rode: $GITLEAKS_BIN git --pre-commit --staged --redact -v"
elif [ "$agentic_rc" -ne 0 ]; then
  agentic_falha "gitleaks falhou ao executar (código $agentic_rc) — fail-closed."
fi

# --- Segredos: camada 2, palavras-chave com valor literal (o gitleaks não pega senha genérica).
agentic_padrao='(senha|password|passwd|secret|segredo|api[_-]?key|token)[A-Za-z0-9_]*["'\'']?[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{8,}["'\'']'
agentic_achados=$(git diff --cached -U0 --no-color | grep '^+' | grep -v '^+++' \
  | grep -iE "$agentic_padrao" | grep -vc 'agentic:permitir-segredo')
if [ "$agentic_achados" -gt 0 ]; then
  agentic_falha "possível segredo literal em $agentic_achados linha(s) staged. Veja 'git diff --cached'. Se for falso positivo, marque a linha com 'agentic:permitir-segredo' e justifique no PR."
fi
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/githooks/pre-commit-segredos.Tests.sh && sh mecanismos/githooks/pre-commit.Tests.sh`
Expected: as duas suítes com `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/githooks/pre-commit mecanismos/githooks/pre-commit-segredos.Tests.sh
git commit -m "feat(mecanismos): varredura de segredos em duas camadas no pre-commit"
```

---

### Task 4: pre-push (branch protegida, exclusão e force-push)

**Files:**
- Create: `mecanismos/githooks/pre-push`
- Test: `mecanismos/githooks/pre-push.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh`.
- Produces: pre-push que lê do stdin linhas `<ref-local> <sha-local> <ref-remoto> <sha-remoto>` e sai 1 se algum destino é branch protegida (inclusive exclusão), se o push não é fast-forward, ou se o commit remoto é desconhecido localmente.

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/githooks/pre-push.Tests.sh`:
```sh
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
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/githooks/pre-push.Tests.sh`
Expected: `FALHA bloqueia push para main (esperado 1, obtido 0)`.

- [ ] **Step 3: Implementar**

`mecanismos/githooks/pre-push`:
```sh
#!/bin/sh
# pre-push — bloqueia push para branch protegida, exclusão de branch protegida e force-push. Fail-closed.
agentic_lib=""
for agentic_c in "$(dirname "$0")/../scripts/agentic/lib-agentic.sh" "$(dirname "$0")/../scripts/lib-agentic.sh"; do
  if [ -f "$agentic_c" ]; then agentic_lib=$agentic_c; break; fi
done
[ -n "$agentic_lib" ] || { echo "agentic: BLOQUEADO — lib-agentic.sh não encontrada (fail-closed)" >&2; exit 1; }
. "$agentic_lib"

zero="0000000000000000000000000000000000000000"
status=0
while read -r ref_local sha_local ref_remoto sha_remoto; do
  [ -n "$ref_remoto" ] || continue
  branch=${ref_remoto#refs/heads/}
  if agentic_branch_protegida "$branch"; then
    printf 'agentic: BLOQUEADO — push para %s (branch protegida). Abra um PR; o merge é do humano.\n' "$branch" >&2
    status=1
    continue
  fi
  [ "$sha_local" = "$zero" ] && continue    # exclusão de branch de trabalho
  [ "$sha_remoto" = "$zero" ] && continue   # branch nova no remoto
  if ! git cat-file -e "$sha_remoto^{commit}" 2>/dev/null; then
    printf 'agentic: BLOQUEADO — commit remoto %s desconhecido localmente; rode git fetch (fail-closed).\n' "$sha_remoto" >&2
    status=1
    continue
  fi
  if ! git merge-base --is-ancestor "$sha_remoto" "$sha_local"; then
    printf 'agentic: BLOQUEADO — push não fast-forward (force-push) em %s.\n' "$branch" >&2
    status=1
  fi
done
exit $status
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/githooks/pre-push.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/githooks/pre-push mecanismos/githooks/pre-push.Tests.sh
git commit -m "feat(mecanismos): pre-push contra branch protegida e force-push"
```

---

### Task 5: status-projeto.sh (estado derivado)

**Files:**
- Create: `mecanismos/scripts/status-projeto.sh`
- Test: `mecanismos/scripts/status-projeto.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh` (`agentic_raiz`, `BRANCH_PRINCIPAL`).
- Produces: `status-projeto.sh` imprime, em Markdown: branch atual, `git worktree list`, branches com commits à frente da principal, `- <arquivo>: <status>` para cada `.md` em `intent/` e `docs/specs/` (exceto `_*.md`) com linha `**Status:**`, e `Modo automático: ligado|desligado` (lê `.agentic/auto-mode`, linha `enabled: true`). Sempre sai 0.

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/scripts/status-projeto.Tests.sh`:
```sh
#!/bin/sh
# Testes do status-projeto.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(tl_repo)
mkdir -p "$r/intent" "$r/docs/specs/pedidos/tasks" "$r/.agentic"
printf '# Intent: pedidos\n**Status:** aprovado\n' > "$r/intent/001-pedidos.md"
printf '# Task 001\n**Status:** em-andamento\n**Branch:** pedidos/001\n' > "$r/docs/specs/pedidos/tasks/001-criar.md"
printf '# modelo\n**Status:** <x>\n' > "$r/docs/specs/_template.md"
echo "enabled: true" > "$r/.agentic/auto-mode"
git -C "$r" checkout -q -b pedidos/001
git -C "$r" commit -q --allow-empty -m "w1"

tl_espera 0 "status sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Branch atual: pedidos/001" "mostra a branch atual"
tl_contem "intent/001-pedidos.md: aprovado" "lista status de intent"
tl_contem "docs/specs/pedidos/tasks/001-criar.md: em-andamento" "lista status de task"
tl_contem "pedidos/001: 1 commit(s)" "mostra branch à frente da principal"
tl_contem "Modo automático: ligado" "lê o auto-mode"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "ignora arquivos _modelo" grep -q "_template" "$copia_saida"

# Review Focus 2: repositório sem a branch principal.
r2=$(mktemp -d); git -C "$r2" init -q -b trabalho
tl_espera 0 "não quebra sem a branch principal e sem commits" sh -c "cd '$r2' && sh '$dir/status-projeto.sh'"
tl_contem "Modo automático: desligado" "auto-mode ausente = desligado"

tl_fim
```

Nota: a saída é copiada antes do `grep` porque `tl_espera` trunca `$TL_SAIDA` antes de rodar o comando — um `grep` direto em `$TL_SAIDA` passaria sempre, sem testar nada.

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/status-projeto.Tests.sh`
Expected: `FALHA status sai com 0 (esperado 0, obtido 127)` ou erro de arquivo inexistente.

- [ ] **Step 3: Implementar**

`mecanismos/scripts/status-projeto.sh`:
```sh
#!/bin/sh
# status-projeto.sh — estado do projeto DERIVADO do git e dos campos **Status:**.
# Nada aqui é escrito à mão. Executado no início de cada sessão (hook SessionStart).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 0

echo "## Estado do projeto (derivado — não edite à mão)"
echo "Branch atual: $(git symbolic-ref --short -q HEAD || echo '(detached)')"

echo
echo "### Worktrees"
git worktree list 2>/dev/null

echo
echo "### Branches à frente de $BRANCH_PRINCIPAL"
if git rev-parse --verify -q "$BRANCH_PRINCIPAL" >/dev/null; then
  git for-each-ref --format='%(refname:short)' refs/heads | while read -r b; do
    [ "$b" = "$BRANCH_PRINCIPAL" ] && continue
    n=$(git rev-list --count "$BRANCH_PRINCIPAL..$b" 2>/dev/null || echo "?")
    [ "$n" = "0" ] || echo "- $b: $n commit(s)"
  done
else
  echo "- (branch principal '$BRANCH_PRINCIPAL' ainda não existe)"
fi

echo
echo "### Artefatos"
find intent docs/specs -name '*.md' ! -name '_*' 2>/dev/null | sort | while read -r f; do
  s=$(grep -m1 '^\*\*Status:\*\*' "$f" | sed 's/^\*\*Status:\*\*[[:space:]]*//')
  [ -n "$s" ] && echo "- $f: $s"
done

echo
modo="desligado"
grep -q '^enabled:[[:space:]]*true' .agentic/auto-mode 2>/dev/null && modo="ligado"
echo "Modo automático: $modo"
exit 0
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/scripts/status-projeto.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/status-projeto.sh mecanismos/scripts/status-projeto.Tests.sh
git commit -m "feat(mecanismos): status-projeto com estado derivado"
```

---

### Task 6: verifica-escopo.sh

**Files:**
- Create: `mecanismos/scripts/verifica-escopo.sh`
- Test: `mecanismos/scripts/verifica-escopo.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh` (`agentic_base`, `agentic_raiz`).
- Produces: `verifica-escopo.sh <task.md relativo à raiz> [base]` — sai 0 se todo arquivo alterado (commits desde a base + working tree + não rastreados) casa um padrão da seção `## Arquivos` da task (itens `- caminho` ou ``- `caminho` ``, globs permitidos) ou está sob o diretório da spec da task (`dirname(dirname(task))`); sai 1 listando os de fora; sai 2 em uso incorreto.

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/scripts/verifica-escopo.Tests.sh`:
```sh
#!/bin/sh
# Testes do verifica-escopo.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/docs/specs/pedidos/tasks" "$r/src/pedidos" "$r/tests"
  cat > "$r/docs/specs/pedidos/tasks/001-criar.md" <<'EOF'
# Task 001
**Status:** em-andamento
**Branch:** pedidos/001

## Arquivos
- `src/pedidos/*`
- tests/test_pedidos.py — testes da task

## Critérios de pronto
- src/fora.py não deve contar como escopo só por aparecer aqui
EOF
  git -C "$r" add -A; git -C "$r" commit -q -m "task"
  git -C "$r" checkout -q -b pedidos/001
  printf '%s\n' "$r"
}

r=$(prepara)
echo x > "$r/src/pedidos/criar.py"; echo t > "$r/tests/test_pedidos.py"
git -C "$r" add -A; git -C "$r" commit -q -m "impl"
tl_espera 0 "aceita arquivos dentro do escopo (glob e caminho)" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

echo y > "$r/docs/specs/pedidos/spec.md"
tl_espera 0 "aceita alteração na pasta da própria spec" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

echo z > "$r/src/fora.py"
tl_espera 1 "rejeita arquivo não rastreado fora do escopo" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
tl_contem "src/fora.py" "lista o arquivo fora do escopo"

r=$(prepara)
mkdir -p "$r/docs"; echo e > "$r/docs/a b.md"
tl_espera 1 "rejeita arquivo com espaço no nome" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
tl_contem "docs/a b.md" "reporta o nome com espaço inteiro"

tl_espera 2 "uso incorreto sem task" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh'"

tl_fim
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/verifica-escopo.Tests.sh`
Expected: falhas com código 127 (script inexistente).

- [ ] **Step 3: Implementar**

`mecanismos/scripts/verifica-escopo.sh`:
```sh
#!/bin/sh
# verifica-escopo.sh <task.md> [base] — falha se a branch altera arquivo fora da seção "## Arquivos" da task.
# Para ampliar o escopo, atualize a lista da task num commit docs(task): (visível na revisão e no Gate 2).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
task=${1:-}
[ -n "$task" ] && [ -f "$task" ] || { echo "uso: verifica-escopo.sh <task.md relativo à raiz> [base]" >&2; exit 2; }
base=${2:-$(agentic_base)}
[ -n "$base" ] || agentic_falha "sem base de comparação (a branch principal '$BRANCH_PRINCIPAL' existe?)"

set -f   # padrões com glob não podem ser expandidos contra o disco
padroes=$(sed -n '/^## Arquivos/,/^## /p' "$task" \
  | sed -n 's/^[[:space:]]*-[[:space:]]*`\{0,1\}\([^` ]*\)`\{0,1\}.*/\1/p')
dir_spec=$(dirname "$(dirname "$task")")

fora=$(
  { git diff --name-only "$base" HEAD; git diff --name-only HEAD; git ls-files --others --exclude-standard; } \
  | sort -u | while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in "$dir_spec"/*) continue ;; esac
      dentro=1
      for p in $padroes; do
        case "$f" in $p) dentro=0; break ;; esac
      done
      [ "$dentro" -eq 0 ] || printf '  %s\n' "$f"
    done
)

if [ -n "$fora" ]; then
  echo "agentic: BLOQUEADO — arquivos fora do escopo de $task:"
  printf '%s\n' "$fora"
  echo "Se a ampliação for legítima, acrescente-os em '## Arquivos' via commit docs(task):."
  exit 1
fi
echo "escopo: OK ($task)"
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/scripts/verifica-escopo.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-escopo.sh mecanismos/scripts/verifica-escopo.Tests.sh
git commit -m "feat(mecanismos): verifica-escopo compara diff com os arquivos da task"
```

---

### Task 7: verifica-skip.sh

**Files:**
- Create: `mecanismos/scripts/verifica-skip.sh`
- Test: `mecanismos/scripts/verifica-skip.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh` (`MARCADOR_DESABILITADO`, `RELATORIO_TESTES`, `agentic_base`).
- Produces: `verifica-skip.sh [base]` — sai 1 se (a) alguma linha adicionada desde a base casa `MARCADOR_DESABILITADO` (ERE), ou (b) o número de `<skipped` nos relatórios JUnit (`RELATORIO_TESTES`, glob) excede `.agentic/baseline-skips` (padrão 0), ou (c) `RELATORIO_TESTES` está configurado mas nenhum arquivo existe. Configuração vazia → imprime `degradado:` e não falha por aquele item.

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/scripts/verifica-skip.Tests.sh`:
```sh
#!/bin/sh
# Testes do verifica-skip.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/.agentic" "$r/tests" "$r/relatorio"
  cat > "$r/.agentic/config" <<'EOF'
MARCADOR_DESABILITADO='@unittest\.skip|\.skip\('
RELATORIO_TESTES="relatorio/*.xml"
EOF
  git -C "$r" add -A; git -C "$r" commit -q -m "config"
  git -C "$r" checkout -q -b feat/k
  printf '%s\n' "$r"
}
junit() { printf '<testsuite><testcase name="a"/>%s</testsuite>\n' "$2" > "$1/relatorio/junit.xml"; }

r=$(prepara); junit "$r" ""
echo "def test_a(): pass" > "$r/tests/test_a.py"
tl_espera 0 "passa sem marcador novo e sem skip no relatório" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" ""
printf '@unittest.skip("depois")\ndef test_b(): pass\n' > "$r/tests/test_b.py"
tl_espera 1 "falha com marcador em arquivo novo não rastreado" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "desabilitado" "explica o motivo"
git -C "$r" add -A; git -C "$r" commit -q -m "skip commitado"
tl_espera 1 "falha com marcador em commit da branch" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" '<testcase name="b"><skipped/></testcase>'
tl_espera 1 "falha com skip no relatório acima do baseline" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

echo 1 > "$r/.agentic/baseline-skips"
tl_espera 0 "aceita skips até o baseline registrado" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara)
tl_espera 1 "falha se o relatório configurado não existe" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(tl_repo); git -C "$r" checkout -q -b feat/sem-config
tl_espera 0 "sem configuração: degradado, não falha" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "degradado" "declara a verificação degradada"

tl_fim
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/verifica-skip.Tests.sh`
Expected: falhas com código 127.

- [ ] **Step 3: Implementar**

`mecanismos/scripts/verifica-skip.sh`:
```sh
#!/bin/sh
# verifica-skip.sh [base] — falha se a branch desabilita testes ou se o relatório real mostra skips novos.
# Lê o relatório JUnit real (não confia no exit code). Sem configuração, declara-se degradado.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
base=${1:-$(agentic_base)}
status=0

if [ -n "$MARCADOR_DESABILITADO" ] && [ -n "$base" ]; then
  # Linhas adicionadas em arquivos rastreados (commits + working tree) e conteúdo de arquivos novos não rastreados.
  n_diff=$(git diff "$base" -U0 --no-color | grep '^+' | grep -v '^+++' | grep -cE -- "$MARCADOR_DESABILITADO")
  n_novos=$(git ls-files --others --exclude-standard | while IFS= read -r f; do cat "$f"; done \
    | grep -cE -- "$MARCADOR_DESABILITADO")
  n=$((n_diff + n_novos))
  if [ "$n" -gt 0 ]; then
    echo "agentic: BLOQUEADO — $n linha(s) adicionada(s) marcam teste como desabilitado (padrão: $MARCADOR_DESABILITADO)."
    status=1
  fi
else
  echo "degradado: MARCADOR_DESABILITADO não configurado — marcadores novos não são verificados."
fi

if [ -n "$RELATORIO_TESTES" ]; then
  arquivos=$(ls $RELATORIO_TESTES 2>/dev/null)
  if [ -z "$arquivos" ]; then
    echo "agentic: BLOQUEADO — relatório de testes não encontrado ($RELATORIO_TESTES). Rode os testes antes."
    status=1
  else
    pulados=$(cat $arquivos | grep -o '<skipped' | wc -l | tr -d ' ')
    limite=$(cat .agentic/baseline-skips 2>/dev/null || echo 0)
    if [ "$pulados" -gt "$limite" ]; then
      echo "agentic: BLOQUEADO — $pulados teste(s) pulado(s) no relatório; baseline é $limite."
      status=1
    else
      echo "skip: $pulados pulado(s), baseline $limite — OK"
    fi
  fi
else
  echo "degradado: RELATORIO_TESTES não configurado — skips em tempo de execução não são verificados."
fi
exit $status
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/scripts/verifica-skip.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-skip.sh mecanismos/scripts/verifica-skip.Tests.sh
git commit -m "feat(mecanismos): verifica-skip lê marcadores e relatório real"
```

---

### Task 8: verifica-red.sh

**Files:**
- Create: `mecanismos/scripts/verifica-red.sh`
- Test: `mecanismos/scripts/verifica-red.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh` (`CMD_TESTE`, `CMD_PREPARAR_TESTE`, `DIRS_TESTE`, `MARCADOR_ASSERCAO`, `agentic_base`).
- Produces: `verifica-red.sh [base]` — para cada commit com assunto `test(red):` desde a base: (1) falha se tocou arquivo fora de `DIRS_TESTE`; (2) roda `CMD_TESTE` num worktree destacado naquele commit e falha se os testes **passaram**; (3) falha se o total de linhas que casam `MARCADOR_ASSERCAO` em `DIRS_TESTE` no HEAD é menor que no commit RED. Sem commits RED: imprime e sai 0. `CMD_TESTE` vazio com commits RED: sai 1.

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/scripts/verifica-red.Tests.sh`:
```sh
#!/bin/sh
# Testes do verifica-red.sh com um projeto mínimo em sh (independe de stack).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/.agentic" "$r/src" "$r/tests"
  cat > "$r/.agentic/config" <<'EOF'
CMD_TESTE="sh tests/run.sh"
DIRS_TESTE="tests/"
MARCADOR_ASSERCAO="assert_igual"
EOF
  echo 'soma() { echo 0; }' > "$r/src/soma.sh"
  git -C "$r" add -A; git -C "$r" commit -q -m "base"
  git -C "$r" checkout -q -b feat/soma
  printf '%s\n' "$r"
}
teste_red() {
  cat > "$1/tests/run.sh" <<'EOF'
. ./src/soma.sh
assert_igual() { [ "$1" = "$2" ] || { echo "esperado $2, obtido $1"; exit 1; }; }
assert_igual "$(soma 2 3)" 5
EOF
}

# Caso feliz: RED falha, GREEN passa.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): soma"
tl_espera 0 "aceita RED que falhava e GREEN que mantém asserções" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# RED que já passava não é evidência.
r=$(prepara)
echo 'soma() { echo $(($1 + $2)); }' > "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat: soma antes do teste"
teste_red "$r"; git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "rejeita RED cujos testes passavam" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "PASSAVAM" "explica que o RED não falhava"

# RED tocando produção.
r=$(prepara); teste_red "$r"; echo '# mexi' >> "$r/src/soma.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
tl_espera 1 "rejeita RED que toca fora dos diretórios de teste" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "src/soma.sh" "aponta o arquivo de produção"

# GREEN que remove asserção.
r=$(prepara); teste_red "$r"
git -C "$r" add -A; git -C "$r" commit -q -m "test(red): soma"
printf '. ./src/soma.sh\n' > "$r/tests/run.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "feat(green): removi o teste"
tl_espera 1 "rejeita quando asserções diminuem depois do RED" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"

# Sem commit RED.
r=$(prepara)
tl_espera 0 "sem commit RED não falha" sh -c "cd '$r' && sh '$dir/verifica-red.sh'"
tl_contem "nenhum commit test(red):" "informa ausência de RED"

tl_fim
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/verifica-red.Tests.sh`
Expected: falhas com código 127.

- [ ] **Step 3: Implementar**

`mecanismos/scripts/verifica-red.sh`:
```sh
#!/bin/sh
# verifica-red.sh [base] — prova que cada commit test(red): (1) só tocou testes, (2) falhava de fato,
# (3) não teve asserções removidas depois. Roda os testes do RED num worktree isolado.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
base=${1:-$(agentic_base)}
[ -n "$base" ] || agentic_falha "sem base de comparação (a branch principal '$BRANCH_PRINCIPAL' existe?)"

reds=$(git log --format=%H --grep='^test(red):' "$base..HEAD")
if [ -z "$reds" ]; then
  echo "verifica-red: nenhum commit test(red): na branch"
  exit 0
fi
[ -n "$CMD_TESTE" ] || agentic_falha "CMD_TESTE não configurado em .agentic/config"

conta_assercoes() {
  # shellcheck disable=SC2086
  git grep -c -E -e "$MARCADOR_ASSERCAO" "$1" -- $DIRS_TESTE 2>/dev/null \
    | awk -F: '{ s += $NF } END { print s + 0 }'
}

status=0
for c in $reds; do
  curto=$(git rev-parse --short "$c")

  for f in $(git diff-tree --no-commit-id --name-only -r "$c"); do
    dentro=1
    for d in $DIRS_TESTE; do
      case "$f" in "$d"*) dentro=0 ;; esac
    done
    if [ "$dentro" -ne 0 ]; then
      echo "agentic: BLOQUEADO — RED $curto toca arquivo fora dos diretórios de teste: $f"
      status=1
    fi
  done

  wt=$(mktemp -d)
  rmdir "$wt"
  git worktree add -q --detach "$wt" "$c" || agentic_falha "não foi possível criar worktree para $curto"
  if [ -n "$CMD_PREPARAR_TESTE" ] && ! ( cd "$wt" && eval "$CMD_PREPARAR_TESTE" ) >/dev/null 2>&1; then
    echo "agentic: BLOQUEADO — CMD_PREPARAR_TESTE falhou no RED $curto; não há evidência."
    status=1
  elif ( cd "$wt" && eval "$CMD_TESTE" ) >/dev/null 2>&1; then
    echo "agentic: BLOQUEADO — os testes PASSAVAM no RED $curto: não é evidência de RED."
    status=1
  else
    echo "RED $curto: falhava (ok)"
  fi
  git worktree remove --force "$wt"

  a_red=$(conta_assercoes "$c")
  a_head=$(conta_assercoes HEAD)
  if [ "$a_head" -lt "$a_red" ]; then
    echo "agentic: BLOQUEADO — asserções diminuíram desde o RED $curto: $a_red -> $a_head"
    status=1
  fi
done
exit $status
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/scripts/verifica-red.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-red.sh mecanismos/scripts/verifica-red.Tests.sh
git commit -m "feat(mecanismos): verifica-red prova falha, escopo e asserções do RED"
```

---

### Task 9: verify.sh do projeto (ponto único, com lock)

**Files:**
- Create: `mecanismos/scripts/verify.sh`
- Test: `mecanismos/scripts/verify.Tests.sh`

**Interfaces:**
- Consumes: `lib-agentic.sh` (`CMD_VERIFY_STACK`), `verifica-escopo.sh`, `verifica-skip.sh`, `verifica-red.sh` (Tasks 6–8).
- Produces: `verify.sh [--task <task.md>]` — sai 0 se todas as etapas passam; 1 se alguma falha (imprime `VERIFY: FALHOU em: <etapas>`); 3 se outro verify está em execução (lock `.agentic/verify.lock/` com `pid`). Sem `--task`, procura a task cujo `**Branch:**` é a branch atual; sem task, pula a etapa de escopo (trilha rápida).

- [ ] **Step 1: Escrever o teste (falhando)**

`mecanismos/scripts/verify.Tests.sh`:
```sh
#!/bin/sh
# Testes do verify.sh do projeto.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/.agentic" "$r/tests" "$r/sub/dir" "$r/docs/specs/x/tasks"
  printf 'CMD_VERIFY_STACK="sh tests/stack.sh"\nCMD_TESTE="sh tests/stack.sh"\nDIRS_TESTE="tests/"\n' > "$r/.agentic/config"
  echo 'exit 0' > "$r/tests/stack.sh"
  printf '# T\n**Status:** em-andamento\n**Branch:** x/001\n\n## Arquivos\n- tests/*\n' > "$r/docs/specs/x/tasks/001-t.md"
  git -C "$r" add -A; git -C "$r" commit -q -m "base"
  git -C "$r" checkout -q -b x/001
  printf '%s\n' "$r"
}

r=$(prepara)
tl_espera 0 "passa quando a stack passa e o escopo é respeitado" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: OK" "resumo de sucesso"
tl_contem "escopo: OK" "encontrou a task pela branch"

tl_espera 0 "funciona chamado de um subdiretório" sh -c "cd '$r/sub/dir' && sh '$dir/verify.sh'"

echo 'exit 1' > "$r/tests/stack.sh"
tl_espera 1 "falha quando a stack falha" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "VERIFY: FALHOU em: stack" "nomeia a etapa que falhou"
echo 'exit 0' > "$r/tests/stack.sh"

echo z > "$r/fora.txt"
tl_espera 1 "falha quando o escopo é violado" sh -c "cd '$r' && sh '$dir/verify.sh'"
rm "$r/fora.txt"

mkdir "$r/.agentic/verify.lock"; echo $$ > "$r/.agentic/verify.lock/pid"
tl_espera 3 "recusa rodar com outro verify vivo" sh -c "cd '$r' && sh '$dir/verify.sh'"
echo 999999 > "$r/.agentic/verify.lock/pid"
tl_espera 0 "recupera lock abandonado" sh -c "cd '$r' && sh '$dir/verify.sh'"

git -C "$r" checkout -q main
tl_espera 0 "na branch principal, sem task: pula escopo (trilha rápida)" sh -c "cd '$r' && sh '$dir/verify.sh'"
tl_contem "pulado" "declara a etapa pulada"

r=$(tl_repo)
tl_espera 1 "falha se CMD_VERIFY_STACK não está configurado" sh -c "cd '$r' && sh '$dir/verify.sh'"

tl_fim
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/verify.Tests.sh`
Expected: falhas com código 127.

- [ ] **Step 3: Implementar**

`mecanismos/scripts/verify.sh`:
```sh
#!/bin/sh
# verify.sh [--task <task.md>] — ponto único de verificação do projeto. Só reporta; nunca conserta.
# Etapas: stack (CMD_VERIFY_STACK) → escopo → skip → red.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/lib-agentic.sh"
cd "$agentic_raiz" || exit 1

task=""
[ "${1:-}" = "--task" ] && task=${2:-}
[ -n "$CMD_VERIFY_STACK" ] || agentic_falha "CMD_VERIFY_STACK não configurado em .agentic/config (rode /bootstrap)"

mkdir -p .agentic
lock=".agentic/verify.lock"
if ! mkdir "$lock" 2>/dev/null; then
  pid=$(cat "$lock/pid" 2>/dev/null)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "verify já em execução (pid $pid)"
    exit 3
  fi
  rm -rf "$lock"
  mkdir "$lock" || exit 3
fi
echo $$ > "$lock/pid"
trap 'rm -rf "$lock"' EXIT INT TERM

falhas=""
etapa() {
  nome=$1; shift
  echo; echo "== $nome"
  if "$@"; then echo "-- $nome: OK"; else echo "-- $nome: FALHOU"; falhas="$falhas $nome"; fi
}

etapa stack sh -c "$CMD_VERIFY_STACK"

if [ -z "$task" ]; then
  branch=$(git symbolic-ref --short -q HEAD)
  [ -n "$branch" ] && task=$(grep -l "^\*\*Branch:\*\*[[:space:]]*$branch[[:space:]]*$" docs/specs/*/tasks/*.md 2>/dev/null | head -n 1)
fi
if [ -n "$task" ]; then
  etapa escopo sh "$dir/verifica-escopo.sh" "$task"
else
  echo; echo "== escopo: nenhuma task associada à branch (trilha rápida) — pulado"
fi

etapa skip sh "$dir/verifica-skip.sh"
etapa red sh "$dir/verifica-red.sh"

echo
if [ -z "$falhas" ]; then
  echo "VERIFY: OK"
else
  echo "VERIFY: FALHOU em:$falhas"
  exit 1
fi
```

Nota: `verifica-red.sh` em `main` (base = HEAD) não encontra commits RED e sai 0 — por isso o caso "na branch principal" passa.

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/scripts/verify.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Rodar todas as suítes**

Run: `sh scripts/verify.sh`
Expected: `verify: OK`.

- [ ] **Step 6: Commit**

```bash
git add mecanismos/scripts/verify.sh mecanismos/scripts/verify.Tests.sh
git commit -m "feat(mecanismos): verify como ponto único com lock"
```

---

### Task 10: Núcleo — princípios e ciclo

**Files:**
- Create: `core/principios.md`
- Create: `core/processo/ciclo.md`

**Interfaces:**
- Produces: documentos referenciados pelos papéis (Task 11), pelo `AGENTS.md` (Task 12) e pelos comandos (Task 13) nos caminhos de destino `docs/agentic/principios.md` e `docs/agentic/ciclo.md`.

- [ ] **Step 1: Escrever `core/principios.md`**

````markdown
# Princípios do SDLC agêntico

Estes princípios regem todo papel, artefato e mecanismo. Cada um diz **por que existe** e **como é verificado**. Regra sem verificação mecânica é declarada como "por revisão" — nunca descrita como garantida.

## 1. Prompt orienta, mecanismo controla
Instrução escrita é orientação; só um mecanismo determinístico consegue dizer "não". Toda regra do processo declara `Verificado por:` com o mecanismo que a garante ou com "por revisão".
**Por quê:** agentes seguem prompts na maior parte do tempo, não sempre. Uma regra que só existe em texto falha justamente quando mais importa.
**Verificado por:** revisão (o `revisor` rejeita regra nova sem `Verificado por:`).

## 2. Erro repetido duas vezes vira mecanismo
Quando o mesmo erro acontece pela segunda vez, a correção é um controle mecânico (hook, script, teste, permissão) — não uma terceira instrução em prosa. Controle que nunca pega nada é candidato a remoção.
**Por quê:** reforçar texto que já falhou não muda o resultado; e controle inútil é cerimônia que custa tempo de toda execução.
**Verificado por:** revisão.

## 3. Estado é derivado, nunca escrito à mão
O estado do projeto (o que está em andamento, o que foi aprovado) vem do git e dos campos `**Status:**` dos artefatos. É exibido no início de cada sessão por `scripts/agentic/status-projeto.sh`. Números (contagens, totais) são gerados por script.
**Por quê:** estado escrito à mão envelhece em um dia e passa a mentir para a próxima sessão.
**Verificado por:** `status-projeto.sh` (hook de início de sessão).

## 4. Afirmações técnicas são medidas ou inferidas
Toda afirmação sobre comportamento do sistema é marcada `medido` (há saída/execução que comprova) ou `inferido` (dedução ainda não comprovada). Nada é declarado funcionando sem a saída vista.
**Por quê:** a confiança do agente não é evidência; inferências promovidas a fatos sem medição viram defeitos difíceis de rastrear.
**Verificado por:** `verify.sh` para o que é testável; revisão para o resto.

## 5. O agente nunca integra e nunca altera as próprias permissões
Merge na branch principal e permissões do agente pertencem ao humano.
**Por quê:** o ponto de integração é onde o humano responde pela decisão; um agente que amplia as próprias permissões elimina o controle que deveria limitá-lo.
**Verificado por:** `deny` de `gh pr merge` e de edição de `.claude/settings*.json`, `.agentic/config`, `.githooks/**`; `pre-push` e `pre-merge-commit` bloqueiam a branch protegida.

## 6. Memória enxuta
`AGENTS.md` e `CLAUDE.md` são mapa e regras. Narrativa de ciclo vai para documentos datados; decisões vão para `docs/decisoes.md`.
**Por quê:** memória que vira changelog consome contexto a cada sessão e acumula contradições.
**Verificado por:** revisão.

## 7. Erros pequenos, visíveis e reversíveis
Cada sessão trabalha num worktree isolado; tasks têm escopo declarado; descartar uma execução ruim deve ser barato.
**Por quê:** todo commit de agente é tratado como não confiável até o repositório dar motivo para confiar.
**Verificado por:** `verifica-escopo.sh` (escopo); revisão (isolamento por worktree).
````

- [ ] **Step 2: Escrever `core/processo/ciclo.md`**

````markdown
# Ciclo de desenvolvimento agêntico

Leia antes de qualquer trabalho. Princípios: `docs/agentic/principios.md`. Papéis: `docs/agentic/papeis/`.

## Escolha a trilha

- **Trilha padrão** — funcionalidade nova ou qualquer mudança de comportamento observável.
- **Trilha rápida** — `chore`, `docs`, ferramental, correção sem mudança de comportamento: branch → `verify` → PR → Gate 2.

Na dúvida, trilha padrão.

## Trilha padrão

| # | Fase | Papel | Artefato | Verificação |
|---|---|---|---|---|
| 0 | Intenção | humano + `dominio` | `intent/NNN-<nome>.md` | — |
| 1 | Especificação | `dominio` | `docs/specs/<nome>/spec.md` + questionário de decisão | `revisor` modo `spec` |
| 2 | Design | `arquiteto` | `design.md` + contrato executável + `tasks/NNN-<nome>.md` | `revisor` modo `design` |
| G1 | **Gate 1** | humano | aprova intent + spec + design; responde o questionário | — |
| 3 | RED | `testes` | testes falhando, só em diretórios de teste; commit `test(red): …` | `verifica-red.sh` |
| 4 | GREEN + REFACTOR | `dev` | commits `feat(green): …` e `refactor: …` | `verify.sh` |
| 5 | Revisão | `revisor` modo `diff` | parecer com achados Crítico / Importante / Menor | — |
| 6 | Publicação | orquestrador | push + PR pelo template `docs/agentic/templates/pr.md` | — |
| G2 | **Gate 2** | humano | merge **sem squash** (preserva a evidência RED/GREEN) | merge negado ao agente |

- Achado **Crítico** ou **Importante** devolve o trabalho ao papel autor; a revisão roda de novo no diff corrigido.
- Achados **Menores** ficam registrados e são tratados na revisão final da branch, antes da publicação.
- **Gate 1 não aceita hipótese:** toda regra da spec chega ao Gate 1 com estado `confirmada`. O questionário de decisão existe para que o humano resolva todas as dúvidas de uma vez, antes da implementação.

## Escalonamento N3

Pare a execução e chame o humano — mesmo fora de um gate — quando a mudança envolver:
- contrato público (API, schema publicado, formato de arquivo consumido por terceiros);
- segurança, autenticação ou autorização;
- migração destrutiva de dados;
- dependência nova;
- caminho protegido;
- qualquer gatilho adicional listado em `AGENTS.md` (seção "Gatilhos de escalonamento").

`Verificado por:` revisão. Nenhum mecanismo impede o agente de seguir sem escalar — esta é uma limitação declarada.

## Regras de fluxo

- **Isolamento:** um worktree por sessão/trilha (`git worktree add ../<repo>-<branch> -b <branch>`). Nunca duas sessões no mesmo diretório. Subagentes recebem caminhos absolutos do worktree.
- **Escopo:** cada task declara `## Arquivos`. `verify.sh` falha se a branch tocar arquivo fora da lista. Ampliar o escopo exige atualizar a lista num commit `docs(task): …` — visível na revisão e no Gate 2.
- **Divergência spec × código:** pare, registre em "Questões em aberto" da spec e corrija via commit `docs(spec): …` no mesmo PR.
- **Verificação:** `sh scripts/agentic/verify.sh` é o ponto único. Ninguém afirma sucesso sem ter visto a saída.
- **Commits:** `test(red):`, `feat(green):`, `refactor:`, `fix:`, `docs(spec):`, `docs(task):`, `chore:`. Um commit por passo do ciclo.
- **Modo automático:** se `.agentic/auto-mode` contém `enabled: true`, o orquestrador encadeia tasks e publica PRs sem pedir confirmação. Nunca faz merge.

## Orquestração

O orquestrador é a sessão principal — não é um papel. Ele:
1. lê `status-projeto` (injetado no início da sessão) e escolhe a próxima task;
2. cria o worktree e o registro de execução em `.agentic/execucao/<AAAA-MM-DD>-<nome>/`:
   - `progress.md` — task atual, SHA base, próximo passo (permite retomar uma sessão interrompida);
   - `task-N-brief.md` — o que o papel recebe (task, contrato, caminhos absolutos, comandos);
   - `task-N-relatorio.md` — o que o papel devolveu (`FEITO` / `FEITO_COM_RESSALVAS` / `BLOQUEADO`) e o parecer do revisor;
3. despacha cada papel com o brief; nunca implementa ele mesmo;
4. registra uma **Ruling** em `progress.md` sempre que decide algo não previsto no plano (o quê, por quê, alternativa descartada);
5. escolhe o modelo por tipo de trabalho: forte para `arquiteto` e `revisor`; médio para `dominio`, `testes`, `dev`; leve quando o brief já contém o código completo (transcrição).

## Interfaces para versões futuras (não implementadas)

- **Incidente → intent:** um incidente gera `intent/NNN-<nome>.md` com `Origem: incidente <id>`.
- **Release:** um gate de release consome as evidências do PR (RED/GREEN, saída do `verify`, parecer do revisor).
````

- [ ] **Step 3: Conferir referências cruzadas**

Run: `grep -o 'docs/agentic/[a-z/._-]*' core/principios.md core/processo/ciclo.md | sort -u`
Expected: somente `docs/agentic/papeis/`, `docs/agentic/principios.md`, `docs/agentic/templates/pr.md` — todos existirão no projeto alvo após a Task 14.

- [ ] **Step 4: Commit**

```bash
git add core/principios.md core/processo/ciclo.md
git commit -m "docs(core): princípios e ciclo do SDLC agêntico"
```

---

### Task 11: Núcleo — contratos dos papéis

**Files:**
- Create: `core/papeis/dominio.md`, `core/papeis/arquiteto.md`, `core/papeis/testes.md`, `core/papeis/dev.md`, `core/papeis/revisor.md`, `core/papeis/_oraculo.md`

**Interfaces:**
- Consumes: `ciclo.md` e `principios.md` (Task 10).
- Produces: contratos com seções fixas `## Quem você é`, `## Consome`, `## Produz`, `## Nunca faz`, `## Independência`, `## Ao terminar`, `## Contexto da stack`; o último contém o placeholder `{{CONTEXTO_STACK}}` preenchido no `/bootstrap`. `_oraculo.md` usa `{{NOME_ORACULO}}`, `{{FONTE_ORACULO}}`, `{{ACESSO_ORACULO}}`.

- [ ] **Step 1: `core/papeis/dominio.md`**

````markdown
# Papel: dominio

## Quem você é
Analista de negócio. Transforma a intenção de uma pessoa num documento que a engenharia consegue executar sem adivinhar. Você pergunta como um analista experiente: escopo, usuários, restrições, critério de sucesso. Você não decide como construir.

## Consome
- O pedido do humano (conversa, ticket, incidente).
- Oráculos do projeto (somente leitura) para regras existentes.
- `docs/agentic/templates/intent.md` e `docs/agentic/templates/spec.md`.

## Produz
- `intent/NNN-<nome>.md` (Fase 0) a partir da entrevista, com `**Status:** draft`.
- `docs/specs/<nome>/spec.md` (Fase 1): cada regra com `Fonte:` (`humano:<data>`, `oráculo:<arquivo:linha>`, `decisão:D<n>`) e estado `confirmada` ou `hipótese`.
- **Questionário de decisão** no fim da spec: toda `hipótese` vira uma pergunta objetiva, com opções e a sua recomendação, para o humano responder de uma vez no Gate 1.

## Nunca faz
- Sugerir stack, arquitetura ou nomes de classes.
- Promover `hipótese` a `confirmada` sem fonte.
- Escrever código ou testes.

## Independência
Quando a fonte é um oráculo, cite `arquivo:linha`. Quando o comportamento legado parecer errado, registre as duas versões (legado × proposta) e leve ao questionário — não escolha sozinho.

## Ao terminar
Entregue ao orquestrador: caminho dos artefatos, número de regras `confirmada` × `hipótese`, perguntas do questionário. O próximo passo é o `revisor` em modo `spec`.

## Contexto da stack
{{CONTEXTO_STACK}}
````

- [ ] **Step 2: `core/papeis/arquiteto.md`**

````markdown
# Papel: arquiteto

## Quem você é
Arquiteto responsável por tornar a spec construível. Você decide estrutura, fronteiras e contratos — e prova que o desenho fecha antes de qualquer teste ser escrito. É o único dono das tasks.

## Consome
- `spec.md` revisada.
- `docs/decisoes.md` (decisões vigentes; nunca contradiga uma sem registrar a revogação).
- `docs/agentic/templates/design.md` e `docs/agentic/templates/task.md`.

## Produz
- `docs/specs/<nome>/design.md`: decisões numeradas, o que não muda, "o desconfortável, declarado".
- **Contrato executável:** interfaces, tipos, esqueletos, schemas ou rotas que compilam/validam com o comando da stack. Rode a validação e registre a saída no design (`medido`).
- `docs/specs/<nome>/tasks/NNN-<nome>.md`: cada task com `**Branch:**`, `## Arquivos` (escopo exato, globs permitidos), interfaces produzidas/consumidas e critérios de pronto.
- Novas entradas em `docs/decisoes.md` quando uma decisão vale além desta spec.

## Nunca faz
- Alterar regra de negócio da spec (divergência vira pergunta ao `dominio`/humano).
- Escrever implementação além do contrato executável.
- Criar task cujo escopo não cabe numa revisão atenta.

## Independência
Decisão sem `Verificado por:` é marcada "por revisão". Se uma regra de arquitetura atrapalha, o problema costuma estar no lugar do código, não na regra — não a relaxe sem decisão registrada.

## Ao terminar
Entregue: caminho do design, saída da validação do contrato, lista de tasks com escopo. O próximo passo é o `revisor` em modo `design`, depois o Gate 1.

## Contexto da stack
{{CONTEXTO_STACK}}
````

- [ ] **Step 3: `core/papeis/testes.md`**

````markdown
# Papel: testes

## Quem você é
Engenheiro de testes. Você traduz os critérios de aceite de uma task em testes que falham pelo motivo certo. O seu commit é a evidência de que o comportamento ainda não existia.

## Consome
- A task (`## Arquivos`, critérios de pronto) e o contrato executável.
- A spec (regras e critérios de aceite).

## Produz
- Testes **somente** nos diretórios de teste do projeto.
- Um commit `test(red): <o que é testado>` com os testes falhando pelo motivo esperado (asserção, não erro de compilação/importação — salvo quando a ausência do símbolo é o próprio comportamento testado).

## Nunca faz
- Tocar em código de produção (o `verifica-red.sh` bloqueia).
- Criar fixtures ou arquivos de dados redundantes (reaproveite os existentes).
- Escrever teste que não pode falhar: um teste que passa em qualquer implementação não é evidência.

## Independência
Rode os testes e confira a falha antes do commit (`medido`). Se um critério de aceite não é testável como escrito, devolva ao orquestrador como `BLOQUEADO` com a pergunta.

## Ao terminar
Entregue: SHA do commit RED, saída da execução mostrando a falha, mapa critério de aceite → teste.

## Contexto da stack
{{CONTEXTO_STACK}}
````

- [ ] **Step 4: `core/papeis/dev.md`**

````markdown
# Papel: dev

## Quem você é
Desenvolvedor. Você faz os testes do RED passarem com a implementação mais simples que respeita o design, e depois melhora o código sem mudar comportamento.

## Consome
- A task, o design e o contrato executável.
- O commit RED (os testes são a especificação executável).

## Produz
- Commit `feat(green): …` — testes do RED passando.
- Commit(s) `refactor: …` — melhoria sem mudança de comportamento, testes continuam passando.
- Saída do `sh scripts/agentic/verify.sh` verde.

## Nunca faz
- Alterar, apagar ou desabilitar testes do RED (o `verifica-red.sh` compara asserções; o `verifica-skip.sh` bloqueia desabilitação).
- Tocar arquivo fora de `## Arquivos` da task sem atualizar a lista num commit `docs(task): …` justificado.
- Adicionar dependência nova sem escalonamento N3.

## Independência
Se o teste do RED parecer errado, não o "conserte": reporte `BLOQUEADO` com o motivo. Se a spec divergir do que o código precisa, siga a regra de divergência do ciclo.

## Ao terminar
Entregue: SHAs dos commits, saída completa do `verify.sh`, status `FEITO` / `FEITO_COM_RESSALVAS` (com as ressalvas) / `BLOQUEADO` (com o motivo).

## Contexto da stack
{{CONTEXTO_STACK}}
````

- [ ] **Step 5: `core/papeis/revisor.md`**

````markdown
# Papel: revisor

## Quem você é
Revisor independente, em contexto limpo. Você não escreveu o que revisa e não conserta o que encontra: o seu produto é um parecer que outro papel consegue executar.

## Modos
- **`spec`** — abre cada `Fonte:` citada; confere estado `confirmada`/`hipótese`; procura regra sem critério de aceite verificável, ambiguidade e escopo vazando.
- **`design`** — ataca o desenho: o contrato valida de fato? As tasks cobrem a spec? Algum escopo de task está largo demais? Decisões sem `Verificado por:`?
- **`diff`** — revisa o intervalo de commits da task: correção, segurança, aderência ao design, testes que realmente provam o comportamento. Rode o `verify.sh` você mesmo — não confie no relatório do autor.

## Consome
- O artefato ou o intervalo de SHAs a revisar, a task/spec/design de referência.

## Produz
- Parecer com achados classificados:
  - **Crítico** — quebra comportamento, segurança ou dados; bloqueia.
  - **Importante** — defeito real ou desvio do design; bloqueia.
  - **Menor** — melhoria; registrada para a revisão final da branch.
- Cada achado com `arquivo:linha`, o problema, e a evidência (`medido` ou `inferido`).

## Nunca faz
- Editar arquivos (você não tem ferramenta de escrita).
- Revisar algo que você mesmo produziu.
- Aprovar sem ter aberto as citações e rodado a verificação.

## Ao terminar
Entregue o parecer e o veredito: `APROVADO` ou `DEVOLVIDO` (com a lista de Críticos/Importantes).

## Contexto da stack
{{CONTEXTO_STACK}}
````

- [ ] **Step 6: `core/papeis/_oraculo.md`**

````markdown
# Papel: oraculo-{{NOME_ORACULO}}

## Quem você é
Especialista somente leitura em **{{FONTE_ORACULO}}**. Outros papéis consultam você para saber como algo funciona hoje — você devolve conclusões, não despejos de conteúdo.

## Como acessar a fonte
{{ACESSO_ORACULO}}

## Consome
- Uma pergunta objetiva de outro papel.

## Produz
- Resposta curta com citações `arquivo:linha` (ou referência equivalente da fonte).
- Para cada comportamento encontrado, um juízo: **preservar** (regra de negócio válida) ou **corrigir** (defeito do legado), com o motivo.
- Marcação `medido` (lido/executado) ou `inferido` em cada afirmação.

## Nunca faz
- Escrever, editar ou executar qualquer coisa que altere estado.
- Responder sem citação.

## Ao terminar
Entregue a resposta ao papel que perguntou.
````

- [ ] **Step 7: Conferir seções fixas**

Run: `for f in core/papeis/dominio.md core/papeis/arquiteto.md core/papeis/testes.md core/papeis/dev.md core/papeis/revisor.md; do for s in "Quem você é" "Consome" "Produz" "Nunca faz" "Ao terminar" "Contexto da stack"; do grep -q "^## $s" "$f" || echo "FALTA $s em $f"; done; done; grep -L '{{CONTEXTO_STACK}}' core/papeis/[a-z]*.md`
Expected: nenhuma saída. (`revisor.md` usa `## Modos` no lugar de `## Independência`; `dominio`, `arquiteto`, `testes`, `dev` têm `## Independência`.)

- [ ] **Step 8: Commit**

```bash
git add core/papeis/
git commit -m "docs(core): contratos portáveis dos cinco papéis e do oráculo"
```

---

### Task 12: Núcleo — templates de artefatos

**Files:**
- Create: `core/templates/intent.md`, `core/templates/spec.md`, `core/templates/design.md`, `core/templates/task.md`, `core/templates/decisoes.md`, `core/templates/pr.md`, `core/templates/AGENTS.md`

**Interfaces:**
- Produces: templates com `**Status:**` (lido por `status-projeto.sh`), `**Branch:**` e `## Arquivos` na task (lidos por `verify.sh`/`verifica-escopo.sh`). `AGENTS.md` com placeholders `{{VISAO_GERAL}}`, `{{CMD_INSTALAR}}`, `{{CMD_BUILD}}`, `{{CMD_LINT}}`, `{{CMD_TESTE}}`, `{{CMD_ARQUITETURA}}`, `{{REGRAS_INVIOLAVEIS}}`, `{{ESTRUTURA}}`, `{{GATILHOS_N3_STACK}}`, `{{ORACULOS}}`.

- [ ] **Step 1: `core/templates/intent.md`**

````markdown
# Intent: <nome curto>

**Autor:** <pessoa que teve a ideia>
**Sponsor:** <quem responde pelo resultado>
**Data:** <AAAA-MM-DD>
**Status:** draft
**Origem:** <ideia | ticket <id> | incidente <id>>

## Problema
<o que dói hoje, para quem, com números quando houver>

## Resultado proposto
<como fica o mundo quando isto estiver pronto — sem descrever solução técnica>

## Usuários e sistemas afetados
- <usuário/sistema> — <como é afetado>

## Restrições e não-escopo
- Restrição: <prazo, norma, compatibilidade…>
- Fora de escopo: <o que explicitamente não será feito>

## Critérios de aceite de negócio
- <comportamento observável que prova que o resultado foi atingido>

## Questões abertas
- <dúvida que precisa de resposta antes da spec>
````

- [ ] **Step 2: `core/templates/spec.md`**

````markdown
# Spec: <nome>

**Intent:** intent/<NNN-nome>.md
**Status:** draft

## Regras
| # | Regra | Fonte | Estado |
|---|---|---|---|
| R1 | <regra de negócio> | <humano:AAAA-MM-DD \| oráculo:arquivo:linha \| decisão:Dn> | <confirmada \| hipótese> |

## Critérios de aceite
- CA1 (R1): <dado … quando … então …>

## Invariantes (o que não muda)
- <comportamento existente que deve permanecer>

## Fora de escopo
- <item>

## Questionário de decisão
1. <pergunta objetiva derivada de uma hipótese> — opções: (a) <…> (b) <…>. Recomendação: <…>, porque <…>.

## Questões em aberto
- <dúvida surgida durante a execução — registrar data e quem resolveu>

## Divergências
- <spec × código ou legado × proposta, com a resolução>
````

- [ ] **Step 3: `core/templates/design.md`**

````markdown
# Design: <nome>

**Spec:** docs/specs/<nome>/spec.md
**Status:** draft

## Decisões
1. <decisão> — **Por quê:** <…> — **Verificado por:** <mecanismo | por revisão>

## Contrato executável
- O que é: <interfaces/tipos/schemas/rotas criados>
- Como se valida: `<comando>`
- Saída da validação (medido):
```
<saída>
```

## Tasks
| Task | Objetivo | Branch |
|---|---|---|
| tasks/001-<nome>.md | <…> | <spec>/001-<nome> |

## Como isso se prova
- <qual teste/verificação demonstra cada critério de aceite>

## O que não muda
- <componentes e comportamentos preservados>

## O desconfortável, declarado
- <risco, limitação ou aposta que o leitor deve conhecer>
````

- [ ] **Step 4: `core/templates/task.md`**

````markdown
# Task <NNN>: <nome>

**Spec:** docs/specs/<nome>/spec.md
**Status:** pendente
**Branch:** <spec>/<NNN>-<nome>

## Objetivo
<uma frase>

## Arquivos
- `<caminho/exato>`
- `<diretorio/*>`

## Interfaces
- Produz: <símbolos, assinaturas, rotas que outras tasks usam>
- Consome: <o que vem de tasks anteriores>

## Critérios de pronto
- <critério de aceite da spec coberto por esta task>
- `sh scripts/agentic/verify.sh` verde

## Questões em aberto
- <…>
````

Valores de `**Status:**` da task: `pendente`, `em-andamento`, `em-revisão`, `publicada`, `integrada`.

- [ ] **Step 5: `core/templates/decisoes.md`**

````markdown
# Registro de decisões

Cada decisão vale para o projeto inteiro até ser revogada. Nunca apague uma decisão: mova-a para "Decisões revogadas" com a data e o motivo.

## Vigentes

### D1 — <título>
- **Decisão:** <…>
- **Por quê:** <…>
- **Consequência:** <…>
- **Verificado por:** <mecanismo | por revisão>
- **Data:** <AAAA-MM-DD>

## Decisões revogadas

<nenhuma>
````

- [ ] **Step 6: `core/templates/pr.md`**

````markdown
## Origem
- Intent: <intent/NNN-nome.md>
- Task: <docs/specs/<nome>/tasks/NNN-nome.md>

## Evidência
- RED: <sha> — saída mostrando a falha (resumo)
- GREEN: <sha>
- `verify.sh`:
```
<últimas linhas da saída, incluindo VERIFY: OK>
```

## Tamanho e sensibilidade
- Arquivos alterados: <n> · Linhas: +<a> −<r>
- Caminhos sensíveis tocados: <nenhum | lista>
- Supressões novas (`agentic:permitir-segredo`, skips no baseline…): <nenhuma | lista com justificativa>

## Parecer do revisor
- Veredito: <APROVADO>
- Achados menores registrados: <lista ou nenhum>

## O que ficou desconfortável
- <…>

> Merge sem squash (preserva a evidência RED/GREEN). O merge é do humano.
````

- [ ] **Step 7: `core/templates/AGENTS.md`**

````markdown
# AGENTS.md

Guia para qualquer agente de IA trabalhando neste repositório. Mapa e regras — o estado do projeto é derivado (`sh scripts/agentic/status-projeto.sh`), nunca escrito aqui.

## Visão geral
{{VISAO_GERAL}}

## Processo
Todo trabalho segue `docs/agentic/ciclo.md`. Princípios em `docs/agentic/principios.md`. Papéis em `docs/agentic/papeis/`.

## Comandos
| Ação | Comando |
|---|---|
| Instalar dependências | `{{CMD_INSTALAR}}` |
| Build | `{{CMD_BUILD}}` |
| Lint | `{{CMD_LINT}}` |
| Testes | `{{CMD_TESTE}}` |
| Arquitetura | `{{CMD_ARQUITETURA}}` |
| **Verificação completa** | `sh scripts/agentic/verify.sh` |

## Regras invioláveis
- Nunca faça merge na branch principal nem altere permissões do agente.
- Nunca afirme sucesso sem ter visto a saída do `verify.sh`.
- Nunca desabilite ou altere testes de um commit `test(red):`.
{{REGRAS_INVIOLAVEIS}}

## Estrutura do repositório
{{ESTRUTURA}}

## Onde ficam os artefatos
- Intents: `intent/`
- Specs, designs e tasks: `docs/specs/<nome>/`
- Decisões: `docs/decisoes.md`
- Respostas do bootstrap: `docs/bootstrap.md`

## Gatilhos de escalonamento (N3)
Além dos gatilhos genéricos de `docs/agentic/ciclo.md`:
{{GATILHOS_N3_STACK}}

## Oráculos
{{ORACULOS}}
````

- [ ] **Step 8: Conferir campos lidos por scripts**

Run: `grep -l '^\*\*Status:\*\*' core/templates/*.md; grep -c '^\*\*Branch:\*\*' core/templates/task.md; grep -c '^## Arquivos' core/templates/task.md`
Expected: `intent.md`, `spec.md`, `design.md`, `task.md` listados; `1`; `1`.

- [ ] **Step 9: Commit**

```bash
git add core/templates/
git commit -m "docs(core): templates de intent, spec, design, task, decisões, PR e AGENTS.md"
```

---

### Task 13: Adaptador Claude Code

**Files:**
- Create: `adapters/claude-code/CLAUDE.md`
- Create: `adapters/claude-code/settings.json.tmpl`
- Create: `adapters/claude-code/hooks/pre-tool-use.sh`
- Test: `adapters/claude-code/hooks/pre-tool-use.Tests.sh`
- Create: `adapters/claude-code/agents/{dominio,arquiteto,testes,dev,revisor,_oraculo}.md`
- Create: `adapters/claude-code/commands/{bootstrap,intent,nova-task,verify,status}.md`
- Create: `mecanismos/scripts/ativar-protecoes.sh`
- Test: `mecanismos/scripts/ativar-protecoes.Tests.sh`

**Interfaces:**
- Consumes: contratos em `docs/agentic/papeis/` (destino da Task 11), `docs/agentic/entrevista.md` (Task 14), scripts das Tasks 5 e 9.
- Produces: `pre-tool-use.sh` lê JSON do stdin e sai 2 (bloqueio do Claude Code) para varredura de disco a partir da raiz (`/`, `~`, `X:/`, `X:\`), 0 caso contrário. `ativar-protecoes.sh` copia `.agentic/settings.pendente.json` para `.claude/settings.json` se este não existir (sai 0); se existir, não sobrescreve e sai 1 com instrução de merge manual.

- [ ] **Step 1: Escrever o teste do hook (falhando)**

`adapters/claude-code/hooks/pre-tool-use.Tests.sh`:
```sh
#!/bin/sh
# Testes do hook PreToolUse mínimo (varredura de disco).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../../../mecanismos/scripts/testlib.sh"

json() { printf '{"tool_name":"Bash","tool_input":{"command":"%s","description":"d"}}' "$1"; }
roda() { json "$1" | sh "$dir/pre-tool-use.sh"; }

tl_espera 2 "bloqueia find /" roda 'find / -name x'
tl_contem "varredura" "explica o bloqueio"
tl_espera 2 "bloqueia grep -r na raiz" roda 'grep -rn senha /'
tl_espera 2 "bloqueia find na raiz de drive" roda 'find C:/ -name x'
tl_espera 2 "bloqueia raiz de drive com barra invertida" roda 'find C:\\ -name x'
tl_espera 2 "bloqueia ls -R no home" roda 'ls -R ~'
tl_espera 0 "permite find no diretório atual" roda 'find . -name x'
tl_espera 0 "permite find em caminho absoluto específico" roda 'find /tmp/x -name y'
tl_espera 0 "permite grep -r num diretório do projeto" roda 'grep -r foo src/'
tl_espera 0 "permite ls não recursivo da raiz" roda 'ls -la /'
tl_espera 0 "permite comandos comuns" roda 'git log --format=%H'

tl_fim
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh adapters/claude-code/hooks/pre-tool-use.Tests.sh`
Expected: `FALHA bloqueia find / (esperado 2, obtido 127)`.

- [ ] **Step 3: Implementar o hook**

`adapters/claude-code/hooks/pre-tool-use.sh`:
```sh
#!/bin/sh
# pre-tool-use.sh — hook PreToolUse (Bash) MÍNIMO de propósito: bloqueia varredura de disco a partir
# da raiz, do home ou de um drive. Proteções de git vivem nos .githooks (valem para qualquer autor);
# interpretar texto de comando para isso é uma corrida que não se ganha.
entrada=$(cat)
padrao='(^|[;&|[:space:]"])(find|du|tree|ls[[:space:]]+-[A-Za-z]*R[A-Za-z]*|grep[[:space:]]+-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]+[^;&|"[:space:]]+)*[[:space:]]+(/|~|[A-Za-z]:(/|\\\\)?)([[:space:]";&|]|$)'
if printf '%s' "$entrada" | grep -qE "$padrao"; then
  echo "agentic: BLOQUEADO — varredura de disco a partir da raiz/home/drive. Restrinja a busca ao repositório ou a um caminho específico." >&2
  exit 2
fi
exit 0
```

- [ ] **Step 4: Rodar e ver passar**

Run: `sh adapters/claude-code/hooks/pre-tool-use.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 5: Escrever o teste do `ativar-protecoes.sh` (falhando)**

`mecanismos/scripts/ativar-protecoes.Tests.sh`:
```sh
#!/bin/sh
# Testes do ativar-protecoes.sh (ação humana que instala o settings.json).
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(tl_repo); mkdir -p "$r/.agentic"; echo '{"x":1}' > "$r/.agentic/settings.pendente.json"
tl_espera 0 "instala settings quando não existe" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_espera 0 "conteúdo copiado" grep -q '"x":1' "$r/.claude/settings.json"

r=$(tl_repo); mkdir -p "$r/.agentic" "$r/.claude"
echo '{"x":1}' > "$r/.agentic/settings.pendente.json"; echo '{"meu":true}' > "$r/.claude/settings.json"
tl_espera 1 "não sobrescreve settings existente" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"
tl_contem "merge" "orienta o merge manual"
tl_espera 0 "settings original preservado" grep -q '"meu":true' "$r/.claude/settings.json"

r=$(tl_repo)
tl_espera 1 "falha sem settings pendente" sh -c "cd '$r' && sh '$dir/ativar-protecoes.sh'"

tl_fim
```

- [ ] **Step 6: Implementar `ativar-protecoes.sh`**

`mecanismos/scripts/ativar-protecoes.sh`:
```sh
#!/bin/sh
# ativar-protecoes.sh — AÇÃO HUMANA: instala .agentic/settings.pendente.json como .claude/settings.json.
# Permissões do agente pertencem ao humano (princípio 5); por isso o agente não faz este passo.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
[ -f .agentic/settings.pendente.json ] || { echo "Não há .agentic/settings.pendente.json (rode bootstrap/instalar.sh)."; exit 1; }
if [ -f .claude/settings.json ]; then
  echo "Já existe .claude/settings.json — não sobrescrito."
  echo "Faça o merge manual de .agentic/settings.pendente.json (permissions.deny, hooks, enabledPlugins) e rode de novo depois de remover o pendente."
  exit 1
fi
mkdir -p .claude
cp .agentic/settings.pendente.json .claude/settings.json
echo "Proteções ativadas em .claude/settings.json. Reinicie a sessão do Claude Code."
```

- [ ] **Step 7: Rodar e ver passar**

Run: `sh mecanismos/scripts/ativar-protecoes.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 8: `adapters/claude-code/settings.json.tmpl`**

```json
{
  "permissions": {
    "allow": [
      "Bash(sh scripts/agentic/verify.sh:*)",
      "Bash(sh scripts/agentic/status-projeto.sh:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git worktree:*)",
      "Bash(git push:*)",
      "Bash(gh pr create:*)",
      "Bash(gh pr view:*)"
    ],
    "deny": [
      "Bash(gh pr merge:*)",
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git push --force-with-lease:*)",
      "Bash(git push --no-verify:*)",
      "Bash(git commit --no-verify:*)",
      "Bash(git commit -n:*)",
      "Bash(git reset --hard:*)",
      "Bash(git config core.hooksPath:*)",
      "Bash(sh scripts/agentic/ativar-protecoes.sh:*)",
      "Edit(.claude/settings.json)",
      "Write(.claude/settings.json)",
      "Edit(.claude/settings.local.json)",
      "Write(.claude/settings.local.json)",
      "Edit(.claude/hooks/**)",
      "Write(.claude/hooks/**)",
      "Edit(.agentic/config)",
      "Write(.agentic/config)",
      "Edit(.agentic/auto-mode)",
      "Write(.agentic/auto-mode)",
      "Edit(.githooks/**)",
      "Write(.githooks/**)"
    ],
    "disableBypassPermissionsMode": "disable"
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": false
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "sh \"$CLAUDE_PROJECT_DIR/scripts/agentic/status-projeto.sh\"" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "sh \"$CLAUDE_PROJECT_DIR/.claude/hooks/pre-tool-use.sh\"" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 9: Validar o JSON**

Run: `node -e "JSON.parse(require('fs').readFileSync('adapters/claude-code/settings.json.tmpl','utf8')); console.log('json ok')"`
Expected: `json ok`.

- [ ] **Step 10: `adapters/claude-code/CLAUDE.md`**

```markdown
# CLAUDE.md

Leia `AGENTS.md` — é a fonte de verdade para qualquer agente neste repositório.

Específico do Claude Code:
- Papéis em `.claude/agents/` são adaptadores finos de `docs/agentic/papeis/`; a regra vive no contrato, não aqui.
- Comandos: `/intent`, `/nova-task`, `/verify`, `/status`, `/bootstrap`.
- O estado do projeto é injetado no início da sessão por `scripts/agentic/status-projeto.sh`; não o reescreva aqui.
- Plugins de processo (por exemplo, superpowers) ficam desligados: o processo deste projeto é `docs/agentic/ciclo.md`.
```

- [ ] **Step 11: Agentes (adaptadores finos)**

`adapters/claude-code/agents/dominio.md`:
```markdown
---
name: dominio
description: Analista de negócio — conduz a entrevista de intenção e escreve intent.md e spec.md com fonte e estado por regra. Use nas fases 0 e 1 do ciclo.
tools: Read, Grep, Glob, Write, Edit
model: sonnet
---
Leia `docs/agentic/papeis/dominio.md` e siga-o integralmente. Não duplique regras aqui.
```

`adapters/claude-code/agents/arquiteto.md`:
```markdown
---
name: arquiteto
description: Arquiteto — produz design.md, contrato executável e tasks com escopo de arquivos. Use na fase 2 do ciclo.
tools: Read, Grep, Glob, Write, Edit, Bash
model: opus
---
Leia `docs/agentic/papeis/arquiteto.md` e siga-o integralmente. Não duplique regras aqui.
```

`adapters/claude-code/agents/testes.md`:
```markdown
---
name: testes
description: Engenheiro de testes — escreve os testes RED de uma task, só em diretórios de teste. Use na fase 3 do ciclo.
tools: Read, Grep, Glob, Write, Edit, Bash
model: sonnet
---
Leia `docs/agentic/papeis/testes.md` e siga-o integralmente. Não duplique regras aqui.
```

`adapters/claude-code/agents/dev.md`:
```markdown
---
name: dev
description: Desenvolvedor — faz GREEN e REFACTOR dentro do escopo da task. Use na fase 4 do ciclo.
tools: Read, Grep, Glob, Write, Edit, Bash
model: sonnet
---
Leia `docs/agentic/papeis/dev.md` e siga-o integralmente. Não duplique regras aqui.
```

`adapters/claude-code/agents/revisor.md`:
```markdown
---
name: revisor
description: Revisor independente em contexto limpo — modos spec, design e diff; produz parecer, nunca corrige. Use após as fases 1, 2 e 4.
tools: Read, Grep, Glob, Bash
model: opus
---
Leia `docs/agentic/papeis/revisor.md` e siga-o integralmente. O modo vem no seu brief. Não duplique regras aqui.
```

`adapters/claude-code/agents/_oraculo.md`:
```markdown
---
name: oraculo-{{NOME_ORACULO}}
description: Oráculo somente leitura sobre {{FONTE_ORACULO}} — responde com citações e juízo preservar/corrigir.
tools: Read, Grep, Glob
model: sonnet
---
Leia `docs/agentic/papeis/oraculo-{{NOME_ORACULO}}.md` e siga-o integralmente. Não duplique regras aqui.
```

- [ ] **Step 12: Comandos**

`adapters/claude-code/commands/bootstrap.md`:
```markdown
---
description: Entrevista o profissional sobre contexto e stack e instancia o framework agêntico neste projeto.
---
Siga `docs/agentic/entrevista.md` do início ao fim. Argumentos opcionais: $ARGUMENTS
```

`adapters/claude-code/commands/intent.md`:
```markdown
---
description: Inicia a Fase 0 — captura uma ideia, ticket ou incidente como intent.md.
---
Despache o subagente `dominio` para conduzir a entrevista de intenção com o humano sobre: $ARGUMENTS

Ele deve usar `docs/agentic/templates/intent.md` e gravar `intent/NNN-<nome>.md` com `**Status:** draft` (NNN = próximo número livre em `intent/`). Ao final, mostre o caminho e pergunte se o humano aprova o intent para seguir à especificação (`docs/agentic/ciclo.md`).
```

`adapters/claude-code/commands/nova-task.md`:
```markdown
---
description: Inicia a execução de uma task aprovada no Gate 1 (RED → GREEN → revisão → PR).
---
Task: $ARGUMENTS

1. Confira que a spec e o design da task estão com `**Status:** aprovado`. Se não, pare e diga o que falta.
2. Leia o `**Branch:**` da task e crie o worktree: `git worktree add ../<repo>-<branch> -b <branch>` (use o nome da pasta do repositório em `<repo>`).
3. Crie `.agentic/execucao/<AAAA-MM-DD>-<nome>/progress.md` com a task, o SHA base e o próximo passo.
4. Conduza as fases 3 a 6 de `docs/agentic/ciclo.md` como orquestrador: despache `testes`, depois `dev`, depois `revisor` (modo `diff`), sempre com caminhos absolutos do worktree no brief. Registre brief, relatório e Rulings no diretório de execução.
5. Se `.agentic/auto-mode` contém `enabled: true`, publique o PR sem pedir confirmação; caso contrário, pergunte antes do push. Nunca faça merge.
```

`adapters/claude-code/commands/verify.md`:
```markdown
---
description: Roda a verificação completa do projeto e reporta. Nunca conserta.
---
Rode `sh scripts/agentic/verify.sh $ARGUMENTS` e reporte a saída: etapas que passaram, etapas que falharam e as mensagens relevantes.

Não conserte nada neste comando — reportar é o trabalho. Nunca afirme sucesso sem ter visto `VERIFY: OK` na saída.
```

`adapters/claude-code/commands/status.md`:
```markdown
---
description: Mostra o estado derivado do projeto (branches, worktrees, artefatos, modo automático).
---
Rode `sh scripts/agentic/status-projeto.sh` e apresente o resultado. Se houver task `em-andamento`, aponte o próximo passo segundo `docs/agentic/ciclo.md`.
```

- [ ] **Step 13: Rodar todas as suítes**

Run: `sh scripts/verify.sh`
Expected: `verify: OK`.

- [ ] **Step 14: Commit**

```bash
git add adapters/ mecanismos/scripts/ativar-protecoes.sh mecanismos/scripts/ativar-protecoes.Tests.sh
git commit -m "feat(adapter): adaptador Claude Code — agentes, comandos, hooks e settings"
```

---

### Task 14: Bootstrap — instalador, entrevista e checagem

**Files:**
- Create: `bootstrap/config.padrao`
- Create: `bootstrap/auto-mode.padrao`
- Create: `bootstrap/instalar.sh`
- Test: `bootstrap/instalar.Tests.sh`
- Create: `bootstrap/checa-instancia.sh`
- Test: `bootstrap/checa-instancia.Tests.sh`
- Create: `bootstrap/entrevista.md`

**Interfaces:**
- Consumes: todo o kit (Tasks 1–13).
- Produces: `instalar.sh <alvo>` — sai 2 em uso incorreto/alvo não-git; 0 após copiar conforme o mapeamento, sem sobrescrever (conflitos em `.agentic/conflitos-instalacao.txt`), acrescentar `.gitignore`/`.gitattributes` e configurar `core.hooksPath`. `checa-instancia.sh <alvo>` — sai 0 se a instância está completa (arquivos obrigatórios, nenhum `{{` fora dos templates, hooksPath, `CMD_VERIFY_STACK`/`CMD_TESTE` preenchidos, `.claude/settings.json` ativo, `verify.sh` executável até o fim); sai 1 listando cada problema.

**Mapeamento (origem no framework → destino no projeto):**

| Origem | Destino |
|---|---|
| `core/principios.md` | `docs/agentic/principios.md` |
| `core/processo/ciclo.md` | `docs/agentic/ciclo.md` |
| `core/papeis/*` | `docs/agentic/papeis/*` |
| `core/templates/*` | `docs/agentic/templates/*` |
| `core/templates/AGENTS.md` | `AGENTS.md` |
| `bootstrap/entrevista.md` | `docs/agentic/entrevista.md` |
| `mecanismos/githooks/*` | `.githooks/*` |
| `mecanismos/scripts/*` | `scripts/agentic/*` |
| `adapters/claude-code/agents/*` | `.claude/agents/*` |
| `adapters/claude-code/commands/*` | `.claude/commands/*` |
| `adapters/claude-code/hooks/*` | `.claude/hooks/*` |
| `adapters/claude-code/CLAUDE.md` | `CLAUDE.md` |
| `adapters/claude-code/settings.json.tmpl` | `.agentic/settings.pendente.json` |
| `bootstrap/config.padrao` | `.agentic/config` |
| `bootstrap/auto-mode.padrao` | `.agentic/auto-mode` |

Nota: os `.Tests.sh` dos githooks referenciam `../scripts/testlib.sh` (layout do framework); no projeto o caminho equivalente é `../scripts/agentic/testlib.sh`. Os testes são do framework — no projeto alvo eles viajam como documentação executável, mas a suíte oficial é a do framework. Isso é declarado em `docs/agentic/entrevista.md` (passo final).

- [ ] **Step 1: `bootstrap/config.padrao`**

```sh
# .agentic/config — configuração dos mecanismos do framework. Preenchida no /bootstrap.
# Superfície de política: depois de ativadas as proteções, o agente não edita este arquivo.
BRANCH_PRINCIPAL="main"
BRANCHES_PROTEGIDAS="main master"
# Comando que roda build + lint + testes + arquitetura da stack (usado pelo verify.sh).
CMD_VERIFY_STACK="{{CMD_VERIFY_STACK}}"
# Comando que roda só os testes (usado pelo verifica-red.sh no commit RED).
CMD_TESTE="{{CMD_TESTE}}"
# Preparação necessária num worktree limpo antes de testar (ex.: npm ci). Vazio se não houver.
CMD_PREPARAR_TESTE="{{CMD_PREPARAR_TESTE}}"
# Diretórios de teste, separados por espaço, com barra final.
DIRS_TESTE="{{DIRS_TESTE}}"
# Regex (ERE) que identifica teste desabilitado na stack. Vazio = verificação degradada.
MARCADOR_DESABILITADO="{{MARCADOR_DESABILITADO}}"
# Regex (ERE) que identifica uma asserção nos testes.
MARCADOR_ASSERCAO="{{MARCADOR_ASSERCAO}}"
# Glob dos relatórios JUnit XML gerados pelo CMD_VERIFY_STACK. Vazio = verificação degradada.
RELATORIO_TESTES="{{RELATORIO_TESTES}}"
GITLEAKS_BIN="gitleaks"
```

- [ ] **Step 2: `bootstrap/auto-mode.padrao`**

```
# Modo automático: com enabled: true o orquestrador encadeia tasks e publica PRs sem confirmação.
# Nunca faz merge. Alterar este arquivo é decisão humana.
enabled: false
```

- [ ] **Step 3: Escrever o teste do instalador (falhando)**

`bootstrap/instalar.Tests.sh`:
```sh
#!/bin/sh
# Testes do instalar.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"

r=$(tl_repo)
tl_espera 0 "instala num repositório git" sh "$dir/instalar.sh" "$r"
for f in AGENTS.md CLAUDE.md docs/agentic/ciclo.md docs/agentic/principios.md docs/agentic/entrevista.md \
         docs/agentic/papeis/dev.md docs/agentic/templates/task.md .githooks/pre-commit .githooks/pre-push \
         scripts/agentic/verify.sh scripts/agentic/lib-agentic.sh .claude/agents/revisor.md \
         .claude/commands/bootstrap.md .claude/hooks/pre-tool-use.sh .agentic/config .agentic/auto-mode \
         .agentic/settings.pendente.json; do
  tl_espera 0 "copiou $f" test -f "$r/$f"
done
tl_espera 1 "não instala settings.json direto (ação humana)" test -f "$r/.claude/settings.json"
tl_espera 0 "configura core.hooksPath" sh -c "[ \"\$(git -C '$r' config core.hooksPath)\" = .githooks ]"
tl_espera 0 ".gitignore ignora execucao" grep -qxF ".agentic/execucao/" "$r/.gitignore"
tl_espera 0 ".gitattributes força LF em sh (Review Focus 1)" grep -qF "*.sh text eol=lf" "$r/.gitattributes"
tl_espera 0 ".gitattributes força LF nos githooks" grep -qF ".githooks/* text eol=lf" "$r/.gitattributes"

tl_espera 0 "reinstalar é idempotente" sh "$dir/instalar.sh" "$r"
tl_espera 1 "sem conflitos na reinstalação" test -f "$r/.agentic/conflitos-instalacao.txt"
tl_espera 0 ".gitignore sem linhas duplicadas" sh -c "[ \$(grep -cxF '.agentic/execucao/' '$r/.gitignore') -eq 1 ]"

r=$(tl_repo); echo "meu claude" > "$r/CLAUDE.md"
tl_espera 0 "instala com arquivo pré-existente" sh "$dir/instalar.sh" "$r"
tl_espera 0 "preserva o CLAUDE.md existente" grep -qx "meu claude" "$r/CLAUDE.md"
tl_espera 0 "registra o conflito" grep -qx "CLAUDE.md" "$r/.agentic/conflitos-instalacao.txt"

tl_espera 2 "recusa alvo que não é git" sh "$dir/instalar.sh" "$(mktemp -d)"
tl_espera 2 "recusa sem argumento" sh "$dir/instalar.sh"

tl_fim
```

- [ ] **Step 4: Rodar e ver falhar**

Run: `sh bootstrap/instalar.Tests.sh`
Expected: falhas com código 127.

- [ ] **Step 5: Implementar `instalar.sh`**

`bootstrap/instalar.sh`:
```sh
#!/bin/sh
# instalar.sh <projeto-alvo> — copia o kit do framework para o projeto.
# Não pergunta nada e não sobrescreve nada: conflitos vão para .agentic/conflitos-instalacao.txt
# e são resolvidos no /bootstrap.
fw=$(cd "$(dirname "$0")/.." && pwd)
alvo=${1:-}
{ [ -n "$alvo" ] && [ -d "$alvo" ]; } || { echo "uso: instalar.sh <projeto-alvo>" >&2; exit 2; }
git -C "$alvo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "o alvo não é um repositório git: $alvo" >&2; exit 2; }
alvo=$(cd "$alvo" && pwd)
conflitos=$(mktemp)

copia() { # copia <origem> <destino relativo ao alvo>
  if [ -e "$alvo/$2" ]; then
    cmp -s "$1" "$alvo/$2" || printf '%s\n' "$2" >> "$conflitos"
    return 0
  fi
  mkdir -p "$(dirname "$alvo/$2")"
  cp "$1" "$alvo/$2"
}
copia_dir() { # copia_dir <diretório origem> <diretório destino relativo>
  ( cd "$1" && find . -type f | sed 's|^\./||' ) | while IFS= read -r f; do
    copia "$1/$f" "$2/$f"
  done
}
acrescenta() { # acrescenta <arquivo relativo> <linha> — sem duplicar
  grep -qxF "$2" "$alvo/$1" 2>/dev/null || printf '%s\n' "$2" >> "$alvo/$1"
}

copia "$fw/core/principios.md" docs/agentic/principios.md
copia "$fw/core/processo/ciclo.md" docs/agentic/ciclo.md
copia_dir "$fw/core/papeis" docs/agentic/papeis
copia_dir "$fw/core/templates" docs/agentic/templates
copia "$fw/core/templates/AGENTS.md" AGENTS.md
copia "$fw/bootstrap/entrevista.md" docs/agentic/entrevista.md
copia_dir "$fw/mecanismos/githooks" .githooks
copia_dir "$fw/mecanismos/scripts" scripts/agentic
copia_dir "$fw/adapters/claude-code/agents" .claude/agents
copia_dir "$fw/adapters/claude-code/commands" .claude/commands
copia_dir "$fw/adapters/claude-code/hooks" .claude/hooks
copia "$fw/adapters/claude-code/CLAUDE.md" CLAUDE.md
copia "$fw/adapters/claude-code/settings.json.tmpl" .agentic/settings.pendente.json
copia "$fw/bootstrap/config.padrao" .agentic/config
copia "$fw/bootstrap/auto-mode.padrao" .agentic/auto-mode

acrescenta .gitignore ".agentic/execucao/"
acrescenta .gitignore ".agentic/verify.lock/"
acrescenta .gitattributes "*.sh text eol=lf"
acrescenta .gitattributes ".githooks/* text eol=lf"

git -C "$alvo" config core.hooksPath .githooks

if [ -s "$conflitos" ]; then
  cp "$conflitos" "$alvo/.agentic/conflitos-instalacao.txt"
  echo "Arquivos já existentes e diferentes (NÃO sobrescritos) — listados em .agentic/conflitos-instalacao.txt:"
  sed 's/^/  /' "$conflitos"
fi
rm -f "$conflitos"
echo "Kit instalado em $alvo."
echo "Próximo passo: abra o Claude Code no projeto e rode /bootstrap."
```

- [ ] **Step 6: Rodar e ver passar**

Run: `sh bootstrap/instalar.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 7: Escrever o teste da checagem (falhando)**

`bootstrap/checa-instancia.Tests.sh`:
```sh
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
  -exec sed -i 's/{{[A-Z_]*}}/preenchido/g' {} +
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
tl_espera 0 "instância completa passa" sh "$dir/checa-instancia.sh" "$r"

git -C "$r" config core.hooksPath .outro
tl_espera 1 "detecta hooksPath errado" sh "$dir/checa-instancia.sh" "$r"
tl_contem "core.hooksPath" "aponta o hooksPath"

tl_fim
```

- [ ] **Step 8: Implementar `checa-instancia.sh`**

`bootstrap/checa-instancia.sh`:
```sh
#!/bin/sh
# checa-instancia.sh <projeto> — checagem estrutural de uma instância do framework após o /bootstrap.
alvo=${1:-}
[ -n "$alvo" ] && [ -d "$alvo" ] || { echo "uso: checa-instancia.sh <projeto>" >&2; exit 2; }
cd "$alvo" || exit 2
problemas=0
problema() { echo "PROBLEMA: $*"; problemas=$((problemas + 1)); }

for f in AGENTS.md CLAUDE.md docs/agentic/ciclo.md docs/agentic/principios.md docs/bootstrap.md docs/decisoes.md \
         .agentic/config .agentic/auto-mode .claude/settings.json scripts/agentic/verify.sh .githooks/pre-commit; do
  [ -f "$f" ] || problema "arquivo obrigatório ausente: $f (se for .claude/settings.json: rode sh scripts/agentic/ativar-protecoes.sh)"
done

for p in dominio arquiteto testes dev revisor; do
  [ -f "docs/agentic/papeis/$p.md" ] && [ -f ".claude/agents/$p.md" ] || problema "papel incompleto: $p"
done

restantes=$(grep -rl '{{' AGENTS.md CLAUDE.md docs/agentic/papeis .claude/agents .agentic/config docs/bootstrap.md docs/decisoes.md 2>/dev/null \
  | grep -v '_oraculo.md$')
[ -z "$restantes" ] || problema "placeholders {{...}} não preenchidos em: $(echo $restantes)"

[ "$(git config core.hooksPath)" = ".githooks" ] || problema "core.hooksPath não aponta para .githooks"

if [ -f .agentic/config ]; then
  ( . ./.agentic/config; [ -n "$CMD_VERIFY_STACK" ] && [ -n "$CMD_TESTE" ] ) || problema "CMD_VERIFY_STACK/CMD_TESTE vazios em .agentic/config"
fi

if [ "$problemas" -eq 0 ]; then
  if sh scripts/agentic/verify.sh >/tmp/checa-verify.$$ 2>&1; then
    echo "verify.sh: OK"
  else
    problema "verify.sh falhou (saída abaixo)"
    sed 's/^/  | /' /tmp/checa-verify.$$
  fi
  rm -f /tmp/checa-verify.$$
fi

if [ "$problemas" -eq 0 ]; then echo "INSTÂNCIA: OK"; else echo "INSTÂNCIA: $problemas problema(s)"; exit 1; fi
```

- [ ] **Step 9: Rodar e ver passar**

Run: `sh bootstrap/checa-instancia.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 10: Escrever `bootstrap/entrevista.md`**

````markdown
# Bootstrap: entrevista e instanciação

Você está instanciando o framework de SDLC agêntico neste projeto. **Você nunca escreve código de produto neste processo.** Ao final, o projeto terá agentes e controles específicos do seu contexto.

## Modo de respostas pré-gravadas
Se existir `docs/bootstrap-respostas.md`, use-o como respostas da entrevista: não faça perguntas, só confirme no final o que foi inferido além dele.

## Passo 0 — Pré-condições
1. O repositório tem ao menos um commit? Se não, peça ao humano: `git commit --allow-empty -m "inicial" --no-verify` (ação humana; o agente não usa `--no-verify`).
2. Crie a branch `agentic/bootstrap` (a branch principal é protegida pelos githooks).
3. Leia `.agentic/conflitos-instalacao.txt`, se existir: são arquivos do projeto que o instalador não sobrescreveu.

## Passo 1 — Leitura do projeto (projeto existente)
Antes de perguntar, leia o repositório (manifestos de dependência, configuração de build/teste, estrutura de pastas, CI, README) e prepare respostas propostas marcadas `inferido`. Pergunte só o que não conseguiu inferir; peça confirmação do que inferiu.

## Passo 2 — Entrevista
Pergunte um bloco por vez; prefira múltipla escolha com uma recomendação.

| Bloco | Perguntas |
|---|---|
| Contexto | O que é o produto? Quem usa? Qual o domínio? Projeto novo ou existente? Restrições regulatórias ou de legado? |
| Stack | Linguagens e frameworks? Gerenciador de pacotes? Comandos de instalar, build, lint, testes e verificação de arquitetura? Como a stack marca teste desabilitado? Os testes geram relatório JUnit XML (onde)? O que precisa rodar num checkout limpo antes dos testes? |
| Estrutura | Camadas/módulos e suas fronteiras? Diretórios de teste? Que ferramenta verifica fronteiras (ex.: ArchUnit, dependency-cruiser, import-linter)? |
| Risco | Caminhos protegidos? Gatilhos de escalonamento específicos da stack/domínio? Dependências sensíveis? |
| Fontes externas | Há sistema legado, API externa ou norma que os agentes devem consultar? Onde está e como se acessa (somente leitura)? |
| Operação | Branch principal? Plataforma de PR (GitHub, GitLab, Azure…)? Existe CI? Quem aprova o Gate 1 e o Gate 2? Modo automático começa ligado? |

## Passo 3 — Registro
Grave `docs/bootstrap.md` com todas as respostas, cada uma marcada `confirmado` (humano respondeu/confirmou) ou `inferido`. Re-execuções do `/bootstrap` partem deste arquivo.

## Passo 4 — Instanciação
1. `.agentic/config`: substitua todos os `{{...}}` (valores vazios são permitidos onde o comentário diz "degradado"). Se a stack exigir combinar etapas, `CMD_VERIFY_STACK` pode encadear comandos com `&&`.
2. `AGENTS.md`: preencha todos os `{{...}}`. Em `{{REGRAS_INVIOLAVEIS}}` e `{{GATILHOS_N3_STACK}}` use listas Markdown; sem itens, escreva `- Nenhum além dos genéricos.`
3. `docs/agentic/papeis/{dominio,arquiteto,testes,dev,revisor}.md`: substitua `{{CONTEXTO_STACK}}` por um bloco **específico daquele papel**: comandos que ele usa, convenções da stack relevantes para o trabalho dele, ferramentas. Curto — o contrato já diz o que fazer.
4. Para cada fonte externa: copie `docs/agentic/papeis/_oraculo.md` para `docs/agentic/papeis/oraculo-<nome>.md` e `.claude/agents/_oraculo.md` para `.claude/agents/oraculo-<nome>.md`, preenchendo `{{NOME_ORACULO}}`, `{{FONTE_ORACULO}}`, `{{ACESSO_ORACULO}}`. Liste-os em `{{ORACULOS}}` do `AGENTS.md` (sem oráculos: `- Nenhum.`).
5. `docs/decisoes.md` a partir de `docs/agentic/templates/decisoes.md`, com `D1 — Stack e comandos de verificação` (Verificado por: `verify.sh`) e uma decisão por ferramenta de arquitetura com o mecanismo de baseline dela.
6. Ajuste `.agentic/settings.pendente.json` se a plataforma de PR não for GitHub (troque `gh pr create`/`gh pr view`/`gh pr merge` pelos equivalentes).
7. Se o projeto tem CI: gere o workflow da plataforma chamando `sh scripts/agentic/verify.sh`, e registre em `docs/decisoes.md` que ele só vale depois de **provado verde num PR de teste**.

## Passo 5 — Conflitos
Para cada arquivo em `.agentic/conflitos-instalacao.txt`, mostre ao humano a diferença entre a versão do projeto e a do kit e proponha um merge. Aplique só o que o humano aprovar. Apague o arquivo de conflitos ao terminar.

## Passo 6 — Baseline (projeto existente)
1. Rode os testes; se o relatório já mostra testes pulados, grave a contagem em `.agentic/baseline-skips` e registre em `docs/decisoes.md`.
2. Rode a ferramenta de arquitetura; se houver violações atuais, configure o baseline dela (mecanismo próprio da ferramenta) e registre.

## Passo 7 — Verificação
Rode `sh scripts/agentic/verify.sh`. Deve terminar com `VERIFY: OK`; se não, registre o motivo em `docs/bootstrap.md` (seção "Pendências") — não esconda.

## Passo 8 — Entrega
1. Commit `chore: instancia o framework de SDLC agêntico` na branch `agentic/bootstrap`.
2. Peça ao humano, nesta ordem:
   - ativar as proteções: `sh scripts/agentic/ativar-protecoes.sh` (ação humana — permissões são do humano);
   - integrar a branch (`git merge --ff-only agentic/bootstrap` na principal, ou via PR);
   - reiniciar a sessão do Claude Code.
3. Rode a checagem estrutural se o framework estiver acessível: `sh <framework>/bootstrap/checa-instancia.sh .`
4. Sugira o primeiro intent: `/intent <ideia>`.

Observação: os arquivos `*.Tests.sh` copiados para `.githooks/` e `scripts/agentic/` documentam o comportamento esperado dos mecanismos; a suíte oficial roda no repositório do framework.
````

- [ ] **Step 11: Rodar todas as suítes**

Run: `sh scripts/verify.sh`
Expected: `verify: OK`.

- [ ] **Step 12: Commit**

```bash
git add bootstrap/
git commit -m "feat(bootstrap): instalador, entrevista e checagem estrutural"
```

---

### Task 15: Exemplos, montagem e rastreabilidade

**Files:**
- Create: `exemplos/python-cli-novo/.gitignore`, `exemplos/python-cli-novo/README.md`, `exemplos/python-cli-novo/src/conversor/__init__.py`, `exemplos/python-cli-novo/tests/test_smoke.py`, `exemplos/python-cli-novo/docs/bootstrap-respostas.md`
- Create: `exemplos/node-servico-existente/.gitignore`, `exemplos/node-servico-existente/package.json`, `exemplos/node-servico-existente/src/precos.js`, `exemplos/node-servico-existente/legado/calculo-antigo.js`, `exemplos/node-servico-existente/test/precos.test.js`, `exemplos/node-servico-existente/docs/bootstrap-respostas.md`
- Create: `scripts/montar-exemplo.sh`
- Test: `bootstrap/montar-exemplo.Tests.sh`
- Create: `docs/origem.md`

**Interfaces:**
- Consumes: `instalar.sh` (Task 14).
- Produces: `scripts/montar-exemplo.sh <nome-do-exemplo> <destino>` — copia `exemplos/<nome>` para `<destino>` (que não pode existir), cria repositório git com commit inicial em `main` e roda `instalar.sh`. Sai 2 em uso incorreto.

- [ ] **Step 1: Exemplo Python (projeto novo)**

`exemplos/python-cli-novo/.gitignore` (artefatos gerados não podem aparecer como arquivos fora do escopo no `verifica-escopo.sh`):
```
__pycache__/
```

`exemplos/python-cli-novo/README.md`:
```markdown
# conversor

CLI de conversão de unidades (comprimento e temperatura). Projeto novo — ainda sem funcionalidades.
```

`exemplos/python-cli-novo/src/conversor/__init__.py`:
```python
"""Conversor de unidades."""
```

`exemplos/python-cli-novo/tests/test_smoke.py`:
```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))


class TestSmoke(unittest.TestCase):
    def test_pacote_importa(self):
        import conversor

        self.assertEqual(conversor.__doc__, "Conversor de unidades.")


if __name__ == "__main__":
    unittest.main()
```

`exemplos/python-cli-novo/docs/bootstrap-respostas.md`:
```markdown
# Respostas pré-gravadas do bootstrap

- Contexto: CLI de conversão de unidades (comprimento, temperatura) para uso pessoal; domínio simples; projeto novo; sem restrições regulatórias nem legado.
- Stack: Python 3 sem dependências externas; testes com unittest da biblioteca padrão.
- Comandos: instalar = (nenhum); build = `python -m compileall -q src`; lint = (nenhum); testes = `python -m unittest discover -s tests -q`; arquitetura = (nenhum).
- CMD_VERIFY_STACK = `python -m compileall -q src && python -m unittest discover -s tests -q`
- CMD_TESTE = `python -m unittest discover -s tests -q`
- Teste desabilitado: `@unittest\.skip|skipTest\(`. Relatório JUnit: não há (verificação degradada, aceito). Asserção: `assert[A-Z][A-Za-z]*\(`.
- Estrutura: pacote `src/conversor/`, testes em `tests/`. Sem ferramenta de fronteiras.
- Risco: nenhum caminho protegido além dos do framework; nenhum gatilho N3 adicional.
- Fontes externas: nenhuma.
- Operação: branch principal `main`; sem plataforma de PR (integração local com `git merge --ff-only`); sem CI; Gate 1 e Gate 2 aprovados pelo mantenedor; modo automático desligado.
```

- [ ] **Step 2: Exemplo Node (projeto existente)**

`exemplos/node-servico-existente/.gitignore`:
```
relatorio/
node_modules/
```

`exemplos/node-servico-existente/package.json`:
```json
{
  "name": "servico-precos",
  "version": "1.0.0",
  "private": true,
  "type": "commonjs",
  "scripts": {
    "test": "node --test --test-reporter=spec --test-reporter-destination=stdout --test-reporter=junit --test-reporter-destination=relatorio/junit.xml"
  }
}
```

`exemplos/node-servico-existente/src/precos.js`:
```js
// Cálculo de preço final com desconto por faixa de quantidade.
function precoFinal(precoUnitario, quantidade) {
  const bruto = precoUnitario * quantidade;
  const desconto = quantidade >= 100 ? 0.1 : quantidade >= 10 ? 0.05 : 0;
  return Math.round(bruto * (1 - desconto) * 100) / 100;
}

module.exports = { precoFinal };
```

`exemplos/node-servico-existente/legado/calculo-antigo.js`:
```js
// Implementação antiga, ainda usada por relatórios. Arredonda para baixo (comportamento herdado).
function precoAntigo(precoUnitario, quantidade) {
  const desconto = quantidade > 100 ? 0.1 : 0;
  return Math.floor(precoUnitario * quantidade * (1 - desconto));
}

module.exports = { precoAntigo };
```

`exemplos/node-servico-existente/test/precos.test.js`:
```js
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { precoFinal } = require("../src/precos");

test("sem desconto abaixo de 10 unidades", () => {
  assert.equal(precoFinal(2.5, 4), 10);
});

test("5% a partir de 10 unidades", () => {
  assert.equal(precoFinal(10, 10), 95);
});

test("10% a partir de 100 unidades", () => {
  assert.equal(precoFinal(1, 100), 90);
});
```

`exemplos/node-servico-existente/docs/bootstrap-respostas.md`:
```markdown
# Respostas pré-gravadas do bootstrap

- Contexto: serviço interno de cálculo de preços usado pelo time comercial; projeto existente; há uma implementação legada em `legado/` ainda usada por relatórios, com regra de desconto diferente.
- Stack: Node.js ≥ 20, CommonJS, sem dependências externas; testes com `node:test`.
- Comandos: instalar = (nenhum); build = (nenhum); lint = (nenhum); testes = `npm test`; arquitetura = (nenhum).
- CMD_VERIFY_STACK = `mkdir -p relatorio && npm test`
- CMD_TESTE = `node --test`
- Teste desabilitado: `\.skip\(|\{ *skip *:|test\.todo\(`. Relatório JUnit: `relatorio/*.xml`. Asserção: `assert\.`.
- Estrutura: código em `src/`, legado em `legado/` (não deve ser alterado sem decisão), testes em `test/`.
- Risco: caminho protegido `legado/`; gatilho N3 adicional: qualquer mudança em regra de desconto.
- Fontes externas: oráculo `legado-precos` sobre `legado/calculo-antigo.js` (leitura do arquivo no próprio repositório).
- Operação: branch principal `main`; sem plataforma de PR (integração local); sem CI; Gates aprovados pelo mantenedor; modo automático desligado.
```

- [ ] **Step 3: Conferir que os exemplos rodam sozinhos**

Run: `(cd exemplos/python-cli-novo && python -m unittest discover -s tests -q) && (cd exemplos/node-servico-existente && node --test)`
Expected: `OK` do unittest (1 teste) e `pass 3` do node.

- [ ] **Step 4: Escrever o teste do montador (falhando)**

`bootstrap/montar-exemplo.Tests.sh`:
```sh
#!/bin/sh
# Testes do scripts/montar-exemplo.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/../mecanismos/scripts/testlib.sh"
montar="$dir/../scripts/montar-exemplo.sh"

dest=$(mktemp -d); rmdir "$dest"
tl_espera 0 "monta o exemplo python" sh "$montar" python-cli-novo "$dest"
tl_espera 0 "destino é repositório git com main" git -C "$dest" rev-parse --verify -q main
tl_espera 0 "kit instalado" test -f "$dest/scripts/agentic/verify.sh"
tl_espera 0 "respostas pré-gravadas presentes" test -f "$dest/docs/bootstrap-respostas.md"

tl_espera 2 "recusa destino existente" sh "$montar" python-cli-novo "$dest"
tl_espera 2 "recusa exemplo inexistente" sh "$montar" nao-existe "$(mktemp -d)/x"

tl_fim
```

- [ ] **Step 5: Implementar `scripts/montar-exemplo.sh`**

```sh
#!/bin/sh
# montar-exemplo.sh <nome> <destino> — cria um projeto-exemplo isolado e instala o kit nele.
fw=$(cd "$(dirname "$0")/.." && pwd)
nome=${1:-}; dest=${2:-}
{ [ -n "$nome" ] && [ -n "$dest" ]; } || { echo "uso: montar-exemplo.sh <nome> <destino>" >&2; exit 2; }
[ -d "$fw/exemplos/$nome" ] || { echo "exemplo inexistente: $nome" >&2; exit 2; }
[ ! -e "$dest" ] || { echo "destino já existe: $dest" >&2; exit 2; }

cp -R "$fw/exemplos/$nome" "$dest"
git -C "$dest" init -q -b main
git -C "$dest" config core.autocrlf false
git -C "$dest" add -A
git -C "$dest" -c user.email=exemplo@exemplo.invalid -c user.name=exemplo commit -q -m "inicial"
sh "$fw/bootstrap/instalar.sh" "$dest"
```

- [ ] **Step 6: Rodar e ver passar**

Run: `sh bootstrap/montar-exemplo.Tests.sh`
Expected: `0 falhas`.

- [ ] **Step 7: Escrever `docs/origem.md`**

````markdown
# Origem de cada regra

Cada regra do núcleo aponta para a fonte que a justifica. Siglas das referências teóricas: **[AG]** AGENTS.md · **[QG]** Continuous Quality Gates for Agentic PRs · **[BR]** Bridging AI Agents and CI/CD Quality Gates · **[CI]** Capture as intent.md (Claude Academy) · **[RG]** Repository Guardrails for AI-Generated Code · **[FC]** Framework Corporativo de SDLC com IA (gerado por IA — proposta, não prática validada) · **[RR]** Research report SDLC agêntico.

| Regra (onde vive) | Fonte |
|---|---|
| P1 Prompt orienta, mecanismo controla (`principios.md`) | [RG] "prompts são orientação"; prática: projeto de referência controlado (subagente executou varredura de disco por ~7h apesar da regra em prosa) |
| P2 Erro 2x vira mecanismo (`principios.md`) | prática: projeto de referência controlado (ciclo do agente; erro repetido virou mecanismo) |
| P3 Estado derivado (`principios.md`, `status-projeto.sh`) | prática: projeto de referência controlado (script de status derivado; decisão de espera humana); prática: projeto de referência enxuto: contagens escritas à mão envelheceram |
| P4 Medido × inferido (`principios.md`) | prática: projeto de referência enxuto (conhecimento de protocolo marcado "medido"/"inferido") |
| P5 Agente não integra nem altera permissões (`principios.md`, `settings.json.tmpl`) | prática: projeto de referência controlado (classificador recusou ampliação de permissões); [QG] revisão humana final |
| P6 Memória enxuta (`principios.md`) | prática: projeto de referência enxuto: arquivo de memória de 110 KB com estado duplicado; [FC]/[RR] context bloat |
| P7 Erros pequenos, visíveis e reversíveis (`principios.md`) | [RG] workspace isolado e princípio-síntese |
| intent.md e suas seções (`templates/intent.md`) | [CI]; [FC] §20.1 |
| AGENTS.md como README para agentes (`templates/AGENTS.md`) | [AG]; [FC] §20.2 |
| Spec com Fonte e estado por regra; questionário de decisão (`papeis/dominio.md`, `templates/spec.md`) | prática: projeto de referência controlado (papel de domínio; decisão de espera humana) |
| Contrato executável antes do RED (`papeis/arquiteto.md`) | prática: projeto de referência controlado (papel de arquiteto) |
| Arquiteto dono único das tasks (`papeis/arquiteto.md`) | prática: projeto de referência controlado |
| Revisor separado, contexto limpo, nunca corrige, 3 modos (`papeis/revisor.md`) | [RG] separação autor/revisor; prática: projeto de referência controlado (reestruturação); prática: projeto de referência enxuto (revisão por diff) |
| Revisor sem ferramenta de escrita (`agents/revisor.md`) | proposta nossa — transforma "nunca corrige" de prompt em mecanismo |
| Achados Crítico/Importante/Menor; menores para revisão final (`ciclo.md`) | prática: projeto de referência enxuto (findings parked para revisão final) |
| Dois gates humanos (`ciclo.md`) | prática: projeto de referência controlado (espera humana dominava o ciclo); [CI] aprovação do intent |
| Escalonamento N3 (`ciclo.md`) | prática: projeto de referência controlado (N3); [FC] níveis de risco N1–N4; [QG] auth/pagamentos/cripto exigem humano |
| Trilha rápida (`ciclo.md`) | prática: projeto de referência controlado (ciclo do agente) |
| Escopo de arquivos declarado e verificado (`verifica-escopo.sh`) | [RG] expansão de escopo plausível; [RR] escopo delimitado; decisão desta spec (sem limite de linhas) |
| Commit `test(red):` provado em worktree; asserções comparadas (`verifica-red.sh`) | prática: projeto de referência controlado (script de verificação do RED); [FC]/[RR] test tampering |
| Skips lidos do relatório real (`verifica-skip.sh`) | prática: projeto de referência controlado (verificação de skips) |
| `verify` ponto único, só reporta, com lock (`verify.sh`, `/verify`) | prática: projeto de referência enxuto (`/verify`: "reportar é o trabalho"); prática: projeto de referência controlado (`verify.sh` com lock) |
| Segredos em duas camadas, fail-closed, staged (`pre-commit`) | prática: projeto de referência controlado (gitleaks não pega senha genérica); [RG] varrer staged, fail-closed |
| Proteção de branch e force-push em hooks nativos (`.githooks`) | prática: projeto de referência controlado (15→20 bypasses no parser de comandos) |
| PreToolUse mínimo, só varredura de disco (`pre-tool-use.sh`) | prática: projeto de referência controlado (varredura de disco); reestruturação: parser redundante com `.githooks` |
| Registro de execução, Rulings, roteamento de modelo (`ciclo.md` — Orquestração) | prática: projeto de referência enxuto (registro de execução do ciclo SDD) |
| Worktree por sessão (`ciclo.md`) | prática: projeto de referência controlado; [RG] |
| Modo automático versionado, nunca mergeia (`auto-mode`) | prática: projeto de referência controlado (auto-mode versionado) |
| Merge sem squash (`ciclo.md`, `templates/pr.md`) | prática: projeto de referência controlado (preserva evidência RED/GREEN) |
| Registro de decisões com Verificado por e revogadas (`templates/decisoes.md`) | prática: projeto de referência controlado (registro de decisões D1–D10; controle afirmado e inexistente) |
| CI só depois de provado verde (`entrevista.md`) | prática: projeto de referência controlado (CI declarado e nunca verde) |
| Plugin de processo desligado (`settings.json.tmpl`, `CLAUDE.md`) | prática: projeto de referência controlado (plugin de processo sobrescrevendo convenções) |
| Contratos portáveis + adaptador fino (`core/papeis/`, `adapters/`) | prática: projeto de referência controlado (contratos de papéis + adaptadores); [AG] |
| Oráculo somente leitura com `arquivo:linha` (`papeis/_oraculo.md`) | prática: projeto de referência enxuto e prática: projeto de referência controlado (oráculos de referência somente leitura) |
| Settings ativado pelo humano (`ativar-protecoes.sh`) | proposta nossa — decorre de P5 |
| Questionário de bootstrap (`entrevista.md`) | proposta nossa — nenhuma fonte propõe; derivado de [AG], [CI], [RG] |
| Baseline de legado (`entrevista.md`, `.agentic/baseline-skips`) | [RG] baseline do legado, bloquear só violações novas |
| Interfaces incidente→intent e release (`ciclo.md`) | [CI] Maintain; [FC] G5 |
````

- [ ] **Step 8: Rodar todas as suítes**

Run: `sh scripts/verify.sh`
Expected: `verify: OK`.

- [ ] **Step 9: Commit**

```bash
git add exemplos/ scripts/montar-exemplo.sh bootstrap/montar-exemplo.Tests.sh docs/origem.md
git commit -m "feat: projetos-exemplo, montador e rastreabilidade de origem"
```

---

### Task 16: Validação v1 (agnosticismo, ciclo real, teste de fogo)

Esta task é de **validação**, com partes que exigem o humano (gates). Ela não muda o kit, salvo correções que a validação revelar — cada correção vira um commit `fix:` próprio, com teste quando for mecanismo.

**Files:**
- Create: `docs/validacao-v1.md`

- [ ] **Step 1: Bootstrap do exemplo Python (projeto novo)**

```bash
dest="$(mktemp -d)/python-cli-novo"; rmdir "$(dirname "$dest")" 2>/dev/null; mkdir -p "$(dirname "$dest")"
sh scripts/montar-exemplo.sh python-cli-novo "$dest"
cd "$dest" && claude -p "/bootstrap" --permission-mode acceptEdits
```

O `/bootstrap` usa `docs/bootstrap-respostas.md` (modo pré-gravado). Depois, como humano:
```bash
cd "$dest" && sh scripts/agentic/ativar-protecoes.sh && git checkout -q main && git merge --ff-only agentic/bootstrap
sh <caminho-do-framework>/bootstrap/checa-instancia.sh "$dest"
```
Expected: `INSTÂNCIA: OK`. Registre em `docs/validacao-v1.md` a saída, o tempo e qualquer intervenção manual.

- [ ] **Step 2: Bootstrap do exemplo Node (projeto existente)**

Mesmo procedimento com `node-servico-existente`. Expected adicional: oráculo `legado-precos` criado em `docs/agentic/papeis/oraculo-legado-precos.md` e `.claude/agents/oraculo-legado-precos.md`; `legado/` listado como caminho protegido e "regra de desconto" como gatilho N3 no `AGENTS.md`; `checa-instancia.sh` com `INSTÂNCIA: OK`.

- [ ] **Step 3: Comparar instâncias (prova de agnosticismo)**

Run: `diff -rq <dest-python>/docs/agentic/ciclo.md <dest-node>/docs/agentic/ciclo.md; diff -q <dest-python>/docs/agentic/principios.md <dest-node>/docs/agentic/principios.md`
Expected: sem diferenças — o núcleo é idêntico; só config, AGENTS.md, "Contexto da stack" e oráculos diferem. Registre.

- [ ] **Step 4: Ciclo real no exemplo Node (com o humano)**

No exemplo Node instanciado, numa sessão interativa do Claude Code:
1. `/intent desconto de 15% a partir de 500 unidades`
2. Seguir `docs/agentic/ciclo.md` até o Gate 1 (o humano aprova e responde o questionário).
3. `/nova-task docs/specs/<nome>/tasks/001-<nome>.md` até o PR/branch publicada.
4. Gate 2 pelo humano (`git merge --no-ff` local, já que o exemplo não tem remoto — o humano pode usar `--no-verify` por ser integração humana).

Registre em `docs/validacao-v1.md`: cada fase, artefatos gerados, saídas do `verify.sh`, onde o processo travou, e a seção **"O que ficou desconfortável"**. Toda falha de mecanismo encontrada vira `fix:` com caso novo no `.Tests.sh` correspondente.

- [ ] **Step 5: Teste de fogo (somente leitura sobre um projeto existente maduro)**

```bash
git -C <projeto-existente> worktree add "$(mktemp -d)/fogo" HEAD --detach
```
No worktree descartável: `git checkout -b agentic/fogo`, rodar `sh <framework>/bootstrap/instalar.sh .` e `/bootstrap` em modo interativo, comparando o gerado com o que o projeto já tem (`docs/agentes/`, `.githooks/`, `scripts/verify.sh`). Registre o comparativo em `docs/validacao-v1.md` (o que o framework cobre, o que o projeto tem a mais e vale trazer, o que o framework tem a mais). Ao final: `git -C <projeto-existente> worktree remove --force <caminho>` — o repositório original não recebe commits.

- [ ] **Step 6: Escrever `docs/validacao-v1.md`**

Estrutura obrigatória:
```markdown
# Validação v1

**Data:** <AAAA-MM-DD>

## 1. Suítes dos mecanismos
<saída final de sh scripts/verify.sh>

## 2. Bootstrap — python-cli-novo
<saída do checa-instancia, intervenções manuais, tempo>

## 3. Bootstrap — node-servico-existente
<idem; oráculo e gatilhos gerados>

## 4. Agnosticismo
<resultado do diff do núcleo entre as instâncias>

## 5. Ciclo real
<fase a fase, com evidências e travamentos>

## 6. Teste de fogo (projeto existente maduro)
<comparativo>

## 7. O que ficou desconfortável
<lista>

## 8. Correções aplicadas
<commits fix: gerados pela validação>
```

- [ ] **Step 7: Commit**

```bash
git add docs/validacao-v1.md
git commit -m "docs: validação v1 do framework"
```
