# Brief e parecer estruturados — Design

**Data:** 2026-11-06
**Status:** aprovado (2026-11-06)
**Autor:** mantenedor do framework (decisões) · Claude (redação)
**Origem:** parecer do orquestrador do projeto de referência controlado, de 2026-11-06, sobre 114 briefs reais (2026-10-27 a 2026-11-06), o modelo de brief em teste no projeto e os incidentes com papéis despachados em ferramentas de orquestração.

## 1. Intenção

O kit diz **o que** o brief contém (`core/processo/ciclo.md`, "Orquestração", item 2), mas não diz **como** ele é montado. O projeto de referência preencheu essa lacuna à mão, e a forma que funcionou não chegou ao kit.

O motivo não é estilo, é custo de contexto. Cada requisição de um papel reenvia o contexto inteiro. Arquivo lido inteiro, saída de shell larga e exploração sem rumo são contexto inútil para a tarefa, e isso vale em qualquer ferramenta e com qualquer modelo. No projeto de referência:

| Brief | Requisições | Cache lido |
|---|---|---|
| testes, sem modelo de brief | 117 | 25,8M |
| testes, com modelo | 69 | 5,3M (−80%) |
| dev, com modelo e teto ignorado | 219 | 27,7M |
| dev, com modelo, teto explícito e acompanhado | 61 | 6,5M |

O que derrubou o custo foi "leia só isto (arquivo:linhas)", comando com saída curta e teto declarado.

Há um segundo efeito, também medido: uma regra que está só no contrato linkado não é seguida por modelo barato. O brief é o texto que o papel lê com atenção. Os desvios de "Nunca faz" e "Independência" pararam quando o brief passou a trazer essas cláusulas coladas, escritas como ação ("PARE e diga").

## 2. Objetivos

1. **Template de brief** usado em todo despacho, de todo papel, em toda rodada.
2. **Seção "No brief"** em cada contrato de papel: as cláusulas que o orquestrador cola no brief.
3. **Relatório em arquivo**: o papel grava o relatório no arquivo que o brief indica e devolve uma linha. Vale sempre, não só com orquestrador externo, porque também poupa o contexto do orquestrador.
4. **Template de parecer** e revisor autorizado a escrever só o parecer.
5. **Conferência no recebimento**: o orquestrador roda os mecanismos que já existem antes de passar a entrega adiante.

## 3. Não objetivos

- **Nada específico de orquestrador ou ferramenta**: worker de fumaça, reabertura de worker, sintaxe do Orca ou do Maestri, prompts de trust. O orquestrador descobre isso durante a execução e anota na memória do projeto. Nada entra em `docs/portabilidade.md` nem em `adapters/` além do item 6 da seção 5.
- **Regras novas de papel trazidas como cópia.** O parecer de origem propôs colar cláusulas que nenhum contrato do kit tem: teste de caracterização em commit `test:` separado; "nunca reduza asserção existente" para o `testes`; "só a task corrente na branch" para o `arquiteto`. Elas ficam fora. Cada uma, se o dono quiser, entra depois por mudança própria, com `Verificado por:`.
- **Medição de tokens, comandos de stack e escalação de modelos**: ficam no projeto.
- **Versionar todo parecer.** Pareceres ficam locais (seção 5.4).
- **Verificador ou gerador de brief** (`verifica-brief.sh`, `monta-brief.sh`), proposto no parecer de origem (K9). Um protótipo rodou nos 115 briefs do projeto de referência e os resultados não justificam o mecanismo agora:
  - Na primeira rodada, 56 de 61 briefs seriam barrados, quase todos por caminho relativo do contrato. Esses briefs funcionaram, porque o papel roda no worktree, onde o contrato existe.
  - Na correção, 32 de 54 seriam barrados (sem teto, sem âncora, `Papel:` com nome errado). Nenhum desses briefs está ligado a um incidente medido.
  - Como o brief não é commitado, nada obriga a rodar o verificador. Ele seria "por revisão", como o template, e cairia no momento de pressa em que o brief malfeito sai.
  - Ele só olha a forma; o conteúdo, onde moram os erros caros, fica de fora.

  A causa, a correção escrita só com o delta, é atacada no template (seção 5.1, "Rodada de correção"). Pelo Princípio 2, se um brief malformado sair duas vezes com o template em uso, entra um mecanismo, de preferência no ponto de despacho (hook do adaptador), onde ele é obrigatório.

