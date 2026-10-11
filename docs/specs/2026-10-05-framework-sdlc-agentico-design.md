# Framework de SDLC Agêntico — Design (v1)

**Data:** 2026-10-05
**Status:** aprovado
**Integrado:** na main em 2026-10-06
**Autor:** mantenedores do framework (decisões) · Claude (redação)

## 1. Objetivo

Criar uma **referência reutilizável de SDLC agêntico**: a estrutura de agentes, artefatos, gates e mecanismos que conduz o desenvolvimento de software com IA, **independente de stack**. O profissional instala o framework num projeto (novo ou existente), responde uma entrevista sobre contexto e stack, e o framework instancia os agentes e controles daquele contexto. A partir daí, todo desenvolvimento segue o ciclo agêntico.

Este repositório contém **apenas a parte agêntica**. Não contém código de produto.

### Critérios de sucesso

1. Um projeto Python novo e um projeto Node/TypeScript existente são instrumentados pelo mesmo núcleo, sem editar o `core/` (prova de agnosticismo).
2. Uma funcionalidade real percorre o ciclo completo (intent → Gate 2) num projeto-exemplo, com registro do que ficou desconfortável.
3. Todo mecanismo de controle tem suíte de testes com casos que **devem** bloquear e casos que **não devem** bloquear.
4. Toda regra do `core/` é rastreável até sua origem (referências teóricas, prática de projetos de referência) ou é marcada como proposta não validada.

## 2. Contexto e fontes

O design consolida três fontes:

- **Teoria:** referências teóricas (AGENTS.md; Continuous Quality Gates for Agentic PRs; Bridging AI Agents and CI/CD Quality Gates; Capture as intent.md — Claude Academy; Repository Guardrails for AI-Generated Code; Framework Corporativo de SDLC com IA; Research report de SDLC agêntico). Ressalva: o "Framework Corporativo" foi gerado por IA e seus números (36 agentes, scores RMI/ARS) são propostas, não prática validada.
- **Prática enxuta:** um projeto de referência enxuto — ciclo baseado no plugin superpowers, baixo retrabalho (1 revert em mais de 500 commits). Atrito: `CLAUDE.md` inchado (110 KB, estado duplicado), contagens escritas à mão que envelheceram.
- **Prática controlada:** um projeto de referência com mais controle — contratos de papéis portáveis, `agentic/mecanismos/githooks`, estado derivado, "Verificado por". Exigiu grandes rodadas de correção; as lições dessas rodadas são a principal entrada deste design.

### Lições que moldam o design

| Lição | Origem |
|---|---|
| Prompt é orientação; só mecanismo determinístico diz "não" | [RG]; projeto de referência controlado (varredura de disco órfã por 7h apesar da regra em prosa) |
| Erro repetido 2x vira mecanismo, não terceira instrução | projeto de referência controlado |
| Plugin genérico de processo compete com o processo do projeto | projeto de referência controlado (plugin de processo removido) |
| Parser de texto de comando é corrida armamentista; hook nativo do git é a defesa sólida | projeto de referência controlado (15→20 bypasses) |
| Agente afirma controles que não existem → todo controle declara "Verificado por" | projeto de referência controlado (CI nunca verde) |
| Espera humana domina o tempo de ciclo → concentrar decisões num gate com questionário | projeto de referência controlado (3–4h de espera / tasks de 20–40min) |
| Cerimônia cresce mais rápido que o código | projeto de referência controlado (reestruturação: 11 ADRs, 7→5 agentes) |
| Estado escrito à mão envelhece em um dia → estado derivado | ambos os projetos de referência |
| Revisor separado do autor, em contexto limpo, nunca corrige | [RG]; ambos os projetos de referência |
| Roteamento de modelo por tipo de task | projeto de referência enxuto |
| Expansão de escopo plausível é o antipadrão mais comum | [RG] |

## 3. Decisões

1. **Portabilidade:** Claude Code primeiro, mas portável. Núcleo em Markdown neutro; adaptador fino para Claude Code. Outras ferramentas apontam para os mesmos contratos.
2. **Autocontido:** o framework não depende do plugin superpowers. Incorpora seus padrões validados (registro de execução por task, roteamento de modelo, revisão por diff, verificar antes de afirmar). Projetos que usam o framework mantêm o plugin desligado.
3. **Distribuição:** template com bootstrap guiado. O kit é copiado para o projeto, que passa a ser dono do que foi gerado. Versionamento/upgrade fica para depois de haver segundo adotante.
4. **Escopo do ciclo:** da intenção ao merge. Deploy e operação entram apenas como interfaces.
5. **Agentes:** núcleo fixo de 5 papéis + oráculos opcionais gerados. A stack é conhecimento injetado nos papéis, não novos papéis.
6. **Escopo de task:** lista de arquivos declarada e verificada mecanicamente. Sem limite fixo de linhas.
7. **Idioma:** documentação e contratos em português; scripts em POSIX `sh` (o Git para Windows já fornece `sh`).

