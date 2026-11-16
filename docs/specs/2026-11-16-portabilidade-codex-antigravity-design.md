# Portabilidade para Codex e Antigravity — design

**Data:** 2026-11-16 · **Status:** aguardando aprovação do dono

## 1. Intenção

Hoje o kit roda no Claude Code (sempre instalado) e no GitHub Copilot (opcional, `--copilot`). A proposta é que ele rode também no **OpenAI Codex** e no **Google Antigravity**, para que quem usa essas ferramentas siga o mesmo processo: papéis separados, testes antes do código, dois gates humanos e controles que bloqueiam de verdade.

Sucesso: num projeto instalado com `--codex` ou `--antigravity`, uma sessão nova da ferramenta, sem receber nenhuma explicação, passa no teste de portabilidade de `docs/portabilidade.md`, que tem 5 perguntas. A sessão também consegue despachar um papel como subagente, e um `git commit --no-verify` é barrado pelo hook. Esse teste é feito pelo dono nas duas ferramentas, que ele tem instaladas.

## 2. Objetivos, não-objetivos, anti-objetivos

**Objetivos**
- Dois adaptadores finos novos, `adapters/codex/` e `adapters/antigravity/`, mais um compartilhado, `adapters/agents-skills/`, com os comandos do ciclo como skills em `.agents/skills/`. Codex e Antigravity leem esse mesmo diretório.
- Duas opções novas no `instalar.sh`, `--codex` e `--antigravity`. Elas podem ser combinadas entre si e com `--copilot`. O Claude Code continua instalado sempre.
- Os mesmos controles do adaptador do Claude Code, onde a ferramenta oferecer um equivalente. Onde não houver, a regra vira "por revisão", dita assim por escrito.

**Não-objetivos**
- Mudar `core/` ou `mecanismos/`, exceto o `ativar-protecoes.sh` (seção 5.4) e textos que hoje citam só Claude Code e Copilot.
- Suporte ao Codex cloud ou a agentes de nuvem do Antigravity. O alvo é o uso local: CLI, IDE e app.
- Escolher modelos por papel nessas ferramentas. Os agentes herdam o modelo da sessão (seção 5.6).

**Anti-objetivos** (é fracasso mesmo que funcione)
- Regra de processo copiada para dentro do adaptador. O adaptador só aponta para o contrato e para `.claude/commands/`.
- Prometer como garantido o que a ferramenta não garante. No Codex sem confiança no projeto, nenhum hook ou regra roda, e isso precisa estar escrito.
- Listas de bloqueio divergentes entre Claude, Codex e Antigravity.

## 3. Fatos das ferramentas (documentação oficial, conferida em 2026-11-16)

**Codex** (developers.openai.com/codex)
- Lê `AGENTS.md` da raiz até o diretório atual.
- Agentes do projeto ficam em `.codex/agents/<nome>.toml`, com os campos obrigatórios `name`, `description` e `developer_instructions`. Eles herdam sandbox e aprovação da sessão pai e não podem restringi-las. A única restrição possível é `features.shell_tool = false` e similares.
- Skills: `.agents/skills/<nome>/SKILL.md`, com frontmatter `name` e `description`. São invocadas com `$<nome>` ou de forma autônoma.
- Regras: `.codex/rules/*.rules` em Starlark, com `prefix_rule(pattern=[...], decision="forbidden", justification=..., match=[...], not_match=[...])`. O casamento é pelo prefixo exato da lista de argumentos. Um `bash -lc` simples é dividido em comandos, um complexo é avaliado inteiro. As regras são experimentais.
- Hooks: `.codex/hooks.json` ou `[hooks]` em `.codex/config.toml`, com os eventos `SessionStart` e `PreToolUse`, entre outros.
  - No `PreToolUse`, `tool_name` vale `Bash` ou `apply_patch` (o matcher aceita também `Edit` e `Write`), e `tool_input.command` traz o comando ou o patch.
  - `exit 2` com motivo no stderr bloqueia a ação.
  - No `SessionStart`, o texto no stdout vira contexto do modelo.
  - Para os caminhos, a recomendação é partir da raiz do git.
  - Existe `commandWindows`, que permite um comando diferente no Windows.
- Confiança: o Codex ignora a camada `.codex/` do projeto (config, hooks, rules) se o projeto não for confiável. Cada hook não gerenciado precisa ser revisado e aprovado em `/hooks`, e a aprovação fica presa ao hash do hook.
- No sandbox `workspace-write`, `.git/`, `.agents/` e `.codex/` são somente leitura.