## 4. Anti-objetivos

- **O brief virar um segundo contrato colado inteiro.** Isso traz o custo de volta. O template impõe "leia só isto", teto e cláusulas curtas, com meta de até ~40 linhas.
- **Enchimento para cumprir campo obrigatório.** Seção obrigatória significa seção presente. Quando não há nada a dizer, escreve-se `nenhum`, e isso basta.
- **Exemplo ou regra de stack no kit.** `Select-Object`, Maven, `flutter`, `worker_done` e "ask do Orca" não aparecem em `core/`. O comando concreto vem do `AGENTS.md` e do perfil.
- **Citar o projeto de referência, as pessoas ou os nomes de papéis dele** em artefato, commit ou PR do kit.

## 5. Desenho

### 5.1 `core/templates/brief.md` (novo)

É um bloco para o orquestrador preencher, com um comentário de preenchimento no topo, no estilo de `perfil-papel.md`. A primeira linha é o cabeçalho; as demais são seções `## `, nesta ordem.

**Cabeçalho (obrigatório).** São quatro linhas fixas, iguais em todo brief. Os caminhos são absolutos sempre, inclusive em rodada de correção.

```
Papel: <papel exato do kit>[ — modo <modo>]
Contrato: <caminho absoluto de agentic/processo/papeis/<papel>.md>
Perfil: <caminho absoluto>[; <caminho absoluto> …]
Task: <caminho da task ou do documento enxuto> — fase <n>
```

Pode haver mais de um perfil, como o perfil geral do revisor mais um perfil por camada.

**Seções obrigatórias** (presentes sempre; `nenhum` quando vazias):

| Seção | Conteúdo |
|---|---|
| `## Escopo` | Worktree absoluto, branch e caminhos de escrita. Fora deles: "PARE e pergunte" pelo canal de dúvida. |
| `## O que fazer` | Até 5 linhas, cada uma com uma entrega verificável. |
| `## Já decidido` | Rulings, respostas e itens N3 que o papel não reabre, um por linha. |
| `## Nunca faz` | As cláusulas da seção "No brief" do contrato que valem nesta rodada, mais os itens de "Padrões" e "Nunca faz neste projeto" do perfil que se aplicam. Coladas, em forma de ação. |
| `## Leia só isto` | `arquivo:linha-linha`, com até ~80 linhas por trecho e o motivo da leitura. Nada de "leia o arquivo" nem "veja o commit". |
| `## Comandos` | Comandos exatos, com saída limitada e em primeiro plano. Diz quais verificações longas o papel roda e quais o orquestrador roda. Lista o que é proibido rodar. **Exceção:** o brief nunca tira do `revisor` o `verify.sh`, porque é a independência dele (seção 5.3). |
| `## Teto` | Número de requisições (ou turnos, na ferramenta que não conta requisições) e a ação ao atingi-lo: parar, comitar o que estiver pronto se o papel comita e reportar onde travou. |
| `## Entrega` | Commits (tipo e mensagem, sem push), o caminho absoluto do arquivo de relatório, o formato da linha de retorno e o canal de dúvida. |

**Seções condicionais:**