## 4. Arquitetura

```
framework-sdlc-agentico/
├── core/                       NEUTRO
│   ├── principios.md
│   ├── processo/ciclo.md, processo/modelos.md
│   ├── papeis/                 dominio, arquiteto, testes, dev, revisor, _oraculo
│   └── templates/              intent, spec, design, task, decisoes, AGENTS.md, pr
├── mecanismos/                 DETERMINÍSTICO, sem dependência de ferramenta
│   ├── githooks/               pre-commit, pre-push, pre-merge-commit (+ .Tests.sh)
│   └── scripts/                status-projeto, verifica-red, verifica-escopo,
│                               verifica-skip, verify — lê agentic/config (+ .Tests.sh)
├── adapters/claude-code/       ADAPTADOR FINO
│   ├── agents/                 frontmatter + "leia core/papeis/X.md"
│   ├── commands/               bootstrap, nova-task, verify, status
│   ├── hooks/                  SessionStart, PreToolUse mínimo
│   └── settings.json.tmpl
├── adapters/copilot/           ADAPTADOR FINO (opcional: instalar.sh --copilot)
│   ├── copilot-instructions.md ponteiro para AGENTS.md + regras invioláveis
│   ├── agents/, prompts/       "leia core/papeis/X.md" / "siga .claude/commands/X.md"
│   └── copilot-setup-steps.yml agente de nuvem: histórico, gitleaks, githooks
├── bootstrap/
│   ├── instalar.sh             copia o kit e configura core.hooksPath
│   └── entrevista.md           blocos de perguntas e mapeamento para artefatos
├── exemplos/                   python-cli-novo/, node-servico-existente/
├── docs/
│   ├── origem.md               rastreabilidade regra → fonte
│   └── specs/
└── scripts/verify.sh           verificação do próprio framework
```

**Mapeamento no projeto alvo após o bootstrap.** Na raiz entra só o que as ferramentas exigem lá (`AGENTS.md`, `CLAUDE.md`, `.claude/`, uma linha em `.gitignore` e `.gitattributes`); todo o resto vive em `agentic/`, separado entre o que é do kit e o que é do projeto:

| Origem no framework | Destino no projeto |
|---|---|
| `core/principios.md`, `core/processo/`, `bootstrap/entrevista.md` | `agentic/processo/principios.md`, `agentic/processo/ciclo.md`, `agentic/processo/modelos.md`, `agentic/processo/entrevista.md` |
| `core/papeis/` (instanciados) | `agentic/processo/papeis/` |
| `core/templates/` | `agentic/processo/templates/` |
| `core/templates/AGENTS.md` (instanciado) | `AGENTS.md` (raiz) |
| `mecanismos/githooks/` | `agentic/mecanismos/githooks/` (`core.hooksPath`) |
| `mecanismos/scripts/` | `agentic/mecanismos/scripts/` |
| `adapters/claude-code/` | `.claude/` + `CLAUDE.md` mínimo |
| `adapters/copilot/` (com `--copilot`) | `.github/copilot-instructions.md`, `.github/agents/`, `.github/prompts/`, `.github/workflows/copilot-setup-steps.yml` |
| `bootstrap/config.padrao`, `bootstrap/auto-mode.padrao` | `agentic/config`, `agentic/auto-mode` (versionados; política) |
| — | `agentic/projeto/`: `bootstrap.md`, `decisoes.md`, `intent/`, `specs/` (artefatos do projeto; o kit nunca os toca) |
| — | `agentic/.estado/`: `execucao/`, `worktrees/`, `verify.lock/`, `kit-conflitos/`, `settings.pendente.json` (efêmero, uma linha no `.gitignore`) |

## 5. Princípios-meta (`core/principios.md`)

