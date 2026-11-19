# Portabilidade entre ferramentas de agente

O núcleo (`core/`, `mecanismos/`) é neutro. O que muda de uma ferramenta para outra é **como ela encontra as instruções** e **quais controles locais ela respeita**.

## O que vale em qualquer ferramenta

| Controle | Como funciona |
|---|---|
| Githooks (`agentic/mecanismos/githooks`) | O git os executa para qualquer autor. Num clone novo ficam desligados (`core.hooksPath` é configuração local), e por isso a etapa `hooks` do `verify` falha até alguém ligá-los. |
| `verify.sh` | Script `sh`. Numa branch com nome imposto pela ferramenta, `--task <task.md>` informa a task. Sem a principal local (clone de CI ou de nuvem), a base é `origin/<principal>`. |
| CI rodando o `verify` + proteção da principal | Roda no servidor, fora do alcance do agente. É a guarda que nenhum produto contorna. |

`deny`, hooks de sessão e a lista de ferramentas por agente são específicos de cada produto. No Claude Code, quem os instala é o `adapters/claude-code/`; no Codex e no Antigravity, os hooks dos adaptadores, ativados pelo humano. As listas de comandos negados e de caminhos protegidos vivem em `adapters/comum/` e o `coerencia-kit` confere que batem com o `deny` do Claude. Onde não houver equivalente, a regra fica "por revisão".

## Onde mora a persona de cada papel

| Camada | Arquivo | Dono |
|---|---|---|
| Contrato | `agentic/processo/papeis/<papel>.md` | kit; não se edita na instância |
| Perfil | `agentic/projeto/papeis/<papel>.md` | projeto; o kit nunca toca: especialização, stack, padrões, proibições |
| Adaptador | `.claude/agents/<papel>.md`, `.github/agents/<papel>.agent.md`, `.codex/agents/<papel>.toml`, `.agents/agents/<papel>.md` | kit; ponteiro fino para o contrato |

A persona nunca vai para o adaptador. Toda ferramenta segue o mesmo caminho: AGENTS.md → contrato → perfil. O contrato manda ler o perfil, e o brief (montado por `agentic/processo/templates/brief.md`) traz os dois caminhos.

O `instalar.sh` grava `agentic/processo/.kit-manifesto` (sha256 de cada arquivo do kit) e, na reinstalação, troca sem merge o arquivo que ainda bate com o manifesto. O `checa-instancia.sh` acusa contrato editado na instância e caminho citado num perfil que não existe.

## Como cada ferramenta encontra as instruções

| Ferramenta | Arquivo que lê sem pedir | Adaptador no kit |
|---|---|---|
| Claude Code | `CLAUDE.md` (aponta para o `AGENTS.md`) | `adapters/claude-code/` (sempre instalado) |
| GitHub Copilot | `.github/copilot-instructions.md`; o `AGENTS.md` depende da superfície e da versão | `adapters/copilot/` (`instalar.sh <projeto> --copilot`) |
| Codex | `AGENTS.md` | `adapters/codex/` + `adapters/agents-skills/` (`instalar.sh <projeto> --codex`) |
| Antigravity | `AGENTS.md` (regra sempre ativa) | `adapters/antigravity/` + `adapters/agents-skills/` (`instalar.sh <projeto> --antigravity`) |
| Outras | depende da ferramenta; confirme com o teste abaixo | nenhum |

As opções combinam em qualquer ordem (`--copilot --codex --antigravity`). Reinstalar sem opção mantém os adaptadores que o manifesto registra. Codex e Antigravity dividem as skills em `.agents/skills/<comando>/SKILL.md`, uma por comando do Claude, apontando para `.claude/commands/<comando>.md`.

**Windows.** Codex e Antigravity rodam comandos pelo PowerShell, onde `sh` não está no PATH e `bash` costuma ser o do WSL. Os hooks e as skills usam o lançador `git -c alias.agentic-sh=!sh agentic-sh <script>`: o git roda o alias com o `sh` dele, a partir da raiz do repositório, e repassa a entrada e o código de saída.

