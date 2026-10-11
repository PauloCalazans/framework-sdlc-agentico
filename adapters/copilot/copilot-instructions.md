# Instruções para o GitHub Copilot

Leia `AGENTS.md`, na raiz, antes de qualquer trabalho: é a fonte de verdade deste repositório. O processo está em `agentic/processo/ciclo.md` e o contrato de cada papel em `agentic/processo/papeis/`.

Regras que valem sempre (repetidas do `AGENTS.md`, para não depender de ele ter sido lido):
- Nunca faça merge na branch principal nem altere permissões do agente, `agentic/config`, `agentic/auto-mode` ou `agentic/mecanismos/`.
- Só o orquestrador cria branch: uma por task, com o nome exato do `**Branch:**` da task. Nenhum papel cria branch.
- Nunca afirme sucesso sem ter visto `VERIFY: OK` de `sh agentic/mecanismos/scripts/verify.sh`. Numa branch com nome imposto pela ferramenta (ex.: `copilot/…`), rode `sh agentic/mecanismos/scripts/verify.sh --task <caminho da task>`.
- Nunca altere nem desabilite testes de um commit `test(red):`.

Papéis: despachar um papel é invocar o agente personalizado de mesmo nome (`.github/agents/<papel>.agent.md`). Se a ferramenta não deixar invocar outro agente, pare e peça ao humano que troque de agente. O orquestrador nunca implementa.

Comandos do ciclo: os prompts de `.github/prompts/` (`nova-task`, `mudanca`, `intent`, `verify`, `status`).
