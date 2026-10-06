# Validação v1

**Data:** 2026-10-05

Resumo: o framework passou nas suítes dos mecanismos, instanciou dois projetos de teste de forma headless (um novo, um existente) com a checagem estrutural verde, e foi testado em sessão real do Claude Code e contra um clone de um projeto maduro. A validação encontrou defeitos reais, todos corrigidos (seção 8). O ciclo real completo ainda não foi executado (seção 5).

## 1. Suítes dos mecanismos

`sh scripts/verify.sh` no repositório do framework (branch `impl/framework-v1`, após as correções do teste de fogo):

```
verify: OK
```

Todas as suítes `*.Tests.sh` (mecanismos, `instalar`, `checa-instancia`, `montar-exemplo`) passam sem falhas.

## 2. Bootstrap — python-cli-novo

- Bootstrap headless (`/bootstrap` com respostas pré-fornecidas) em um projeto Python novo (unittest, sem PR, sem CI): **1m15s**, terminou com `VERIFY: OK`.
- O bootstrap preencheu `.agentic/config`, `AGENTS.md`, os cinco papéis, `docs/decisoes.md` (D1 stack, D2 integração local) e `docs/bootstrap.md` (respostas marcadas `confirmado`/`inferido`, sem pendências). Hooks e scripts ficaram `100755` no índice.
- Após as ações humanas (`ativar-protecoes.sh`, commit do settings, `git merge --ff-only`): `checa-instancia.sh` → **INSTÂNCIA: OK**.
- Intervenções manuais: apenas as ações humanas previstas no Passo 8 (ativar proteções, commitar settings, integrar, reiniciar a sessão).
- Decisão do bootstrap que virou achado: trocou o deny `gh pr merge` por `git merge` por não haver plataforma de PR (corrigido, ver seção 8).

## 3. Bootstrap — node-servico-existente

- Projeto Node existente com código `legado/` e 3 testes (0 pulados), bootstrap headless com respostas pré-fornecidas: OK, `checa-instancia.sh` → **INSTÂNCIA: OK**.
- Oráculo gerado: `oraculo-legado-precos` (somente leitura sobre `legado/calculo-antigo.js`).
- Gatilhos N3 gerados: qualquer mudança em regra de desconto, qualquer alteração em `legado/`, dependência externa nova.
- `docs/decisoes.md` com cinco decisões (stack e verificação, sem ferramenta de arquitetura, `legado/` protegido, zero testes pulados tolerados, sem CI/PR). Relatório JUnit configurado (`relatorio/*.xml`) e padrões de teste desabilitado/asserção testados.

## 4. Agnosticismo

O núcleo (`docs/agentic/principios.md`, `ciclo.md`, contratos de papéis, templates) foi comparado entre as duas instâncias (Python e Node): **idêntico**. Só mudam os arquivos instanciados (`AGENTS.md`, `.agentic/config`, blocos de stack dos papéis, `docs/decisoes.md`, oráculo).

## 5. Ciclo real

**PENDENTE — aguarda execução interativa pelo humano no exemplo node.** O ciclo completo (`/intent` → spec → tasks → TDD → verify → revisão → integração) exige sessão interativa e decisões nos gates; não foi executado de forma headless. Esta seção deve ser preenchida fase a fase, com evidências e travamentos, após essa execução.

## 6. Teste de fogo (avitech)

Alvo: **clone local** do avitech (Java 25 / Spring Boot / Modulith, 65 tasks, hooks, agentes, comandos e `.claude/settings.json` próprios). Não foi usado worktree: **zero escrita no repositório original**.

**Resultado do bootstrap headless:** não instanciou nada, e esse é o comportamento correto. O `.claude/settings.json` existente do projeto desabilitou `bypassPermissions`, então todas as escritas foram negadas (também a criação de branch e o `mvn -v`). O clone permaneceu intacto (em `main`, nada commitado nem staged). O bootstrap headless de um projeto existente precisa de bypass num diretório descartável; com as permissões do projeto ativas, ele para sem escrever. Apareceu também o aviso de workspace não confiado (`Ignoring 22 permissions.allow entries ... this workspace has not been trusted`; idem para `additionalDirectories`).

Mesmo sem escrever, o agente produziu as respostas dos Passos 1–3 (todas `inferido`: contexto, stack Java/Maven, estrutura de módulos, gatilhos N3, oráculo `oraculo-sisdan`, operação em `main` com GitHub e sem CI) e o conteúdo que gravaria no Passo 4. Notou que o projeto tem o auto-mode próprio ligado e recomendou o modo automático desligado no início.

**Propostas de conflito geradas (Passo 5, nada aplicado):**

