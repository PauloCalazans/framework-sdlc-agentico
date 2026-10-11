# Portabilidade entre ferramentas de agente

O núcleo (`core/`, `mecanismos/`) é neutro. O que muda de uma ferramenta para outra é **como ela encontra as instruções** e **quais controles locais ela respeita**.

## O que vale em qualquer ferramenta

| Controle | Por quê vale em todas |
|---|---|
| Githooks (`agentic/mecanismos/githooks`) | O git os executa para qualquer autor. Num clone novo ficam desligados (`core.hooksPath` é configuração local), e por isso a etapa `hooks` do `verify` falha até alguém ligá-los. |
| `verify.sh` | Script `sh`. Numa branch com nome imposto pela ferramenta, `--task <task.md>` informa a task. Sem a principal local (clone de CI ou de nuvem), a base é `origin/<principal>`. |
| CI rodando o `verify` + proteção da principal | Roda no servidor, fora do alcance do agente. É a guarda que nenhum produto contorna. |

`deny`, hooks de sessão e a lista de ferramentas por agente são específicos de cada produto. No Claude Code, quem os instala é o `adapters/claude-code/`. Nas outras ferramentas, onde não houver equivalente, a regra fica "por revisão".

## Como cada ferramenta encontra as instruções

| Ferramenta | Arquivo que lê sem pedir | Adaptador no kit |
|---|---|---|
| Claude Code | `CLAUDE.md` (aponta para o `AGENTS.md`) | `adapters/claude-code/` (sempre instalado) |
| GitHub Copilot | `.github/copilot-instructions.md`; o `AGENTS.md` depende da superfície e da versão | `adapters/copilot/` (`instalar.sh <projeto> --copilot`) |
| Kiro, Antigravity | não verificado; entenderam o projeto sem explicação (relatado pelo humano) | nenhum |

O adaptador do Copilot traz:
- `.github/copilot-instructions.md`: aponta para o `AGENTS.md` e repete só as regras invioláveis.
- `.github/agents/<papel>.agent.md`: um agente por papel, apontando para o contrato; o `revisor` vem sem `edit`.
- `.github/prompts/*.prompt.md`: os comandos do ciclo, apontando para `.claude/commands/`.
- `.github/workflows/copilot-setup-steps.yml`: prepara o agente de nuvem com histórico completo, `gitleaks` e githooks ligados. O passo da stack é completado no `/bootstrap`.

**A validar na primeira rodada com o Copilot:** os nomes de arquivo e os campos `name`, `description` e `tools` (`read`, `search`, `edit`, `execute`) vêm do changelog e de guias do GitHub. A documentação oficial não foi consultada diretamente.

## Teste de portabilidade (5 minutos por ferramenta)

Abra uma sessão nova na ferramenta, num projeto instanciado, **sem explicar nada nem mandar ler arquivo**, e pergunte:

1. Qual é o processo de desenvolvimento deste repositório e onde ele está descrito?
2. Qual comando verifica tudo antes de afirmar que algo funciona?
3. Quem faz o merge na branch principal?
4. Em que branch você faria a task `<uma task existente>`? Quem cria essa branch?
5. Se eu pedir "faça o RED da task `<a mesma>`", qual é o seu papel e o que você nunca faz? E sem brief nenhum, quem é você nesta sessão?

**Passa** se a ferramenta acerta as cinco perguntas a partir dos arquivos do projeto. **Falha** se precisou ser mandada ler o `AGENTS.md`, ou se inventou regra. Registre o resultado abaixo, com a data e a versão da ferramenta.

| Ferramenta | Data | Resultado | Observação |
|---|---|---|---|
| Kiro | 2026-10 | passou (relatado pelo humano) | teste direto no `action-plan` |
| Antigravity | 2026-10 | passou (relatado pelo humano) | teste direto no `action-plan` |
| GitHub Copilot | 2026-10 | falhou (relato de terceiro) | só entendeu o contexto depois de mandado ler o `AGENTS.md`; criou várias branches. Anterior ao `adapters/copilot/` |
