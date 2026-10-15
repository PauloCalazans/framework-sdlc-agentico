# Ciclo de desenvolvimento agêntico

Leia antes de qualquer trabalho. Princípios: `agentic/processo/principios.md`. Papéis: contratos do kit em `agentic/processo/papeis/`, perfis do projeto em `agentic/projeto/papeis/`.

## Escolha a trilha

- **Trilha padrão** — funcionalidade nova ou qualquer mudança de comportamento observável.
- **Trilha enxuta** — mudança pequena de comportamento que cabe numa única task e não aciona nenhum gatilho N3 (contrato público, segurança/autenticação/autorização, migração destrutiva, dependência nova, caminho protegido, gatilhos da stack em `AGENTS.md`).
- **Trilha rápida** — `chore`, `docs`, ferramental, correção sem mudança de comportamento: branch → `verify` → PR → Gate 2.

Na dúvida, trilha padrão.

## Trilha padrão

| # | Fase | Papel | Artefato | Verificação |
|---|---|---|---|---|
| 0 | Intenção | humano + `dominio` | `agentic/projeto/intent/NNN-<nome>.md` | — |
| 1 | Especificação | `dominio` | `agentic/projeto/specs/<nome>/spec.md` + questionário de decisão | `revisor` modo `spec` |
| 2 | Design | `arquiteto` | `design.md` + contrato executável + `tasks/NNN-<nome>.md` | `revisor` modo `design` |
| G1 | **Gate 1** | humano (ou orquestrador, com o Gate 1 delegado) | aprova intent + spec + design; responde o questionário; aprova os itens N3 do design um a um | `verifica-decisoes.sh` (delegação vigente) |
| 3 | RED | `testes` | testes falhando, sem código de produção (o documento da task pode ser atualizado no mesmo commit); commit `test(red): …` | `verifica-red.sh` |
| 4 | GREEN + REFACTOR | `dev` | commits `feat(green): …` e `refactor: …` | `verify.sh` |
| 5 | Revisão | `revisor` modo `diff` | parecer com achados Crítico / Importante / Menor | — |
| 6 | Publicação | orquestrador | push + PR pelo template `agentic/processo/templates/pr.md` | — |
| G2 | **Gate 2** | humano | merge **sem squash** | merge negado ao agente |

- Achado **Crítico** ou **Importante** devolve o trabalho ao papel autor; a revisão roda de novo no diff corrigido.
- Achados **Menores** ficam registrados e são tratados na revisão final da branch, antes da publicação.
- **Gate 1 não aceita hipótese:** toda regra da spec chega ao Gate 1 com estado `confirmada`.
- **Registro do Gate 1:** depois da aprovação, o orquestrador cria a branch e o worktree da primeira task, e o primeiro commit da branch é `docs(spec): <nome> aprovada (Gate 1)` (com o Gate 1 delegado: `docs(spec): <nome> aprovada (Gate 1 delegado, D<n>)`), com intent, spec, design e tasks (`**Status:** aprovado` em intent, spec e design). As tasks seguintes da mesma spec saem da principal depois que a primeira é integrada; no modo automático, podem sair da branch da task anterior ("Branches empilhadas").
- **Gate 2 sem plataforma de PR:** o orquestrador deixa a branch rebaseada na principal; o humano integra com `git merge --ff-only <branch>`.

## Trilha enxuta

Mantém RED provado, revisor independente, escopo verificado e os dois gates humanos; troca intent + spec + design + task por **um documento** (`agentic/processo/templates/mudanca.md`, gravado em `agentic/projeto/specs/<nome>/tasks/001-<nome>.md`, onde os scripts leem `**Branch:**` e `## Arquivos`).

`/mudanca <descrição>` → `arquiteto` em modo enxuto escreve o documento → **Gate 1** (o humano aprova o documento; nenhuma hipótese) → `testes` RED → `dev` GREEN/REFACTOR → `verify` → `revisor` modo `diff` (revisa o código **e** confere se a trilha enxuta cabia) → publicação → **Gate 2** → worktree removido.

- **Elegibilidade:** a mudança cabe numa única task e não aciona nenhum gatilho N3. Na dúvida, trilha padrão.
- **Registro do Gate 1:** o commit `docs(mudanca): <nome> aprovada (Gate 1)` (delegado: `docs(mudanca): <nome> aprovada (Gate 1 delegado, D<n>)`) com o documento, primeiro commit da branch (criada com o worktree depois da aprovação).
- **Promoção:** se surgir gatilho N3 ou o `revisor` julgar a classificação errada, pare; o trabalho sobe para a trilha padrão e o documento enxuto vira rascunho do intent. Registre uma Ruling (seção "Rulings").

## Gate 1 delegado

O humano pode delegar o Gate 1 ao orquestrador, por exemplo depois de escrever um plano longo. A delegação é uma decisão do humano e vale até ser revogada.