**Antigravity** (antigravity.google/docs)
- Regras sempre ativas: lê `AGENTS.md` (sem frontmatter) da pasta de trabalho até a raiz do repositório.
- Skills: `.agents/skills/<nome>/SKILL.md`, com `name` (opcional) e `description`. São invocadas por `/<nome>` ou de forma autônoma. Os workflows estão descontinuados, e uma skill vence um workflow de mesmo nome.
- Subagentes: `.agents/agents/<nome>.md`, com frontmatter `name` e `description` obrigatórios e opcionalmente `tools`, `model` e `commandExecutionPolicy`. O corpo do arquivo é o prompt de sistema. O orquestrador despacha com `invoke_subagent`. A documentação avisa que um nome de ferramenta errado em `tools` pode travar o subagente.
- Hooks: `.agents/hooks.json`, com os eventos `SessionStart`, `PreToolUse` e outros.
  - O `PreToolUse` casa por regex no nome da ferramenta: `run_command` e as de escrita `write_to_file|replace_file_content|multi_replace_file_content`.
  - A entrada é JSON em camelCase: o comando vem em `toolCall.args.CommandLine` e o arquivo em `toolCall.args.TargetFile`.
  - A saída é JSON com `decision`, que pode ser `deny` e outros valores, e `reason`.
  - O `SessionStart` injeta contexto por `injectSteps`/`systemMessage`.
- Lista de permitidos e negados para terminal e arquivos: existe só nas configurações do usuário. **Não há** arquivo de repositório para isso.

Os nomes de campo do hook do Antigravity e o comportamento dos hooks no Windows nas duas ferramentas são **a confirmar no teste real** (seção 7).

## 4. Abordagens consideradas

1. **Adaptadores por opção, com as skills compartilhadas** (escolhida pelo dono). O Claude Code fica como padrão, e Codex e Antigravity entram por opção, como o Copilot. `.agents/skills/` é escrito uma vez só.
2. Instalar sempre todos os adaptadores. Foi descartada porque enche a raiz do projeto de pastas de ferramentas que o time não usa e foge do padrão já firmado com o Copilot.
3. Skills com o conteúdo dos comandos escrito dentro delas. Foi descartada porque gera duas cópias da regra, que divergem. O Copilot já usa o ponteiro para `.claude/commands/`.

## 5. Design

### 5.1 Estrutura no kit

```
adapters/agents-skills/<comando>/SKILL.md   intent, mudanca, nova-task, verify, status, bootstrap
adapters/codex/agents/<papel>.toml          os 5 papéis
adapters/codex/agente-oraculo.tmpl.toml
adapters/codex/rules/agentic.rules
adapters/codex/hooks.json
adapters/codex/hooks/guarda-edicao.sh       bloqueio de edição por caminho (apply_patch)
adapters/antigravity/agents/<papel>.md
adapters/antigravity/agente-oraculo.tmpl.md
adapters/antigravity/hooks.json
adapters/antigravity/hooks/pre-tool-use.sh  traduz entrada/saída e aplica as listas
```

O `pre-tool-use.sh` do Claude Code continua sendo a única implementação do bloqueio de desvio dos githooks e de varredura de disco. O Codex o usa direto, porque a entrada é a mesma. O tradutor do Antigravity o chama com a entrada no formato do Claude.

### 5.2 Skills (compartilhadas)

Cada `SKILL.md` tem `name`, `description` (a mesma do comando do Claude) e um corpo de uma ou duas linhas no estilo dos prompts do Copilot:

> Siga `.claude/commands/<comando>.md` como orquestrador. Nele, `$ARGUMENTS` é o texto que o humano escreveu junto com o pedido. Despachar um papel é invocar o subagente de mesmo nome.

O `bootstrap` entra como skill porque o `/bootstrap` hoje só existe no Claude Code.

### 5.3 Papéis

- **Codex.** `name` igual ao papel, a `description` do agente do Claude e `developer_instructions` com o mesmo ponteiro do adaptador do Claude: "Leia `agentic/processo/papeis/<papel>.md` e siga-o integralmente…".
- **Antigravity.** Frontmatter `name` e `description`, e o corpo com o mesmo ponteiro. Sem `tools`, por causa do risco de travar documentado.
- **Revisor.** Nas duas ferramentas, "escreve só o parecer" é por revisão, com o mesmo texto de limite que o Copilot já usa.
- **Oráculo.** Há um template por ferramenta, e o passo 4 da entrevista passa a citá-los quando o adaptador estiver instalado.