| Seção | Quando |
|---|---|
| `## Desde a rodada anterior` | Em rodada de correção, obrigatória: o brief anterior (caminho), o parecer ou relatório que motivou a rodada (caminho e IDs dos achados) e o que mudou. Ela não substitui nenhuma outra seção. |
| `## Assinaturas` | Em `testes` e `dev`, quando há contrato executável: tipos, métodos e records colados, para o papel não precisar procurar. |
| `## API externa` | Em `testes` e `dev`, quando o papel usa biblioteca externa: um snippet pronto. |

**Rodada de correção.** O orquestrador copia para um arquivo novo o brief anterior do mesmo papel, inteiro: cabeçalho, escopo, nunca faz, comandos, teto e entrega. Nesse arquivo, ele reescreve "O que fazer", acrescenta "Desde a rodada anterior" e ajusta o resto só onde a rodada mudou (por exemplo, um commit novo a fazer passar ou um novo caminho de relatório). Nunca escreve "mesmo contrato", "mesmo escopo do brief anterior" nem "continuação". Motivo: no projeto de referência, os briefs de correção saíam só com o que mudou porque reescrever tudo custava. Copiar o anterior tira esse custo.

**Nome dos arquivos, na pasta de execução** `agentic/.estado/execucao/<AAAA-MM-DD>-<nome>/`:

- Brief: `NN-<papel>[-<modo>]-brief.md`.
- Relatório: `NN-<papel>[-<modo>]-relatorio.md`; no caso do revisor, `NN-revisor-<modo>-parecer.md`.
- `NN` é a ordem do despacho na pasta (`01`, `02`, …). Assim cada papel e cada rodada têm arquivo próprio, e a ordem se lê pelo nome.

**Linha de retorno:** `NN-<papel>: <STATUS> | <campos do papel> | <arquivo de relatório>`.

- `STATUS` é `FEITO`, `FEITO_COM_RESSALVAS` ou `BLOQUEADO`.
- No revisor, `STATUS` é `APROVADO | C n I n M n` ou `DEVOLVIDO | C n I n M n`.
- Os campos de cada papel saem de "Ao terminar" do contrato (por exemplo, SHAs e resultado da verificação).

**Fechamento do template.** O template termina com duas listas curtas.

*Antes de enviar:*
- cabeçalho de quatro linhas, com caminhos absolutos e o `Papel:` igual ao nome do contrato;
- em correção: copiado do brief anterior, com "Desde a rodada anterior";
- toda leitura tem intervalo;
- todo comando tem saída limitada;
- o teto está declarado;
- o "Nunca faz" está colado, não linkado.

*Ao receber:*
- `verifica-escopo.sh <task>` na branch do papel;
- `verifica-red.sh` depois do RED;
- `verify.sh` depois da GREEN;
- no revisor, `git status --porcelain` vazio no worktree revisado (o parecer fica fora do worktree);
- confere a linha de retorno contra o arquivo de relatório.

Desvio que é da stack não entra nessa lista. Pelo Princípio 2, ele vai para `CMD_VERIFY_STACK` do projeto.

### 5.2 Seção "No brief" em `core/papeis/*.md`

Cada contrato de papel (não o `_oraculo.md`) ganha uma seção `## No brief`, colocada depois de "Independência". Ela traz de 3 a 5 linhas, em forma de ação. **Cada linha reescreve uma regra que o próprio contrato já tem; nenhuma é nova.** O conteúdo de cada papel:

- **dev:**
  - teste do RED parece errado: PARE e reporte `BLOQUEADO`; não contorne no código de produção;
  - nunca altere, apague ou desabilite teste do RED;
  - arquivo fora do escopo: PARE e pergunte;
  - dependência nova: PARE e pergunte (N3).
- **testes:**
  - escreva só nos diretórios de teste (e no documento da task); nunca em código de produção;
  - antes do commit, rode o comando do brief e confira que cada teste falha pelo motivo certo;
  - teste que passaria em qualquer implementação não vale;
  - critério de aceite que não dá para testar como está escrito: `BLOQUEADO`, com a pergunta.