- **Delegar:** o humano registra em `agentic/projeto/decisoes.md` a decisão `D<n> — Delegação do Gate 1`, com o plano que a orienta (versionado em `agentic/projeto/planos/`), as specs ou mudanças cobertas (ou "todas") e os itens N3 que o orquestrador pode aprovar (ou "nenhum"). Depois grava em `agentic/auto-mode` `enabled: true` e `gate1: D<n>`.
- **Revogar:** o humano move a decisão para "Decisões revogadas" e esvazia `gate1:`. Branch com Gate 1 delegado ainda não integrada volta a precisar do humano, que aprova e registra na branch `docs(spec): <nome> aprovada (Gate 1)` (ou `docs(mudanca): …`).
- **O orquestrador no Gate 1:** aprova intent, spec e design depois do `revisor` aprovar a spec (modo `spec`) e o design (modo `design`). Responde o questionário pelo plano: a regra entra `confirmada` com `Fonte: plano:<arquivo>:<linha>`. O que o plano não cobre ele decide: grava a resposta no questionário da spec (`Resposta (Gate 1 delegado, D<n>): <opção> — <motivo>`) e a regra entra `confirmada` com `Fonte: decisão:D<n>`.
- **Itens N3:** o orquestrador aprova só os incluídos na decisão; os demais param a execução e chamam o humano.
- **Fora da delegação:** o Gate 2 (merge) é sempre humano. Spec ou mudança fora do escopo da decisão segue com o Gate 1 humano.
- **Registro:** commit `docs(spec): <nome> aprovada (Gate 1 delegado, D<n>)` ou `docs(mudanca): <nome> aprovada (Gate 1 delegado, D<n>)`.
- **Revisor:** com o Gate 1 delegado, o `revisor` roda no nível forte (`agentic/processo/modelos.md`).

`Verificado por:` `verifica-decisoes.sh` (`gate1:` aponta decisão vigente; commit de Gate 1 delegado exige `enabled: true` e `gate1:` com a mesma decisão, vigente, ou um Gate 1 humano registrado depois na branch); `agentic/auto-mode` é superfície de política, só o humano edita; revisão (escopo da decisão, respostas do questionário, itens N3, nível do `revisor`).

## Escalonamento N3

Pare a execução e chame o humano — mesmo fora de um gate — quando a mudança envolver:
- contrato público (API, schema publicado, formato de arquivo consumido por terceiros);
- segurança, autenticação ou autorização;
- migração destrutiva de dados;
- dependência nova;
- caminho protegido;
- qualquer gatilho adicional listado em `AGENTS.md` (seção "Gatilhos de escalonamento").

**Itens N3 previstos no design:** o `arquiteto` lista em `design.md` ("Itens N3 (aprovação no Gate 1)") todo gatilho N3 já visível no desenho, e o humano aprova cada item explicitamente no Gate 1. A task cita em "N3 aprovados no Gate 1" os itens que usa. Item previsto no design e aprovado no Gate 1 não exige nova parada; só N3 novo (fora da lista) interrompe a execução.

`Verificado por:` revisão (o `revisor` em modo `design` confere que todo gatilho N3 visível está na lista; em modo `diff`, que toda mudança N3 do diff está em "N3 aprovados no Gate 1" da task).

## Regras de fluxo