1. **Prompt orienta, mecanismo controla.** Toda regra declara `Verificado por:` com o mecanismo ou "por revisão".
2. **Erro repetido 2x vira mecanismo.** Controle que nunca pega nada é candidato a remoção.
3. **Estado é derivado, nunca escrito à mão.** Fonte: git + campos `Status:`. Exibido no início de cada sessão.
4. **Afirmações técnicas são marcadas `medido` ou `inferido`.** Nada é declarado funcionando sem a saída vista.
5. **O agente nunca integra e nunca altera as próprias permissões.** Merge e permissões são do humano.
6. **Memória enxuta.** `AGENTS.md`/`CLAUDE.md` são mapa e regras; narrativa vai para documentos datados; números são gerados por script.
7. **Erros pequenos, visíveis e reversíveis.** Workspace isolado por sessão; descartar uma execução ruim deve ser barato.

## 6. Ciclo (`core/processo/ciclo.md`)

### Trilha padrão (funcionalidade ou mudança de comportamento)

| # | Fase | Papel | Artefato | Verificação |
|---|---|---|---|---|
| 0 | Intenção | humano + `dominio` | `agentic/projeto/intent/NNN-<nome>.md` | — |
| 1 | Especificação | `dominio` | `agentic/projeto/specs/<nome>/spec.md` + questionário de decisão | `revisor` modo spec |
| 2 | Design | `arquiteto` | `design.md` + contrato executável + `tasks/NNN-*.md` | `revisor` modo design |
| G1 | **Gate 1** | humano | aprova intent+spec+design; responde questionário; nenhuma `hipótese` passa | — |
| 3 | RED | `testes` | testes falhando, sem código de produção (o documento da task pode ser atualizado no mesmo commit); commit `test(red):` | `verifica-red` |
| 4 | GREEN + REFACTOR | `dev` | `feat(green):`, `refactor:` | `verify` |
| 5 | Revisão | `revisor` modo diff | parecer com achados Crítico/Importante/Menor | — |
| 6 | Publicação | agente | push + PR pelo template | — |
| G2 | **Gate 2** | humano | merge sem squash | `deny` mecânico de merge ao agente |

Revisões que devolvem achados Crítico ou Importante voltam ao papel autor; achados Menores ficam registrados para a revisão final da branch.

### Trilha rápida

`chore`, `docs`, ferramental, correção sem mudança de comportamento: branch → `verify` → PR → Gate 2.

### Escalonamento N3

Gatilhos que interrompem a execução fora dos gates e exigem humano. Genéricos do framework: mudança de contrato público, segurança/autenticação/autorização, migração destrutiva de dados, dependência nova, edição de caminho protegido. O bootstrap acrescenta gatilhos da stack. `Verificado por: revisão` (não há mecanismo que impeça o agente de seguir sem escalar; declarado honestamente). Itens N3 já visíveis no design são listados em `design.md` e aprovados um a um no Gate 1; a task cita os que usa e só N3 novo (fora da lista) interrompe a execução.

### Regras de fluxo

- **Escopo:** cada task declara `Arquivos:`. Arquivo fora da lista faz o `verify` falhar, salvo justificativa em commit `docs(task):` no mesmo PR.
- **Divergência spec × código:** parar, registrar em "Questões em Aberto", corrigir via `docs(spec):` no mesmo PR.
- **Isolamento:** um worktree por sessão/trilha. Nunca duas sessões no mesmo diretório.
- **Modo automático:** `agentic/auto-mode` versionado (`enabled: true|false`). Ligado: encadeia tasks e publica PRs sem confirmação. Nunca faz merge.
- **Registro de execução:** o orquestrador mantém `agentic/.estado/execucao/<data>-<nome>/` com `progress.md`, `task-N-brief.md`, `task-N-relatorio.md`, e registra **Rulings** quando decide algo não previsto no plano. Permite retomar sessões interrompidas.
- **Orquestrador:** é a sessão principal guiada por `ciclo.md`, não um papel.

### Interfaces para a v2 (não implementadas)

- Incidente → novo `agentic/projeto/intent/` (campo `Origem: incidente <id>`).
- Gate de release consome as evidências do PR (RED/GREEN, `verify`, parecer do revisor).

## 7. Papéis (`core/papeis/`)

Estrutura fixa de cada contrato: **Quem você é** · **Consome** · **Produz** · **Nunca faz** · **Independência** · **Ao terminar** · **Contexto da stack** (bloco preenchido pelo bootstrap).

