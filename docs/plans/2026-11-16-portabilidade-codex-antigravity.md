# Portabilidade para Codex e Antigravity — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** instalar o kit no Codex e no Antigravity (`--codex`, `--antigravity`), com papéis, skills e os mesmos bloqueios do Claude Code onde a ferramenta oferece equivalente.

**Architecture:** são dois adaptadores finos, `adapters/codex/` e `adapters/antigravity/`, mais dois compartilhados:
- `adapters/agents-skills/`: as skills em `.agents/skills/`;
- `adapters/comum/`: as listas de comandos negados e de caminhos protegidos, e o `lib-guarda.sh`.

Os arquivos de proteção (hooks, regras e listas) são instalados como pendentes em `agentic/.estado/protecoes-pendentes/<caminho final>`. Quem os põe no lugar é o `ativar-protecoes.sh`, uma ação humana, como já acontece com o `settings.json`. O `pre-tool-use.sh` do Claude continua sendo a única implementação do bloqueio de desvio dos githooks.

**Tech Stack:** POSIX `sh`, sem `jq` (o JSON é lido com `sed`/`awk`, como no `pre-tool-use.sh`); testes com `mecanismos/scripts/testlib.sh`; Starlark para as regras do Codex.

**Spec:** `docs/specs/2026-11-16-portabilidade-codex-antigravity-design.md`

## Global Constraints

- O Claude Code continua sempre instalado. Codex e Antigravity só entram por `--codex` ou `--antigravity`, combináveis em qualquer ordem entre si e com `--copilot`.
- O adaptador nunca copia regra de processo. Os agentes apontam para `agentic/processo/papeis/<papel>.md`, e as skills apontam para `.claude/commands/<comando>.md`.
- Onde a ferramenta não garante algo, o texto diz "por revisão".
- Os adaptadores novos bloqueiam quando a entrada é ilegível. O `pre-tool-use.sh` do Claude não muda de comportamento.
- Sem nomes de projetos de origem em arquivos, commits ou PR. O `coerencia-kit` confere isso pela lista local `.nomes-proibidos`.
- Arquivos novos `.sh` com LF. `scripts/verify.sh` precisa terminar em `verify: OK` no fim de cada task.
- Commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Formato dos hooks, conferido na documentação oficial em 2026-11-16:
  - Codex:
    - `.codex/hooks.json` traz `{"hooks":{"PreToolUse":[{"matcher":…,"hooks":[{"type":"command","command":…}]}]}}`;
    - a entrada é JSON com `tool_name`, que vale `Bash` ou `apply_patch`, e `tool_input.command`, que traz o comando ou o patch;
    - o hook bloqueia saindo com `exit 2` e o motivo no stderr;
    - no `SessionStart`, o stdout vira contexto do modelo.
  - Antigravity:
    - `.agents/hooks.json` traz `{"<nome>":{"SessionStart":[{"type":"command","command":…}],"PreToolUse":[{"matcher":…,"hooks":[…]}]}}`;
    - a entrada é JSON com `toolCall.name` e `toolCall.args.CommandLine`, ou `toolCall.args.TargetFile` nas ferramentas de escrita (`write_to_file`, `replace_file_content`, `multi_replace_file_content`);
    - a saída é JSON no stdout, `{"decision":"allow"|"deny","reason":…}`;
    - o `SessionStart` devolve `{"injectSteps":[{"systemMessage":{"systemMessage":"…"}}]}`.

## Review Focus