### 5.4 Bloqueios

| Controle | Claude (hoje) | Codex | Antigravity |
|---|---|---|---|
| `--no-verify`, `commit -n`, `hooksPath`, varredura de disco | hook `pre-tool-use.sh` | o mesmo script, no `PreToolUse` `Bash` | tradutor no `PreToolUse` `run_command` |
| `deny` de comandos (`gh pr merge`, `push --force`, `reset --hard`, `ativar-protecoes.sh`…) | `permissions.deny` | `rules/agentic.rules`, um `prefix_rule` `forbidden` por item | o tradutor nega por prefixo, com a mesma lista |
| edição de `agentic/config`, `auto-mode`, `mecanismos/`, `baseline-skips`, `.git/agentic/`, `.gitleaksignore`, arquivos de proteção da própria ferramenta | `deny` de `Edit` | `guarda-edicao.sh` no `PreToolUse` `apply_patch` lê os caminhos do patch. `.codex/` e `.agents/` já são somente leitura no sandbox | o tradutor nega pelo `TargetFile` |
| status no início | `SessionStart` | `SessionStart`, com o texto do `status-projeto.sh` no stdout | `SessionStart` via `injectSteps` |

- **Uma fonte para as listas.** A lista de prefixos negados e de caminhos protegidos vale para as três ferramentas. A ideia é que o `coerencia-kit` confira que cada item do `deny` do `settings.json.tmpl` aparece nas regras do Codex e no tradutor do Antigravity, e vice-versa. Se o construtor achar mais simples gerar as três a partir de um arquivo único, essa escolha é dele.
- **Ativação pelo humano, como no Claude.** O agente não pode editar os arquivos de proteção, e o `/bootstrap` precisa ajustá-los (acrescentar `git merge` sem plataforma de PR, como o passo 6 da entrevista já faz no settings). Por isso o instalador grava as proteções do Codex e do Antigravity como pendentes em `agentic/.estado/`, e o `ativar-protecoes.sh` as instala.
  - O script continua sendo a única ação humana e não sobrescreve um arquivo de proteção que já exista, como faz hoje com o `settings.json`.
  - O passo 6 da entrevista passa a ajustar as três listas pendentes.
- **Confiança no Codex.** O `ativar-protecoes.sh` e o `docs/portabilidade.md` dizem que é preciso marcar o projeto como confiável e aprovar os hooks em `/hooks`. Sem isso, nenhum bloqueio do Codex vale, só os githooks e a CI.
- **Windows.** Os hooks chamam `sh`. Se a ferramenta não rodar comandos pelo Git Bash, usa-se `commandWindows` (no Codex) ou o equivalente que o teste real mostrar.

### 5.4.1 Decisões do design, depois da leitura do construtor

Estas decisões são minhas e o dono pode corrigi-las.

- **Modo do Codex: `workspace-write` com `on-request`, o padrão.** Nesse modo, `.git/` é somente leitura e commit, worktree e push saem do sandbox. Por isso o `allow` do `settings.json.tmpl` (git add/commit/checkout/rebase/worktree/push, `gh pr create/view`, `verify.sh`, `status-projeto.sh`) vira `prefix_rule` com `decision="allow"` em `agentic.rules`, e a regra `forbidden` vence quando os dois casam. Num modo `danger-full-access` o sandbox não protege nada, e o `docs/portabilidade.md` diz isso. Por isso o `guarda-edicao.sh` também protege os arquivos de proteção dentro de `.codex/` e `.agents/`, sem depender do sandbox.
- **Arquivos de proteção são só os que bloqueiam.** No Codex são `.codex/hooks.json`, `.codex/hooks/**`, `.codex/rules/**` e `.codex/config.toml`. No Antigravity, `.agents/hooks.json` e `.agents/hooks/**`. Agentes e skills não entram na lista: o `/bootstrap` cria oráculos e resolve conflitos nelas. No Codex, gravar em `.codex/agents/` pede aprovação do humano por causa do sandbox, e a entrevista avisa isso.
- **A lista vale nos dois sentidos.** O `deny` do Claude ganha `Edit` desses arquivos do Codex e do Antigravity. O Codex e o Antigravity protegem `.claude/settings*.json` e `.claude/hooks/**`, porque executam o mesmo script. Uma instância com `settings.json` já ativo recebe as entradas novas pelo merge manual que o `ativar-protecoes.sh` já orienta. Não há checagem nova para isso.
- **Entrada ilegível bloqueia nos adaptadores novos.** O hook só é chamado para as ferramentas do matcher. Se o campo esperado não estiver lá, o formato mudou: o tradutor do Antigravity e o `guarda-edicao.sh` negam, com uma mensagem que diz isso. Assim a falha aparece em vez de sumir em silêncio. No Codex, `tool_input.command` em forma de lista também é lido. O `pre-tool-use.sh` do Claude não muda.
- **O instalador lembra os adaptadores.** Sem estado novo: se o manifesto anterior tem entradas de `.github/agents/`, `.codex/` ou `.agents/`, a reinstalação inclui o adaptador correspondente mesmo sem a opção, e avisa. Isso vale também para o `--copilot`.