| Papel | Consome | Produz | Nunca faz | Modelo padrão |
|---|---|---|---|---|
| `dominio` | pedido humano, oráculos | intent, spec (regra com `Fonte:` humano/oráculo/decisão e estado `confirmada`/`hipótese`), questionário de decisão | sugerir stack/arquitetura; promover hipótese sem fonte | médio |
| `arquiteto` | spec aprovada, `decisoes.md` | design, contrato executável, tasks com escopo; dono único das tasks | alterar regra de negócio; implementar | forte |
| `testes` | task, contrato | testes RED só em diretórios de teste | tocar produção; fixtures redundantes | médio |
| `dev` | task, testes RED | GREEN + REFACTOR dentro do escopo | alterar/desabilitar testes RED; sair do escopo sem `docs(task):` | médio |
| `revisor` | artefato + diff, contexto limpo | parecer; abre cada citação; modos `spec`, `design`, `diff` | corrigir; revisar o que produziu | forte |
| oráculo (0..N) | fonte externa | respostas com `arquivo:linha` e juízo preservar/corrigir | escrever qualquer coisa | médio |

O orquestrador pode usar modelo **leve** em tasks de transcrição (brief traz o código completo).

**Adaptador Claude Code:** `.claude/agents/<papel>.md` contém frontmatter (`tools`, `model`) e a instrução "Leia `agentic/processo/papeis/<papel>.md`; não duplique regras aqui".

## 8. Artefatos (`core/templates/`)

- **`intent.md`:** Autor, Sponsor, Data, `Status: draft|em-revisão|aprovado|rejeitado`, Origem; Problema (quantificado quando possível); Resultado proposto; Usuários e sistemas afetados; Restrições e não-escopo; Critérios de aceite de negócio; Questões abertas.
- **`spec.md`:** `Status:`; Regras (cada uma com `Fonte:` e estado); Critérios de aceite verificáveis; Invariantes (o que não muda); Fora de escopo; Questionário de decisão; Questões em aberto; Divergências.
- **`design.md`:** `Status:`; Decisões numeradas; Contrato executável (o que é, como se valida); Itens N3 (aprovação no Gate 1); Como isso se prova; O que não muda; O desconfortável, declarado.
- **`task.md`:** `Status:`; Objetivo; `Arquivos:` (escopo); Interfaces Produz/Consome; N3 aprovados no Gate 1; Critérios de pronto; Questões em aberto.
- **`decisoes.md`:** entradas `D<n>` com Decisão · Por quê · Consequência · `Verificado por:`; seção "Decisões revogadas" (nunca apagar, marcar superação).
- **`AGENTS.md`:** Visão geral; Comandos (instalar, build, lint, teste, arquitetura, `verify`); Regras invioláveis; Estrutura do repositório; Onde estão intents/specs/decisões; "Leia `agentic/processo/ciclo.md`".
- **`pr.md`:** Intent/task de origem; Evidência RED/GREEN (hashes); saída do `verify`; Arquivos, linhas e caminhos sensíveis tocados; Parecer do revisor; O que ficou desconfortável.

## 9. Mecanismos

| Controle | Mecanismo | Camada |
|---|---|---|
| Segredos não entram | `pre-commit`: gitleaks + scan de palavras-chave sobre conteúdo staged; fail-closed | `agentic/mecanismos/githooks` |
| Branch protegida / force-push | `pre-commit`, `pre-push`, `pre-merge-commit` | `agentic/mecanismos/githooks` |
| Agente não faz merge, não força, não altera permissões | `deny` (`gh pr merge`, `git push --force*`, `git reset --hard`, edição de `.claude/settings*`) + `disableBypassPermissionsMode` | adaptador |
| Sem varredura de disco / escrita externa | `deny` de escrita fora do repositório; PreToolUse mínimo bloqueando varredura a partir da raiz | adaptador |
| Estado atual | `status-projeto.sh` no SessionStart | adaptador + script |
| RED realmente falhava | `verifica-red.sh` (worktree isolado no commit RED; com `CMD_TESTE_ARQUIVO`, cada arquivo de teste tocado pelo RED precisa falhar — sem ele, a suíte inteira, modo degradado; asserções comparadas com HEAD por arquivo, só nos arquivos de teste tocados pelo RED; RED não toca código de produção, documentação sob `docs/` e `agentic/projeto/intent/` isenta); invocado pelo `verify` quando há commit `test(red):` na branch | script |
| Escopo respeitado | `verifica-escopo.sh`: diff da branch × `Arquivos:` da task | script |
| Testes não desabilitados/pulados | `verifica-skip.sh`: lê o relatório real dos testes; padrão de "desabilitado" vem do bootstrap | script |
| Fronteiras de arquitetura | ferramenta da stack declarada no bootstrap | stack |
| Independência do revisor, N3, checklist Gate 1 | — | por revisão |