1. Um caminho absoluto ou com `\` do Windows em `TargetFile` ou no patch, por exemplo `C:\proj\agentic\config`, precisa ser barrado como o relativo. Teste na Task 1 (`lib-guarda`).
2. Um caminho protegido dentro de um worktree (`agentic/.estado/worktrees/x/agentic/config`) precisa ser barrado. Teste na Task 1.
3. Na reinstalação sem opção, num projeto que já tinha `.codex/agents/`, o adaptador continua e o instalador avisa. Teste na Task 4.
4. Rodar o `ativar-protecoes.sh` com o `settings.json` já existente ainda instala as proteções pendentes do Codex e do Antigravity e sai com 1, orientando o merge. Teste na Task 4.
5. Um comando negado depois de `&&` (`git add . && gh pr merge 1`) precisa ser barrado no Antigravity. Teste na Task 3.
6. Windows sem Git Bash: os hooks e os scripts rodam pelo lançador `git -c alias.agentic-sh=!sh agentic-sh`. Testes na Task 2 e na Task 3: rodar o comando do `hooks.json` exatamente como está escrito, com a entrada de um commit `--no-verify`, e esperar o bloqueio.

---

### Task 1: listas compartilhadas e `lib-guarda.sh`

**Files:**
- Create: `adapters/comum/comandos-negados.txt`, `adapters/comum/caminhos-protegidos.txt`, `adapters/comum/lib-guarda.sh`
- Test: `adapters/comum/lib-guarda.Tests.sh`
- Modify: `adapters/claude-code/settings.json.tmpl` (deny de `Edit` dos arquivos de proteção novos), `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Produces:
  - `comandos-negados.txt`: um prefixo por linha, separado por espaço. São exatamente os `Bash(<prefixo>:*)` do `deny` de `settings.json.tmpl`, na mesma ordem. Linhas `#` e linhas vazias são ignoradas.
  - `caminhos-protegidos.txt`: um padrão por linha, relativo à raiz. Inclui os `Edit(<p>)` do settings que não começam com `**/` e mais `.codex/hooks.json`, `.codex/hooks/**`, `.codex/rules/**`, `.codex/config.toml`, `.agents/hooks.json` e `.agents/hooks/**`.
  - `lib-guarda.sh`, carregado com `.`, com quatro funções:
    - `guarda_raiz` imprime a raiz do git (`git rev-parse --show-toplevel`) com barras `/`.
    - `guarda_protegido <caminho> <arquivo-lista>` retorna 0 se o caminho casa algum padrão. O caminho pode ser relativo, absoluto, com `\` ou com prefixo `C:`. Para casar:
      - normaliza `\` para `/` e tira o prefixo da raiz (sem distinguir maiúsculas no drive);
      - o padrão `X/**` casa `X/…` e `…/X/…`;
      - o padrão `X` casa `X` e `…/X`.
    - `guarda_negado <comando> <arquivo-lista>` retorna 0 se algum trecho do comando, separado por `;`, `&` ou `|` e sem espaços nas pontas, começa com um prefixo da lista seguido de espaço ou fim.
    - Antes de comparar, `guarda_negado` reduz o lançador do Windows a `sh`: o trecho `git -c alias.agentic-sh=!sh agentic-sh ` no começo de um segmento vira `sh `.
    - Lista ausente: a função imprime `agentic: lista de proteção ausente: <arquivo>` no stderr e retorna 0. Assim, a ausência bloqueia.

- [ ] **Step 1: escrever `lib-guarda.Tests.sh`** com uma lista temporária contendo `agentic/config`, `agentic/mecanismos/**` e `.claude/hooks/**`, e a linha de comando `gh pr merge`. Asserções (`tl_espera 0`, protegido ou negado; `tl_espera 1`, livre):
  - protegidos:
    - `agentic/config`;
    - `C:\\proj\\agentic\\config` (raiz fingida `C:/proj` via `GUARDA_RAIZ=C:/proj`, variável que a função usa antes do git);
    - `/r/agentic/mecanismos/scripts/verify.sh` com `GUARDA_RAIZ=/r`;
    - `agentic/.estado/worktrees/t/agentic/config`;
    - `.claude/hooks/pre-tool-use.sh`.
  - livres (→ 1): `agentic/configuracao.md`, `src/agentic/config.js`, `agentic/projeto/decisoes.md`.
  - negados: `gh pr merge 3`, `git add . && gh pr merge 3`, `  gh pr merge`.
  - negado (com `sh agentic/mecanismos/scripts/ativar-protecoes.sh` na lista): `git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/ativar-protecoes.sh`.
  - não negados: `gh pr view 3`, `echo gh pr merge`.
  - lista ausente: `guarda_protegido x /nao/existe` → 0 e a mensagem `lista de proteção ausente`.
- [ ] **Step 2:** `sh adapters/comum/lib-guarda.Tests.sh`. Expected: FAIL (lib inexistente).
- [ ] **Step 3:** criar as duas listas e o `lib-guarda.sh`. Acrescentar ao `deny` de `settings.json.tmpl` `Edit(<p>)` e `Edit(**/<p>)` para cada um dos 6 caminhos novos. No `settings.json.tmpl`, os padrões `X/**` ficam como estão.
- [ ] **Step 4: coerência.** Em `scripts/coerencia-kit.Tests.sh`, na seção `# --- Portabilidade Codex/Antigravity`:
  - cada `Bash(p:*)` do deny aparece como linha de `comandos-negados.txt`, e o contrário também;
  - cada `Edit(p)` sem `**/` aparece em `caminhos-protegidos.txt`, e o contrário também.

  Extração: `grep -o '"Bash([^"]*:\*)"'` e `grep -o '"Edit([^"]*)"'` em `adapters/claude-code/settings.json.tmpl`. Rode o teste com uma linha a menos numa lista e veja a falha antes de restaurar.
- [ ] **Step 5:** `sh scripts/verify.sh`. Expected: `verify: OK`. Também `bootstrap/instalar.Tests.sh` verde, porque o deny só cresceu.
- [ ] **Step 6: commit** `feat(adapters): listas de proteção compartilhadas e lib-guarda`.

### Task 2: adaptador do Codex

**Files:**
- Create:
  - `adapters/codex/agents/{dominio,arquiteto,testes,dev,revisor}.toml`
  - `adapters/codex/agente-oraculo.tmpl.toml`
  - `adapters/codex/rules/agentic.rules`
  - `adapters/codex/hooks.json`
  - `adapters/codex/hooks/guarda.sh`
- Test: `adapters/codex/hooks/guarda.Tests.sh`
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: `lib-guarda.sh`, `comandos-negados.txt` e `caminhos-protegidos.txt` (Task 1).
- Produces, todos na instância:
  - `.codex/hooks/guarda.sh` carrega `./lib-guarda.sh` e `./caminhos-protegidos.txt`, que ficam na mesma pasta.
  - O hook chama `.claude/hooks/pre-tool-use.sh`.

- [ ] **Step 1: escrever `guarda.Tests.sh`.** Ele monta numa pasta temporária `.codex/hooks/` (guarda, lib, lista) e `.claude/hooks/pre-tool-use.sh` copiados do kit, e roda `guarda.sh` com o JSON do Codex na entrada.
  - `exit 2` para:
    - `{"tool_name":"Bash","tool_input":{"command":"git commit -m x --no-verify"}}`;
    - `{"tool_name":"Bash","tool_input":{"command":["git","commit","--no-verify"]}}`, a forma de lista;
    - `{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: agentic/config\n@@\n-a\n+b\n*** End Patch"}}`;
    - patch com `*** Add File: .codex/hooks.json`;
    - patch com `*** Move to: agentic/auto-mode`;
    - entrada sem `tool_input.command` (a mensagem contém `entrada ilegível`).
  - `exit 0` para:
    - `git status`;
    - patch que toca só `src/a.js`.
  - O stderr do bloqueio contém `agentic:`.
  - O comando do `PreToolUse` do `hooks.json`, extraído do arquivo e rodado com `sh -c` na pasta temporária (que é um repositório git), com a entrada do `--no-verify`, sai com 2.
- [ ] **Step 2:** rodar o teste. Expected: FAIL.
- [ ] **Step 3: implementar `guarda.sh`.**
  - Lê o stdin e pega `tool_name` com o mesmo `sed` do `pre-tool-use.sh`.
  - `Bash`: se `command` é uma lista, junta os elementos com espaço. Repassa ao `pre-tool-use.sh` como `{"tool_input":{"command":"…"}}` e devolve o código dele.
  - `apply_patch`: tira de `command` as linhas `*** (Update|Add|Delete) File: ` e `*** Move to: ` (o `\n` vem escapado na string JSON) e aplica `guarda_protegido` a cada caminho.
  - Sem campo `command`: `exit 2`.
- [ ] **Step 4: `hooks.json`.**
  - `PreToolUse`: matcher `^(Bash|apply_patch)$`, command `git -c alias.agentic-sh=!sh agentic-sh .codex/hooks/guarda.sh`, `statusMessage` `agentic: conferindo proteções`.
  - `SessionStart`: matcher `startup|resume|clear|compact`, command `git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/status-projeto.sh`.
  - O lançador (design 5.4, "Windows") roda o `sh` do git a partir da raiz, no PowerShell, no cmd e no sh. Não use `$(…)` nem `commandWindows`.
- [ ] **Step 5: `rules/agentic.rules`.**
  - Um `prefix_rule(pattern=[…], decision="forbidden", justification="agentic: <motivo>; peça ao humano")` por linha de `comandos-negados.txt`, com um `match` igual ao próprio prefixo.
  - Um `decision="allow"` por item `Bash(p:*)` do `allow` do settings. Os dois itens `sh agentic/mecanismos/scripts/…` ganham também o `allow` da forma com o lançador (`["git", "-c", "alias.agentic-sh=!sh", "agentic-sh", "agentic/mecanismos/scripts/verify.sh"]`).
  - Comentário no topo: "gerado a partir de adapters/comum/comandos-negados.txt e do allow do settings; o coerencia-kit confere".
- [ ] **Step 6: agentes `.toml`.**
  - `name` é o papel. `description` é a mesma do `.claude/agents/<papel>.md`.
  - `developer_instructions` é a primeira linha do corpo do agente do Claude: "Leia `agentic/processo/papeis/<papel>.md` e siga-o integralmente…".
  - O revisor acrescenta o limite do Copilot, adaptado: "Escrever só o parecer não é imposto pela ferramenta; é verificado na conferência ao receber e por revisão."
  - Sem `model`.
  - O oráculo segue `adapters/claude-code/agente-oraculo.tmpl.md`, com os mesmos placeholders.
- [ ] **Step 7: coerência.**
  - Cada linha de `comandos-negados.txt` vira `pattern = ["t1", "t2", …]` seguido de `forbidden` em `agentic.rules`. Para conferir, gere a string esperada a partir dos tokens.
  - Cada `Bash(p:*)` do allow vira um `pattern` com `allow`.
  - Há 5 agentes `.toml`, cada um com `name = "<papel>"` e o caminho do contrato.
- [ ] **Step 8:** `sh scripts/verify.sh`. Expected: `verify: OK`.
- [ ] **Step 9: commit** `feat(adapters): adaptador do Codex`.

### Task 3: adaptador do Antigravity

**Files:**
- Create:
  - `adapters/antigravity/agents/{dominio,arquiteto,testes,dev,revisor}.md`
  - `adapters/antigravity/agente-oraculo.tmpl.md`
  - `adapters/antigravity/hooks.json`
  - `adapters/antigravity/hooks/guarda.sh`
  - `adapters/antigravity/hooks/inicio.sh`
- Test: `adapters/antigravity/hooks/guarda.Tests.sh`
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: Task 1, a lib e as duas listas, instaladas em `.agents/hooks/`.
- Produces: `.agents/hooks/guarda.sh` e `.agents/hooks/inicio.sh`.

- [ ] **Step 1: escrever `guarda.Tests.sh`.** A montagem é como na Task 2, em `.agents/hooks/`. As asserções conferem o stdout.
  - `"decision":"deny"` para:
    - `run_command` com `CommandLine` `git push origin main --no-verify`;
    - `git add . && gh pr merge 1`;
    - `git reset --hard HEAD~1`;
    - `write_to_file` com `TargetFile` `C:\\proj\\agentic\\config` (com `GUARDA_RAIZ=C:/proj`);
    - `replace_file_content` em `.agents/hooks.json`;
    - `run_command` sem `CommandLine`, com o `reason` contendo `entrada ilegível`.
  - `"decision":"allow"` para `npm test` e para `write_to_file` em `src/a.js`.
  - Sempre sai com 0. O stdout é um único objeto JSON e o `reason` não tem aspas soltas.
  - O comando do `PreToolUse` do `hooks.json`, extraído do arquivo e rodado com `sh -c` na pasta temporária, com a entrada do `--no-verify`, devolve `"decision":"deny"`.
- [ ] **Step 2:** rodar o teste. Expected: FAIL.
- [ ] **Step 3: implementar `guarda.sh`.**
  - Lê `toolCall.name` com o `sed` do campo `"name"` dentro de `toolCall`.
  - `run_command`: pega `CommandLine` e passa por `guarda_negado` (lista `comandos-negados.txt`). Depois repassa ao `pre-tool-use.sh` como `{"tool_input":{"command":"<valor ainda escapado>"}}`; código 2 vira `deny` com o stderr dele como `reason`.
  - Escrita: `TargetFile` em `guarda_protegido`.
  - O `reason` é escapado para JSON (`\` e `"`, quebras de linha viram espaço).
- [ ] **Step 4: `inicio.sh`.** Roda o `status-projeto.sh`, escapa a saída para JSON e imprime o `injectSteps`. Teste dele no mesmo arquivo: a saída começa com `{"injectSteps":` e contém uma linha do status.
- [ ] **Step 5: `hooks.json`.**

```json
{
  "agentic": {
    "SessionStart": [{ "type": "command", "command": "git -c alias.agentic-sh=!sh agentic-sh .agents/hooks/inicio.sh" }],
    "PreToolUse": [{ "matcher": "run_command|write_to_file|replace_file_content|multi_replace_file_content",
                     "hooks": [{ "type": "command", "command": "git -c alias.agentic-sh=!sh agentic-sh .agents/hooks/guarda.sh" }] }]
  }
}
```

- [ ] **Step 6: agentes `.md`.**
  - Frontmatter `name` e `description`, iguais aos do Claude, sem `tools` e sem `model`.
  - O corpo é igual ao do Codex na Task 2, com o mesmo limite do revisor.
  - O oráculo segue o template do Claude, sem a linha `tools:`.
- [ ] **Step 7: coerência.**
  - Há 5 agentes com o caminho do contrato.
  - Nenhum frontmatter de agente do Antigravity tem `tools:`, por causa do risco de travar documentado.
  - O `hooks.json` cita `guarda.sh` e `inicio.sh`.
- [ ] **Step 8:** `sh scripts/verify.sh`. Expected: `verify: OK`.
- [ ] **Step 9: commit** `feat(adapters): adaptador do Antigravity`.

### Task 4: skills, instalador, ativação e checagem

**Files:**
- Create: `adapters/agents-skills/{intent,mudanca,nova-task,verify,status,bootstrap}/SKILL.md`
- Modify:
  - `bootstrap/instalar.sh`
  - `bootstrap/instalar.Tests.sh`
  - `mecanismos/scripts/ativar-protecoes.sh`
  - `mecanismos/scripts/ativar-protecoes.Tests.sh`
  - `bootstrap/checa-instancia.sh`
  - `bootstrap/checa-instancia.Tests.sh`
  - `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: os arquivos das Tasks 1 a 3.
- Produces: o mapa da instalação.

| Origem no kit | Destino na instância |
|---|---|
| `agents-skills/*` | `.agents/skills/*` |
| `codex/agents/*` | `.codex/agents/*` |
| `codex/agente-oraculo.tmpl.toml` | `agentic/processo/templates/agente-oraculo-codex.toml` |
| `antigravity/agents/*` | `.agents/agents/*` |
| `antigravity/agente-oraculo.tmpl.md` | `agentic/processo/templates/agente-oraculo-antigravity.md` |

Os arquivos pendentes ficam em `agentic/.estado/protecoes-pendentes/`:
- do Codex: `.codex/hooks.json`, `.codex/rules/agentic.rules` e `.codex/hooks/{guarda.sh,lib-guarda.sh,caminhos-protegidos.txt}`;
- do Antigravity: `.agents/hooks.json` e `.agents/hooks/{guarda.sh,inicio.sh,lib-guarda.sh,comandos-negados.txt,caminhos-protegidos.txt}`.

- [ ] **Step 1: testes do instalador**, em `instalar.Tests.sh`, depois do bloco do Copilot.
  - `--codex`: copiou os 5 `.codex/agents/*.toml` e `.agents/skills/intent/SKILL.md`; não criou `.codex/hooks.json` (pendente); criou `agentic/.estado/protecoes-pendentes/.codex/rules/agentic.rules`; não criou `.agents/agents/`.
  - `--antigravity`: criou `.agents/agents/revisor.md` e os pendentes de `.agents/hooks.json`; não criou `.codex/`.
  - `--antigravity --codex --copilot`, nessa ordem: os três presentes.
  - `--outro`: exit 2.
  - Reinstalar sem opção num projeto com `--codex` mantém `.codex/agents/dev.toml` no manifesto, e a saída contém `mantendo o adaptador codex`. O mesmo vale para o copilot.
  - Ponteiros: a primeira referência `.md` entre crases de cada skill e de cada agente novo existe na instância (estender `.ponteiros.sh`).
  - Sem opção: a raiz não ganha `.codex` nem `.agents` (o teste da raiz atual continua igual).
- [ ] **Step 2: testes da ativação**, em `ativar-protecoes.Tests.sh`.
  - Com pendentes de `.codex/hooks.json` e sem `settings.json`: instala os dois, exit 0, e a saída contém `/hooks`, o aviso de confiança do Codex.
  - Com `settings.json` existente e pendente do Codex: instala o do Codex, exit 1, e a saída contém `merge`.
  - Destino existente e diferente: não sobrescreve, lista o arquivo e exit 1.
  - Destino igual: não acusa nada.
- [ ] **Step 3: testes da checagem**, em `checa-instancia.Tests.sh`. Com `.codex/agents/` e sem `.codex/hooks.json`, sai `PROBLEMA` com `ativar-protecoes.sh`. O mesmo para `.agents/agents/` sem `.agents/hooks.json`. Um arquivo de proteção instalado e não rastreado pelo git também dá `PROBLEMA`.
- [ ] **Step 4:** rodar as três suítes. Expected: FAIL nos casos novos.
- [ ] **Step 5: implementar.**
  - **Skills:** frontmatter `name: <comando>` e `description:` igual à do `.claude/commands/<comando>.md`. O corpo é "Siga `.claude/commands/<comando>.md` como orquestrador. Nele, `$ARGUMENTS` é o texto que o humano escreveu junto com o pedido, e despachar um papel é invocar o subagente de mesmo nome."
  - **instalar.sh:**
    - lê as opções num laço (`for o in "$@"` depois do alvo);
    - "lembrar" significa ler o manifesto antigo antes de reescrevê-lo, com `grep -q '  \.codex/agents/'` e equivalentes para `.agents/agents/` e `.github/agents/`;
    - o pendente vai por `copia` para `agentic/.estado/protecoes-pendentes/…`, fora do manifesto, como já acontece com o settings;
    - a mensagem final cita `/bootstrap` (Claude e Antigravity) e `$bootstrap` (Codex).
  - **ativar-protecoes.sh:**
    - mantém o bloco do settings, mas, em vez de sair, marca `falhou=1`;
    - depois, para cada arquivo em `protecoes-pendentes`: se o destino não existe, copia; se é igual, segue; se é diferente, lista o arquivo e marca `falhou=1`;
    - mostra o `git add` dos instalados;
    - com `.codex/` instalado, imprime "No Codex: marque o projeto como confiável e aprove os hooks em /hooks; sem isso nenhum bloqueio do Codex vale.";
    - sai com `falhou`.
  - **checa-instancia.sh:** as checagens dos testes do Step 3.
- [ ] **Step 6: coerência.** Há uma skill por arquivo de `adapters/claude-code/commands/`, cada skill aponta para `.claude/commands/<mesmo nome>.md`, e o `instalar.sh` cita as três opções no `uso:`.
- [ ] **Step 7:** `sh scripts/verify.sh`. Expected: `verify: OK`.
- [ ] **Step 8: commit** `feat(bootstrap): instala Codex e Antigravity por opção, com proteções pendentes`.

### Task 5: entrevista, documentação e site

**Files:**
- Modify:
  - `bootstrap/entrevista.md` (linha 27 e passos 4, 6 e 8)
  - `docs/portabilidade.md`
  - `README.md`
  - `site/index.html`, se uma frase de mecanismo copiada do README mudar
  - `core/templates/AGENTS.md` (a linha do lançador no Windows)
  - `scripts/coerencia-kit.Tests.sh`

- [ ] **Step 1: testes de coerência primeiro.** Devem falhar.
  - `docs/portabilidade.md` cita `--codex`, `--antigravity`, `.codex/agents/`, `.agents/agents/`, `.agents/skills/`, `/hooks` (confiança) e "por revisão" nas seções das duas ferramentas.
  - O README cita `--codex` e `--antigravity` em "Início rápido" e `adapters/codex/` e `adapters/antigravity/` em "Estrutura do framework".
  - A entrevista cita `agente-oraculo-codex.toml`, `agente-oraculo-antigravity.md` e `protecoes-pendentes`.
  - `core/templates/AGENTS.md` e os dois `hooks.json` citam o mesmo lançador, `git -c alias.agentic-sh=!sh agentic-sh`.
- [ ] **Step 2: entrevista.**
  - Linha 27: "Algum é o GitHub Copilot, o Codex ou o Antigravity?".
  - Passo 4: copiar os templates de oráculo de cada adaptador instalado para `.codex/agents/oraculo-<nome>.toml` e `.agents/agents/oraculo-<nome>.md`. No Codex, a gravação pede aprovação, porque `.codex/` é somente leitura no sandbox.
  - Passo 6: os acréscimos ao `deny` (como `git merge`) entram também nas pendentes, em `comandos-negados.txt` e em `agentic.rules`, como `prefix_rule` `forbidden`.
  - Passo 8: no Codex e no Antigravity, o nível de modelo do papel vem de `modelos.md` e é aplicado pelo humano. Se a ferramenta faz parte do time e não está instalada, peça `instalar.sh . --codex` ou `--antigravity`.
- [ ] **Step 2b: `AGENTS.md`.** Na seção de comandos, uma linha: "No Windows, fora do Git Bash (PowerShell, cmd), `sh` não está no PATH e `bash` pode ser o do WSL. Rode os scripts do kit com `git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/<script>.sh`, que usa o `sh` do git e roda da raiz do repositório."
- [ ] **Step 3: `docs/portabilidade.md`.**
  - Linhas novas na tabela "Como cada ferramenta encontra as instruções".
  - A coluna "Adaptador" da tabela de personas ganha os dois caminhos.
  - Uma seção por ferramenta, no molde da do Copilot, dizendo o que garante e o que fica por revisão: revisor; modelos; Codex sem confiança no projeto ou em `danger-full-access`; Antigravity sem lista de bloqueio no repositório, coberta pelo hook.
  - Windows: o lançador e o motivo (o `bash` do WSL). "A confirmar no teste real": o hook roda e bloqueia nas duas ferramentas.
- [ ] **Step 4: README.**
  - A frase de abertura passa a citar "(Claude Code, GitHub Copilot, Codex, Antigravity)".
  - Pré-requisitos e Início rápido ganham o item 1 com as opções.
  - A tabela "Estrutura do framework" ganha as linhas `adapters/codex/`, `adapters/antigravity/`, `adapters/agents-skills/` e `adapters/comum/`.
  - Tabela do problema:
    - "pula os githooks" → "hook `PreToolUse` (Claude Code, Codex, Antigravity)";
    - "afrouxa as próprias permissões" → "`deny` do Claude Code; hooks no Codex e no Antigravity".
  - Se o site copia alguma dessas células (`site/index.html` linhas 85 a 91 e a checagem `hook PreToolUse (só Claude Code)` em `coerencia-kit`), atualize a página e a checagem juntas.
  - Rode `grep -n "Claude Code" site/index.html` e mantenha a página coerente.
- [ ] **Step 5:** `sh scripts/verify.sh`. Expected: `verify: OK`.
- [ ] **Step 6: commit** `docs: portabilidade para Codex e Antigravity (README, entrevista, site)`.

### Task 6: fechamento

- [ ] **Step 1:** `git fetch` e integrar `origin/main`, conforme a memória "fetch antes do PR". Depois `sh scripts/verify.sh` → `verify: OK`.
- [ ] **Step 2:** revisão final da branch inteira. Corrigir os Críticos e Importantes com teste antes.
- [ ] **Step 3:** montar `exemplos/node-servico-existente` com `--codex --antigravity` num diretório temporário, para o dono rodar a seção 7 do design. Entregar ao dono o caminho e o roteiro.
- [ ] **Step 4:** abrir o PR com o resultado do `verify`, as Rulings e a pendência da validação real. O merge só acontece depois dela.