O adaptador do Copilot traz:
- `.github/copilot-instructions.md`: aponta para o `AGENTS.md` e repete só as regras invioláveis.
- `.github/agents/<papel>.agent.md`: um agente por papel, apontando para o contrato; o `revisor` tem `edit` só para gravar o parecer ("escreve só o parecer" é verificado na conferência ao receber).
- `.github/prompts/*.prompt.md`: os comandos do ciclo, apontando para `.claude/commands/`.
- `.github/workflows/copilot-setup-steps.yml`: prepara o agente de nuvem com histórico completo, `gitleaks` e githooks ligados. O passo da stack é completado no `/bootstrap`.

**A confirmar na documentação do GitHub:** nomes de arquivo e campos `name`, `description` e `tools` (`read`, `search`, `edit`, `execute`).

## Codex

O adaptador traz:
- `.codex/agents/<papel>.toml`: `name`, `description` e `developer_instructions` apontando para o contrato. Sem `model`: o nível do papel vem de `modelos.md` e é aplicado pelo humano.
- Proteções, instaladas pelo `ativar-protecoes.sh` a partir de `agentic/.estado/protecoes-pendentes/`:
  - `.codex/rules/agentic.rules`: um `prefix_rule` `forbidden` por comando do `deny` do Claude, e `allow` para os do `allow`;
  - `.codex/hooks.json` e `.codex/hooks/guarda.sh`: no `PreToolUse`, o comando passa pela lista de negados e pelo `.claude/hooks/pre-tool-use.sh` (desvio dos githooks, varredura de disco), e o `apply_patch` é negado se tocar um arquivo de proteção. No `SessionStart`, o `status-projeto.sh` vira contexto.

Garantido pela ferramenta, depois da ativação: os bloqueios acima. **Condição:** o Codex só carrega `.codex/` de projeto confiável, e cada hook precisa ser aprovado em `/hooks`. Sem isso, e em `danger-full-access`, valem só os githooks e a CI.

Por revisão: "o revisor escreve só o parecer" e "o oráculo só lê" (o agente herda sandbox e aprovação da sessão); o modelo de cada papel.

## Antigravity

O adaptador traz:
- `.agents/agents/<papel>.md`: frontmatter `name` e `description`, corpo apontando para o contrato. Sem `tools`, porque um nome de ferramenta errado trava o subagente, e sem `model`.
- Proteções, instaladas pelo `ativar-protecoes.sh`: `.agents/hooks.json` e `.agents/hooks/`. O `guarda.sh` responde `deny` a `run_command` com comando negado ou que pula os githooks, e às ferramentas de escrita num arquivo de proteção. O `inicio.sh` injeta o status no início da sessão.

Garantido pela ferramenta: os bloqueios do hook. O Antigravity não tem lista de permitidos e negados no repositório (só nas configurações do usuário); o hook cobre esse papel.

Por revisão: "o revisor escreve só o parecer", "o oráculo só lê" e o modelo de cada papel. Se o subagente não tiver worktree próprio (a confirmar no teste real), vale a regra do `AGENTS.md` para ferramenta sem isolamento: o orquestrador grava o brief e pede ao humano uma sessão nova.

**A confirmar no teste real (Codex e Antigravity):** que o hook roda no Windows e bloqueia. Depois do `ativar-protecoes.sh`, peça ao agente um `git commit --no-verify -m x`: ele precisa ser barrado. E os nomes de campo do hook do Antigravity (`toolCall.args.CommandLine`, `TargetFile`). Se a entrada não tiver o campo esperado, o hook nega e avisa, em vez de deixar passar.

## Teste de portabilidade (5 minutos por ferramenta)

Abra uma sessão nova na ferramenta, num projeto instanciado, **sem explicar nada nem mandar ler arquivo**, e pergunte:

1. Qual é o processo de desenvolvimento deste repositório e onde ele está descrito?
2. Qual comando verifica tudo antes de afirmar que algo funciona?
3. Quem faz o merge na branch principal?
4. Em que branch você faria a task `<uma task existente>`? Quem cria essa branch?
5. Se eu pedir "faça o RED da task `<a mesma>`", qual é o seu papel e o que você nunca faz? E sem brief nenhum, quem é você nesta sessão?

**Passa** se a ferramenta acerta as cinco perguntas a partir dos arquivos do projeto. **Falha** se precisou ser mandada ler o `AGENTS.md` ou se inventou regra.