**`verify`:** ponto único. `verify.sh` genérico que lê os comandos da stack de `agentic/config` (sem templating de script), encadeado com `verifica-escopo`, `verifica-skip`, `verifica-red` e `verifica-decisoes`. Lock contra execução concorrente. O comando `/verify` só reporta, nunca conserta.

**Deliberadamente excluídos:** parser de texto de comando no PreToolUse (redundante com `agentic/mecanismos/githooks`); CI na v1. Se o projeto tiver CI, o bootstrap gera workflow que chama o mesmo `verify`, e ele só é aprovado depois de provado verde num PR de teste.

## 10. Bootstrap

**Passo 1 — `bootstrap/instalar.sh <alvo>`:** copia o kit conforme o mapeamento da seção 4, configura `git config core.hooksPath agentic/mecanismos/githooks`, adiciona `agentic/.estado/execucao/` ao `.gitignore`. Não pergunta nada. Não sobrescreve arquivos existentes: conflitos são listados e deixados para o passo 2.

**Passo 2 — `/bootstrap`:** entrevista e instanciação. Em projeto existente, o agente lê o repositório antes e propõe respostas marcadas `inferido`; o humano confirma ou corrige.

| Bloco | Perguntas | Alimenta |
|---|---|---|
| Contexto | produto, usuários, domínio, novo/existente, restrições regulatórias e de legado | `AGENTS.md`, persona do `dominio` |
| Stack | linguagens, frameworks, gerenciador de pacotes, comandos de build/lint/teste/arquitetura, marcador de teste desabilitado, formato do relatório de testes | `verify`, "Contexto da stack" dos papéis |
| Estrutura | camadas/módulos, diretórios de teste, locais de agentic/projeto/intent/spec/decisões | ferramenta de fronteiras, templates |
| Risco | caminhos protegidos, gatilhos N3 da stack, dependências sensíveis | `agentic/mecanismos/githooks`, `settings.json`, lista N3 |
| Fontes externas | sistemas legados, APIs, normas | oráculos |
| Operação | branch principal, plataforma de PR, CI, aprovadores dos Gates, modo automático | `settings.json`, `auto-mode`, template de PR |

**Saída:** artefatos instanciados; `agentic/projeto/bootstrap.md` com as respostas (re-execuções partem dele); `agentic/projeto/decisoes.md` com D1 = stack. Em projeto existente: gitleaks e ferramenta de arquitetura em modo baseline (violações atuais registradas, só novas bloqueiam); `CLAUDE.md`/`AGENTS.md` existentes recebem proposta de merge aprovada pelo humano.

**Encerramento:** roda `verify` e `status` (o primeiro deve passar ou registrar o motivo de falha) e sugere o primeiro intent. **O bootstrap nunca escreve código de produto.**

## 11. Como isso se prova

1. **Mecanismos:** cada script/hook com `.Tests.sh` cobrindo casos que devem e que não devem bloquear; executados em Git Bash (Windows) e Linux por `scripts/verify.sh` do framework.
2. **Agnosticismo:** `exemplos/python-cli-novo/` e `exemplos/node-servico-existente/` instrumentados por `instalar.sh` + `/bootstrap` com respostas pré-gravadas; checagem estrutural (arquivos presentes, nenhum placeholder residual, `verify` executa, hooks ativos).
3. **Ciclo real:** uma funcionalidade pequena percorre intent → Gate 2 num exemplo; registro em `docs/validacao-v1.md` com "o que ficou desconfortável".
4. **Teste de fogo:** bootstrap aplicado a um projeto existente maduro num worktree descartável, comparando o gerado com o que o projeto já tem. O repositório original não é alterado.

## 12. O que não muda

Os projetos de referência são apenas fontes de leitura; nenhum arquivo neles é alterado por este trabalho.

## 13. Fora de escopo (v1)

Agentes e automação de deploy/operação; adaptadores para outras ferramentas (Codex, Cursor, Copilot); `/upgrade` versionado; knowledge graph entre projetos; métricas automáticas; CI do próprio framework.

## 14. O desconfortável, declarado

- O escalonamento N3 e a independência do revisor continuam garantidos só por revisão. Nenhum dos projetos de origem encontrou mecanismo para isso.
- O questionário de bootstrap é contribuição nossa: nenhuma fonte teórica propõe um. Só a validação nos exemplos dirá se as perguntas bastam.
- `verifica-skip` depende do formato de relatório de testes de cada stack; o bootstrap precisa mapear isso por stack, e stacks sem relatório estruturado ficam com essa verificação degradada (declarada como tal).
- A validação usa dois exemplos; agnosticismo real só se confirma com adoções reais em stacks diferentes.