### 5.5 Instalador, checagem e documentação

- `instalar.sh <projeto> [--copilot] [--codex] [--antigravity]`, em qualquer ordem e combinação. As skills entram uma vez só se `--codex` ou `--antigravity` estiver presente. Tudo passa pelo manifesto, como hoje.
- `checa-instancia.sh`: com o adaptador instalado, acusa proteção pendente não ativada e arquivo de proteção não versionado, como já faz com o `settings.json`.
- O `docs/portabilidade.md` ganha as duas ferramentas na tabela "Como cada ferramenta encontra as instruções" e uma seção por adaptador, com o que fica por revisão.
- No README:
  - a frase de abertura passa a citar as quatro ferramentas;
  - "Início rápido" ganha as opções novas;
  - a tabela "Estrutura do framework" ganha os adaptadores;
  - na tabela "O problema que ele resolve", a coluna "Quem garante" deixa de ser só Claude onde houver equivalente.
  - O site segue o README nas frases de mecanismo que o `coerencia-kit` confere.
- O `AGENTS.md` não muda, porque já é neutro.

### 5.6 Modelos

Os agentes do Codex e do Antigravity não fixam modelo e herdam o da sessão. O passo 8 da entrevista ("confira o `model:`…") passa a dizer que, nessas ferramentas, o nível do papel vem da tabela de `modelos.md` e é aplicado pelo humano na sessão, por revisão.

## 6. Testes

- `instalar.Tests.sh`:
  - cada opção sozinha e as combinações;
  - nenhuma pasta de ferramenta sem a opção correspondente;
  - os ponteiros das skills e dos agentes levam a arquivos instalados;
  - as proteções ficam pendentes até o `ativar-protecoes.sh`.
- Testes do tradutor do Antigravity e do `guarda-edicao.sh`, com casos espelhados do `pre-tool-use.Tests.sh`:
  - `--no-verify` em qualquer posição;
  - `gh pr merge`;
  - patch que toca `agentic/config`;
  - edição permitida passa.
- `codex execpolicy check` não é obrigatório no `verify` (a CI do kit não tem Codex). As regras levam `match` e `not_match`, que o próprio Codex valida ao carregar.
- `coerencia-kit.Tests.sh`:
  - as listas iguais nas três ferramentas;
  - os agentes dos 5 papéis em todos os adaptadores;
  - uma skill por comando do Claude;
  - o README e o portabilidade citando as opções.

## 7. Validação real (dono)

Em `exemplos/node-servico-existente`, montado com `--codex --antigravity`, para cada ferramenta:
1. `ativar-protecoes.sh`. No Codex, também confiar no projeto e aprovar os hooks.
2. As 5 perguntas do teste de portabilidade.
3. `$bootstrap` ou `/bootstrap` roda a entrevista.
4. O orquestrador despacha um papel como subagente.
5. `git commit --no-verify -m x` é barrado pelo hook, e `gh pr merge 1` é barrado pela regra ou pelo hook.
6. Uma edição de `agentic/config` é barrada.

O que falhar vira ajuste antes do merge, ou vira "por revisão" na documentação, com a decisão registrada.

## 8. O que fica com o construtor

- Formato exato do `hooks.json` do Antigravity e da tradução da saída, conferidos na documentação durante o plano.
- Lista única gerada ou listas conferidas pelo teste (5.4).
- Como o `guarda-edicao.sh` extrai os caminhos do patch do `apply_patch` (linhas `*** Update File:`, `*** Add File:`, `*** Delete File:`, `*** Move to:`).
