# Instruções para o GitHub Copilot

Leia `AGENTS.md`, na raiz, antes de qualquer trabalho: é a fonte de verdade deste repositório. O processo está em `agentic/processo/ciclo.md`, o contrato de cada papel em `agentic/processo/papeis/` e o perfil do papel neste projeto em `agentic/projeto/papeis/`.

Regras que valem sempre:
- Nunca faça merge na branch principal nem altere permissões do agente, `agentic/config`, `agentic/auto-mode` ou `agentic/mecanismos/`.
- Só o orquestrador cria branch: uma por task, com o nome exato do `**Branch:**` da task (trilha rápida: uma por mudança). Nenhum papel cria branch, faz push ou abre PR.
- Nunca afirme sucesso sem ter visto a saída da verificação do seu passo: `VERIFY: OK` do `sh agentic/mecanismos/scripts/verify.sh` (revisor `diff` e orquestrador antes do PR), `VERIFY RÁPIDO: OK` do `verify.sh --rapido` (`dev`, no laço) ou o `verifica-red.sh` verde (`testes`, depois do RED) — `agentic/processo/ciclo.md`, "Verificação". Numa branch com nome imposto pela ferramenta (ex.: `copilot/…`), rode `sh agentic/mecanismos/scripts/verify.sh --task <caminho da task>`.
- Nunca altere nem desabilite testes de um commit `test(red):` (única exceção: a remoção autorizada pelo `testes`, `agentic/processo/ciclo.md`, "Remoção de comportamento").

Início da sessão do orquestrador: rode `sh agentic/mecanismos/scripts/status-projeto.sh` antes de escolher a task (no Copilot nenhum hook o injeta).

Quem é você: com um brief que começa com `Papel: <papel>`, você é esse papel; sem brief de papel, você é o orquestrador e nunca faz o trabalho dos papéis (detalhes em `AGENTS.md`, "Quem é você neste repositório"). Despachar um papel é invocar o agente personalizado de mesmo nome (`.github/agents/<papel>.agent.md`). Se a ferramenta não deixar invocar outro agente, grave o brief e peça ao humano que o abra numa sessão nova com esse agente.

Comandos do ciclo: os prompts de `.github/prompts/` (`nova-task`, `mudanca`, `intent`, `verify`, `status`).