- **revisor:**
  - escreva só o parecer, no caminho do brief; não corrija nada;
  - abra cada citação e rode a verificação você mesmo, em primeiro plano, antes de aprovar;
  - nunca revise o que você mesmo produziu.
- **arquiteto:**
  - nada além do contrato executável;
  - regra de negócio divergente vira pergunta; nunca altere a spec;
  - nunca escreva aprovação, resposta do humano nem Ruling.
- **dominio:**
  - regra vinda de oráculo cita `arquivo:linha`;
  - `hipótese` não vira `confirmada` sem fonte;
  - nada de stack, arquitetura ou nome de classe.

**Ao terminar.** Em todos os contratos, "Ao terminar" passa a dizer: grave o relatório no arquivo indicado no brief e devolva a linha de retorno.

### 5.3 Revisor e template de parecer

**`core/papeis/revisor.md`, "Nunca faz":** "Editar arquivos" passa a ser "Escrever qualquer arquivo além do parecer, no caminho que o brief dá". Fica mantida a nota de que isso é redução, não garantia. **Verificado por:** `git status --porcelain` vazio no worktree revisado, na conferência ao receber; e revisão.

**O revisor roda o `verify.sh` ele mesmo**, como o contrato já diz no modo `diff`. Nenhum brief tira isso dele. No projeto de referência, o brief de confirmação proibia o revisor de rodar o verify, que o orquestrador rodava em paralelo. Isso é a outra contradição do revisor, e o kit não a adota: a independência do revisor vale mais que o custo de um comando de saída curta. O travamento de turno com comando longo é problema da ferramenta, e o orquestrador o resolve na própria memória.

**Escala:** a do kit, sem mudança: Crítico/Importante/Menor e `APROVADO`/`DEVOLVIDO`.

**`core/templates/parecer.md` (novo).** As seções, em ordem:

1. **Cabeçalho:** modo, task ou artefato, intervalo de SHAs (modo `diff`), número da rodada, veredito e contagem `C n I n M n`.
2. **`## Rodada anterior`.** Só na confirmação: tabela achado anterior → `corrigido` / `não corrigido` / `parcial`, com `arquivo:linha` do HEAD.
3. **`## Critérios de aceite`.** No modo `diff`, tabela CA ↔ teste ↔ status (`medido` ou `inferido`). Nos modos `spec`, `design` e `mudanca`, `não se aplica`.
4. **`## Achados`.** ID, classe, `arquivo:linha`, problema e evidência (`medido` ou `inferido`).
5. **`## Verificação`.** Comando rodado e as últimas linhas da saída.

### 5.4 Onde fica o parecer

O parecer fica **local**, na pasta de execução (`agentic/.estado/`, que o git ignora), como os briefs. O PR leva o veredito e os achados menores, como o template `pr.md` já pede.

**Gate 2 sem plataforma de PR:** antes de deixar a branch rebaseada, o orquestrador copia o parecer final aprovado (modo `diff`) para `agentic/projeto/specs/<nome>/pareceres/` e o commita na branch da task. O `verifica-escopo.sh` já isenta a pasta da spec. O `status-projeto.sh` não pode lê-lo como artefato: ele ignora arquivos com prefixo `_`, e o construtor escolhe o nome ou o ajuste que resolve isso.

### 5.5 `core/processo/ciclo.md`, "Orquestração", item 2

As linhas de `task-N-brief.md` e `task-N-relatorio.md` saem. No lugar entram:

- **brief:** montado por `agentic/processo/templates/brief.md` e conferido pela lista "Antes de enviar"; nomes `NN-<papel>[-<modo>]-brief.md`;
- **rodada de correção:** é despacho novo, com o brief anterior copiado inteiro mais a seção "Desde a rodada anterior"; nunca "mesmo brief anterior" nem continuação de sessão;
- **relatório:** gravado pelo papel no arquivo que o brief indica; o retorno pela ferramenta é só a linha;
- **ao receber:** a lista "Ao receber" do template;
- **parecer:** local; no Gate 2 sem plataforma de PR, o parecer final aprovado vai para `pareceres/` (seção 5.4).