| Arquivo | Proposta |
|---|---|
| `.githooks/pre-commit`, `pre-merge-commit` | usar a versão do kit (lê `BRANCHES_PROTEGIDAS`/`GITLEAKS_BIN` via `lib-agentic.sh`) e pôr `develop` no config |
| `.githooks/pre-push` | usar o kit só se o `pre-push.Tests.sh` do projeto continuar passando |
| `.claude/agents/{arquiteto,dev,dominio,revisor,testes}.md` | manter descrições do projeto, apontar para `docs/agentic/papeis/X.md` e `docs/agentes/X.md`; consolidar depois |
| `.claude/commands/nova-task.md` | manter o do projeto e acrescentar `**Branch:**` e `## Arquivos` ao template de task (hoje 0 de 65 tasks têm essas linhas, então a etapa `escopo` nunca rodaria) |
| `.claude/commands/verify.md` | usar o do kit, que chama o `scripts/verify.sh` do projeto via `CMD_VERIFY_STACK` |
| `CLAUDE.md` | manter o do projeto e acrescentar ponteiro para `AGENTS.md` e `docs/agentic/` |

Limitação: o agente não conseguiu ler as versões do kit; o lado "kit" foi inferido (motivo da correção do `kit-conflitos` abaixo).

**Achados para o framework e correções:**

| Achado | Correção |
|---|---|
| `.claude/settings.json` existente não entrava na lista de conflitos, mas `ativar-protecoes.sh` depende da ausência dele | `instalar.sh` o registra como conflito (18e013a) |
| Template `.claude/agents/_oraculo.md` virava um agente `oraculo-{{NOME_ORACULO}}` | movido para `adapters/claude-code/agente-oraculo.tmpl.md`, instalado em `docs/agentic/templates/agente-oraculo.md` (c592f76) |
| O bootstrap não via a versão do kit dos arquivos em conflito | `instalar.sh` guarda a versão do kit em `.agentic/kit-conflitos/<caminho>` (gitignored); `entrevista.md` Passo 5 a usa e a apaga ao final (18e013a, 0d745a2) |
| Duas fontes da verdade em projeto existente (auto-mode, dois `status-projeto.sh`, `docs/arquitetura.md` vs `docs/decisoes.md`) | `entrevista.md` Passo 5: propor consolidação em uma só, humano decide, registrar em `docs/decisoes.md` (0d745a2) |
| `verify.sh` pulava o escopo sem avisar quando há tasks mas nenhuma casa com a branch | aviso visível `aviso: nenhuma task com **Branch:** <branch> — escopo não verificado (trilha rápida?)`, exit inalterado (e7b3cb8) |

## 7. O que ficou desconfortável

- **N3 e independência do revisor continuam só por revisão:** nada mecânico impede o mesmo contexto de implementar e aprovar; a independência do revisor depende de disciplina e de revisão humana.
- **Os deny são contornáveis:** a posição de flags num comando Bash e redirecionamentos (`>`) escapam das regras de deny por padrão. Os githooks são o controle real; os deny são uma camada auxiliar.
- **Bootstrap headless exige bypass em diretório descartável:** com permissões de projeto ativas (ou `bypassPermissions` desabilitado) ele não consegue escrever.
- **Projeto existente exige consolidação conduzida por humano:** hooks, agentes, comandos, auto-mode e registro de decisões próprios competem com os do kit; o framework propõe, mas não consolida sozinho. Sem `**Branch:**` nas tasks, a verificação de escopo não roda.
- **Allow só vale com o workspace confiado:** é preciso abrir o Claude Code interativamente uma vez e aceitar o diálogo de confiança; até lá o modo auto trava em prompts (os `deny` valem de qualquer forma).
- **Regras `Write(...)` não existem para o Claude Code:** só `Edit(path)` é avaliado (cobre todas as ferramentas de escrita); foram removidas.

## 8. Correções aplicadas

Smoke em sessão real do Claude Code (instância python, medido): `Edit` negado em `.agentic/config`, em `.agentic/worktrees/smoke/.agentic/config` (a forma `**/` vale dentro de worktree), em `scripts/agentic/lib-agentic.sh` e em `.claude/settings.json`; o hook bloqueou `find /`; o SessionStart injetou o status do projeto; `bypassPermissions` ficou efetivamente desativado; `Write` comum permitido; regras `Write(...)` ignoradas com aviso a cada sessão (removidas); `allow` ignorado até a confiança do workspace (entrevista corrigida); `gh pr merge` pediu confirmação por ter sido removido do deny pelo bootstrap (entrevista corrigida).

Commits gerados pela validação (`git log 4808882..HEAD`):

```
e7b3cb8 fix: verify.sh avisa quando há tasks mas nenhuma casa com a branch
0d745a2 docs: entrevista Passo 4.4/5 — template do oráculo, kit-conflitos e consolidação de mecanismos equivalentes
c592f76 fix: template do agente oráculo sai de .claude/agents (era registrado como agente)
18e013a fix: instalar.sh registra settings.json existente como conflito e guarda a versão do kit em .agentic/kit-conflitos
df867c5 docs: deny de merge nunca removido e passo de confiança do workspace
652c565 fix: remove regras Write(...) do deny (Claude Code só avalia Edit(...))
```

`652c565` e `df867c5` vêm do smoke; os quatro demais, do teste de fogo. A revisão final da branch cobriu as Tasks 1–15; as correções do teste de fogo não passaram por revisão independente.
