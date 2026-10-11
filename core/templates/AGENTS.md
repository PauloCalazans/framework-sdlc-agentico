# AGENTS.md

Guia para qualquer agente de IA trabalhando neste repositório. Mapa e regras — o estado do projeto é derivado (`sh agentic/mecanismos/scripts/status-projeto.sh`), nunca escrito aqui.

## Visão geral
{{VISAO_GERAL}}

## Processo
Todo trabalho segue `agentic/processo/ciclo.md`. Princípios em `agentic/processo/principios.md`. Papéis em `agentic/processo/papeis/`.

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