O que passa a citar esses nomes também se ajusta:

- `core/templates/AGENTS.md` ("Quem é você", primeiro item): "entregue o relatório que o contrato pede" vira "grave o relatório no arquivo do brief e devolva a linha de retorno";
- `docs/portabilidade.md`: a menção a `task-N-brief.md`.

### 5.6 Adaptadores do revisor

- **Claude Code** (`adapters/claude-code/agents/revisor.md`): ganha `Write`, mas não `Edit`.
- **Copilot** (`adapters/copilot/agents/revisor.agent.md`): ganha `edit`.

Nos dois, a nota passa a dizer: "pode escrever só o parecer; o resto é verificado na conferência ao receber e por revisão". O motivo de dar escrita direta, em vez de usar o shell, é que parecer passado por shell chegou cortado no projeto de referência (variável e colchete). *Decisão do redator; ver seção 8.*

### 5.7 `core/templates/perfil-papel.md`

Não ganha seção nova. O comentário de preenchimento passa a dizer que os itens de "Padrões" e "Nunca faz neste projeto" são escritos em forma de ação, porque o orquestrador os cola no brief.

### 5.8 Coerência no kit inteiro

O kit hoje apresenta o revisor como papel **sem ferramenta de escrita**, e um teste garante isso. Mudar só o contrato deixaria o kit contradizendo a si mesmo. O próprio revisor, revisando este PR, acharia a contradição (Importante).

A garantia passa a ser outra: o revisor **escreve só o parecer, fora do worktree que revisa**. Isso é conferido pelo `git status --porcelain` vazio no worktree, na conferência ao receber, e por revisão.

Toda menção a revisor, brief e relatório no kit muda junto:

| Arquivo | Hoje | Passa a |
|---|---|---|
| `core/papeis/revisor.md` | "Nunca faz: Editar arquivos. Você não tem Write/Edit"; "Ao terminar: entregue o parecer" | só o parecer, no caminho do brief, fora do worktree; "Ao terminar": grava o parecer pelo template e devolve a linha (seção 5.3) |
| `core/processo/modelos.md`, "Ferramentas" (item 4) | "o `revisor` vai para um produto que negue escrita" | o `revisor` vai para um produto que restrinja a escrita; sem isso, "só o parecer" fica por revisão e pela conferência ao receber, e a decisão de composição diz isso |
| `README.md`, tabela de riscos | "o `revisor` roda em contexto limpo, sem ferramenta de escrita, e nunca corrige" | "…em contexto limpo, escreve só o parecer e nunca corrige"; mecanismo: "contrato + adaptador + conferência ao receber" |
| `README.md`, tabela de papéis | Nunca faz: "edita arquivo ou revisa o que produziu" | "escreve além do parecer ou revisa o que produziu" |
| `adapters/claude-code/agents/revisor.md` | sem `Write`/`Edit`; nota "omite Write/Edit" | `Write` sem `Edit`; nota nova (seção 5.6) |
| `adapters/copilot/agents/revisor.agent.md` | sem `edit`; nota "omite edit" | com `edit`; nota nova |
| `bootstrap/instalar.Tests.sh` (caso "revisor sem a ferramenta edit") | confere que o revisor do Copilot **não** tem `edit` | confere as ferramentas novas nos dois adaptadores, inclusive que o do Claude Code continua sem `Edit` |
| `adapters/claude-code/commands/nova-task.md`, passo 4 | "Registre brief e relatório no diretório de execução" | monta cada brief por `agentic/processo/templates/brief.md`; o papel grava o relatório; o orquestrador faz a conferência ao receber |
| `adapters/claude-code/commands/mudanca.md`, passo 2 | "O brief traz o caminho absoluto do documento…" | idem, com o brief montado pelo template |
| `core/templates/AGENTS.md`, "Quem é você" | "entregue o relatório que o contrato pede" | "grave o relatório no arquivo do brief e devolva a linha de retorno" |
| `docs/portabilidade.md` | "o brief (`task-N-brief.md`)" | "o brief (`agentic/processo/templates/brief.md`)" |
| `core/templates/pr.md`, "Parecer do revisor" | veredito e achados menores | idem; sem plataforma de PR, mais o caminho do parecer em `pareceres/` |
| `core/processo/ciclo.md` | item 2 de "Orquestração" | seção 5.5 |

