# AGENTS.md

Guia para qualquer agente de IA trabalhando neste repositório. Mapa e regras — o estado do projeto é derivado (`sh agentic/mecanismos/scripts/status-projeto.sh`), nunca escrito aqui.

## Visão geral
{{VISAO_GERAL}}

## Processo
Todo trabalho segue `agentic/processo/ciclo.md`. Princípios em `agentic/processo/principios.md`. Papéis em `agentic/processo/papeis/`.

## Quem é você neste repositório
- **Recebeu um brief que começa com `Papel: <papel>`?** Você é esse papel. Leia `agentic/processo/papeis/<papel>.md` e o que o brief indicar (não precisa do `ciclo.md`) e entregue o relatório que o contrato pede.
- **Sem brief de papel?** Você é o orquestrador: siga `agentic/processo/ciclo.md`, despache os papéis e nunca faça o trabalho deles.
- **Orquestrador externo** (vários agentes num canvas ou numa ferramenta de orquestração): o orquestrador é a sessão indicada na decisão de composição do time em `agentic/projeto/decisoes.md`. As demais sessões só agem com brief.
- **Ferramenta sem subagentes:** não faça o trabalho de um papel no contexto do orquestrador. Grave o brief e peça ao humano que o abra numa sessão nova. O `revisor` roda sempre em contexto limpo, nunca na sessão de quem escreveu o que ele revisa.

## Integração
- Plataforma de PR: {{PLATAFORMA_PR}}
- Sem plataforma de PR (`nenhuma`), o Gate 2 é local: a branch fica rebaseada na principal e o humano integra com `git merge --ff-only <branch>` (veja `agentic/processo/ciclo.md`).

## Comandos
| Ação | Comando |
|---|---|
| Instalar dependências | `{{CMD_INSTALAR}}` |
| Build | `{{CMD_BUILD}}` |
| Lint | `{{CMD_LINT}}` |
| Testes | `{{CMD_TESTE}}` |
| Arquitetura | `{{CMD_ARQUITETURA}}` |
| **Verificação completa** | `sh agentic/mecanismos/scripts/verify.sh` |

No Windows, rode os comandos `sh ...` no Git Bash (o PowerShell não tem `sh`); dentro do Claude Code isso já é tratado.

## Regras invioláveis
- Nunca faça merge na branch principal nem altere permissões do agente.
- Nunca afirme sucesso sem ter visto a saída do `verify.sh`.
- Nunca desabilite ou altere testes de um commit `test(red):`.
- Só o orquestrador cria branch: uma por task, depois do Gate 1, com o nome exato do `**Branch:**` da task (trilha rápida: uma por mudança). Nenhum papel cria branch. Se a ferramenta impõe o próprio nome de branch, rode o verify com `--task <caminho da task>`.
{{REGRAS_INVIOLAVEIS}}

## Estrutura do repositório
{{ESTRUTURA}}

## Onde ficam os artefatos
- Intents: `agentic/projeto/intent/`
- Specs, designs e tasks: `agentic/projeto/specs/<nome>/`
- Decisões: `agentic/projeto/decisoes.md`
- Respostas do bootstrap: `agentic/projeto/bootstrap.md`

## Gatilhos de escalonamento (N3)
Além dos gatilhos genéricos de `agentic/processo/ciclo.md`:
{{GATILHOS_N3_STACK}}

## Oráculos
{{ORACULOS}}