- **Isolamento:** um worktree por sessão/trilha, dentro do repositório: `git worktree add agentic/.estado/worktrees/<nome> -b <branch>`, onde `<nome>` é a branch com `/` trocado por `-` (ex.: `pedidos/001-criar` → `agentic/.estado/worktrees/pedidos-001-criar`). Nunca duas sessões no mesmo diretório. Subagentes recebem caminhos absolutos do worktree. Depois que o humano integrar (Gate 2), o orquestrador remove o worktree com `git worktree remove agentic/.estado/worktrees/<nome>` e a branch com `git branch -d <branch>` (só `-d`, nunca `-D`). O estado `integrada` não é escrito: deriva do git (branch contida na principal / removida). Se o `-d` recusar, atualize antes a principal local — nunca `-D`.
- **Branches:** só o orquestrador cria branch e worktree, uma branch por task (ou por mudança da trilha rápida), com o nome exato do `**Branch:**` da task; nenhum papel cria branch. Ferramenta que impõe o próprio nome de branch (ex.: agente de nuvem que abre `copilot/…`) roda o verify com `--task <task.md>`.
- **Branches empilhadas:** no modo automático, a task seguinte pode sair da branch da task anterior ainda não integrada: `git worktree add agentic/.estado/worktrees/<nome> -b <branch> <branch anterior>`. A task declara `**Base:** <branch anterior>`; enquanto essa branch não está na principal, o `verify.sh` compara com ela, e depois com a principal. O PR diz `Empilhado sobre: <PR anterior> — integre nesta ordem`. Correção na branch anterior chega às empilhadas por `git merge <branch anterior>`, nunca por rebase de branch publicada. O merge sem squash mantém o empilhamento válido.
- **Escopo:** cada task declara `## Arquivos`. `verify.sh` falha se a branch tocar arquivo fora da lista. Ampliar o escopo exige atualizar a lista num commit `docs(task): …`.
- **Divergência spec × código:** pare, registre em "Questões em aberto" da spec e corrija via commit `docs(spec): …` no mesmo PR.
- **Verificação:** `sh agentic/mecanismos/scripts/verify.sh` é o ponto único. Ninguém afirma sucesso sem ter visto a saída.
- **Commits:** `test(red):`, `feat(green):`, `refactor:`, `fix:`, `docs(spec):`, `docs(task):`, `chore:`. Um commit por passo do ciclo.
- **Status dos artefatos** (`**Status:**`, lido por `status-projeto.sh`): no Gate 1 o humano aprova e intent, spec e design passam de `draft` a `aprovado`; `/nova-task` põe a task em `em-andamento`; com a revisão aprovada, o orquestrador a põe em `em-revisão` e, ao publicar (fase 6), em `publicada`; `integrada` não é um Status escrito (ninguém commita na principal protegida): deriva do git — branch contida na principal ou removida.
- **Modo automático:** se `agentic/auto-mode` contém `enabled: true`, o orquestrador encadeia tasks (empilhando branches quando a anterior não foi integrada) e publica PRs sem pedir confirmação. Com `gate1: D<n>`, também aprova o Gate 1 ("Gate 1 delegado"). Nunca faz merge.

## Orquestração

O orquestrador não é um papel. Qual sessão o é (com e sem orquestrador externo, com e sem subagentes) está em `AGENTS.md`, "Quem é você neste repositório". Ele:
1. lê `status-projeto` (injetado no início da sessão) e escolhe a próxima task;
2. cria o worktree e o registro de execução em `agentic/.estado/execucao/<AAAA-MM-DD>-<nome>/`:
   - `progress.md` — task atual, SHA base, próximo passo;
   - `task-N-brief.md` — o que o papel recebe; começa com `Papel: <papel>` e traz os caminhos absolutos do contrato do papel (`agentic/processo/papeis/<papel>.md`) e do perfil (`agentic/projeto/papeis/<papel>.md`), a task, o contrato executável, os caminhos absolutos do worktree e os comandos. O perfil vai no brief mesmo que o contrato já o cite;
   - `task-N-relatorio.md` — o que o papel devolveu (`FEITO` / `FEITO_COM_RESSALVAS` / `BLOQUEADO`) e o parecer do revisor;
3. despacha cada papel com o brief; nunca implementa ele mesmo;
4. registra uma **Ruling** sempre que decide algo não previsto na spec, no design ou na task (seção "Rulings");
5. escolhe o modelo de cada papel por `agentic/processo/modelos.md` (nível de partida, ajuste por dado, composição do time com mais de um produto).

## Rulings

Ruling é a decisão do orquestrador que a spec, o design e a task não previam: ordem ou divisão das tasks, empilhamento de branches, devolução a um papel, escolha entre pareceres, promoção de trilha.

- **Onde:** seção `## Rulings` do documento da task (`agentic/projeto/specs/<nome>/tasks/NNN-<nome>.md`), uma linha por decisão: `R-<n> (<fase>): <o quê> — por quê: <…> — descartado: <alternativa>`. Entra no commit seguinte da branch (`docs(task): …`). O `progress.md` guarda só o estado da execução.
- **Limite:** Ruling não muda regra de negócio nem aprova item N3: regra de negócio segue a regra de divergência; item N3 é aprovado no Gate 1 (humano ou delegado), e N3 fora da lista para a execução.
- **PR:** a seção "Decisões do orquestrador" do template lista as Rulings da task (ou `nenhuma`). No último PR de uma série empilhada, lista também as das tasks anteriores da mesma spec.
- **Relatório ao humano:** ao publicar, o orquestrador lista as Rulings da task e aponta as que pedem confirmação.
- **Promoção:** Ruling que vale além da task vira `D<n>` em `agentic/projeto/decisoes.md` e a linha da Ruling cita a decisão. Com o Gate 1 delegado, o orquestrador registra a decisão citando a delegação; sem ela, propõe ao humano.

`Verificado por:` revisão (o `revisor` em modo `diff` confere cada Ruling contra a spec e o design; nenhum mecanismo detecta decisão não registrada).

## Interfaces para versões futuras (não implementadas)

- **Incidente → intent:** um incidente gera `agentic/projeto/intent/NNN-<nome>.md` com `Origem: incidente <id>`.
- **Release:** um gate de release consome as evidências do PR (RED/GREEN, saída do `verify`, parecer do revisor).
