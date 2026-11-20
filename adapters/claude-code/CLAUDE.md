# CLAUDE.md

Leia `AGENTS.md` — é a fonte de verdade para qualquer agente neste repositório.

Específico do Claude Code:
- Papéis em `.claude/agents/` são adaptadores finos de `agentic/processo/papeis/`; a regra vive no contrato, não aqui. Stack e padrões do projeto vivem no perfil, em `agentic/projeto/papeis/`.
- Comandos: `/intent`, `/nova-task`, `/mudanca`, `/verify`, `/status`, `/bootstrap`.
- O estado do projeto é injetado no início da sessão por `agentic/mecanismos/scripts/status-projeto.sh`; não o reescreva aqui.
- Plugins de processo (por exemplo, superpowers) ficam desligados: o processo deste projeto é `agentic/processo/ciclo.md`.
- A sessão é compactada ao chegar a 200 mil tokens (`autoCompactWindow` em `.claude/settings.json`): o estado da execução vive no `progress.md`, não na conversa.

# Compact instructions

Ao compactar a sessão do orquestrador, guarde no resumo: a task ou spec em curso e a trilha; o caminho da pasta de execução e do `progress.md`; o próximo passo; as respostas `N<n>` e as Rulings que ainda não estão em artefato ou commit; o que está parado à espera do humano. Não resuma brief, relatório, parecer nem saída de verify: estão em arquivo. Termine o resumo mandando reler o `progress.md` e o que a seção "Kit" do status apontar.