`adapters/copilot/copilot-instructions.md` e os prompts do Copilot apontam para o `AGENTS.md` e para os comandos do Claude Code, por isso herdam a mudança sem edição.

O construtor confirma a lista com uma busca por `revisor`, `brief`, `relatório`, `parecer`, `Write` e `edit` antes de fechar. O que aparecer fora dela entra no mesmo commit do item que tratar o assunto.

## 6. Restrições

- Os contratos (`core/papeis/`, `core/processo/`) são compartilhados com as instâncias, que recebem a mudança pela reinstalação do kit (`bootstrap/instalar.sh` e o manifesto). Nada aqui pode exigir edição manual na instância, além do que cada projeto decide depois.
- `instalar.sh` já copia `core/templates/` e `mecanismos/scripts/` por diretório. Os arquivos novos seguem esse caminho, e `instalar.Tests.sh` deve confirmar que eles chegam à instância.
- `scripts/verify.sh` do kit (todas as suítes `*.Tests.sh`) continua verde.
- Princípio 1: toda regra nova declara `Verificado por:`.
- Trilha do kit: uma branch, um commit por item da seção 5 e um PR, que só o dono integra.

## 7. Critério de pronto

1. Um brief preenchido pelo template para cada papel do kit (`dominio`, `arquiteto`, `testes`, `dev` e `revisor`), em `docs/exemplos-brief/` ou anexado ao PR. *Pasta: decisão do construtor.* Cada um reconstrói, sem perder cláusula, a forma de um brief maduro do projeto de referência, com conteúdo neutro de stack e sem citar o projeto. Cada um passa na lista "Antes de enviar".
2. Um parecer de confirmação preenchido pelo template.
3. `scripts/verify.sh` verde, com `instalar.Tests.sh` confirmando que `brief.md` e `parecer.md` chegam à instância.
4. Nenhuma ocorrência de `task-N-brief` ou `task-N-relatorio` no kit.
5. Nenhum texto do kit descreve o revisor como "sem ferramenta de escrita" ou "nunca edita arquivos" (seção 5.8).

## 8. Decisões do redator (o dono confere)

- Nomes de arquivo por ordem de despacho (`NN-<papel>[-<modo>]-…`), em vez de por rodada.
- Revisor com `Write` (Claude Code) e `edit` (Copilot), em vez de escrever por shell.
- O `verify` continua com o revisor; o brief não pode tirá-lo dele.
- A tabela CA ↔ teste ↔ status é obrigatória só no modo `diff`.
- Meta de ~40 linhas para o brief: orientação no comentário do template, sem checagem.

## 9. Fica com o construtor

- Texto exato das seções e dos comentários de preenchimento.
- Como o `status-projeto.sh` ignora `pareceres/` (prefixo `_` ou exclusão no `find`).
- Onde ficam os briefs de exemplo do critério de pronto.
- A ordem dos commits, desde que cada commit deixe o `verify` verde.

## 10. Depois, na instância de referência (fora deste trabalho)

- Reinstalar o kit.
- Apagar o modelo de brief local (manter a tabela de medição, se o dono quiser).
- Tirar dos perfis do revisor a cláusula "parecer em texto puro".
- Passar a escala Bloqueante/Maior/REPROVADO para a do kit.
- Mover as lições de stack para "Padrões" e "Nunca faz neste projeto" dos perfis.
