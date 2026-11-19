# Artefatos enxutos — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gravar a fala do humano uma vez só, em lugar versionado, tirar da spec o que é histórico, e fazer as rodadas de revisão do planejamento terminarem sem afrouxar o revisor.

**Architecture:** Dois PRs independentes, cada um com uma regra:
- **PR 1 — Fala do humano em um lugar** (A1 + A3 corrigido): a resposta vai para o registro de trabalho (`progress.md`) e, no Gate 1, para o corpo do commit de registro. A regra cita o ID e um trecho. O Questionário só tem perguntas em aberto. Vale nas duas trilhas e no Gate 1 delegado.
- **PR 2 — Rodadas que terminam** (A6 corrigido + A5 + parte do A4): a 3ª devolução para de verdade, o revisor recebe o delta pronto e o "Já decidido" do brief cita IDs.

O texto de `core/` é conferido por `scripts/coerencia-kit.Tests.sh`, e o script, pela sua suíte `*.Tests.sh`.

**Tech Stack:** Markdown do kit, POSIX sh, `mecanismos/scripts/testlib.sh` (`tl_espera`, `tl_contem`, `tl_fim`).

**Spec:** não há design doc. A origem é a proposta externa `2026-11-19-kit-artefatos-enxutos.md` (itens A1–A8, B1), conferida contra três instâncias. O que se aplica está na seção "Base de evidência" abaixo, que viaja com o plano.

## Base de evidência

Amostra: 18 specs no formato do template e 22 artefatos de planejamento com pareceres locais, em três instâncias (projetos A, B e C; C sem `.estado/execucao`). A contagem foi feita por arquivo e por grep, com o tamanho em bytes.

| Item | Medido | Decisão |
|---|---|---|
| A1 histórico de rodada na spec | 0 a 4 marcas por spec (71 na origem) | regra curta de forma, sem mecanismo |
| A1 Questionário respondido na spec | de 7% a 38% do texto, mediana ~20% | **PR 1** |
| A3 fonte única no `progress.md` | `agentic/.estado/` é ignorado pelo git | **corrigido**: a fonte versionada é o corpo do commit do Gate 1 |
| A6 corte na 3ª devolução | 10 de 22 artefatos passaram de 3 devoluções; designs com 9 e 10; nenhum `progress.md` registra a parada | **PR 2**, sem a opção "aceitar com achados pendentes" |
| A5 delta para o revisor | o contrato pede o delta, nada o entrega | **PR 2** |
| A4 brief que acumula | não se reproduz (3 a 11 mil caracteres estáveis por até 12 rodadas); a meta de 40 linhas é estourada com frequência | **PR 2**, só "Já decidido" por ID e aviso acima de 60 linhas |
| A2, A7, A8, B1 | sem relação medida com as rodadas; A8 dispararia em 7 de 12 specs de A | fora deste plano |

Condição de validade: as rodadas tardias de B eram defeitos reais (sanitização provada rodando código). Por isso nenhuma mudança deixa um Importante passar sem bloquear.

## Global Constraints

- **Revisor não afrouxa:** Crítico e Importante sempre bloqueiam. Nenhuma opção aceita artefato com Importante pendente.
- **Fala do humano:** uma entrada por resposta, no formato `N<n> (humano:<AAAA-MM-DD>): <texto exato da mensagem>`. No Gate 1 delegado: `N<n> (Gate 1 delegado, D<n>): <opção> — <motivo>`. `N<n>` é numerado na pasta de execução e nunca reutilizado.
- **Fonte na regra:** `humano:<AAAA-MM-DD> N<n> "<trecho de até ~15 palavras>"`. No delegado: `decisão:D<n> N<n>`. `plano:<arquivo>:<linha>` e `oráculo:<arquivo>:<linha>` não mudam.
- **O corpo do commit de registro do Gate 1** (`docs(spec): … aprovada (Gate 1…)` e `docs(mudanca): …`) lista toda `N<n>` citada nos artefatos, com o texto exato. É o único registro versionado da fala.
- **Coerência:** toda mudança de regra faz grep dos dois lados em `core/ adapters/ bootstrap/ mecanismos/ README.md docs/exemplos-brief/ site/`. Cada contradição mecanizável ganha checagem em `scripts/coerencia-kit.Tests.sh`.
- **Sem nomes de projetos:** nada de nome de instância no repo, nas mensagens de commit ou nos PRs. O teste `sem_nomes_proibidos` continua verde.
- **Sem cerimônia nova:** nenhum arquivo novo por despacho além da cópia do artefato revisado (PR 2, Task 6), que substitui uma leitura inteira. Brief continua sem script de verificação (decisão do dono).
- **Shell:** POSIX `sh`, com `\r` removido em toda leitura.
- **Git:** cada PR sai de `origin/main` depois do `git fetch`. Em PR publicado, integre a main por merge, nunca por rebase. Os commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Pronto de toda task:** `sh scripts/verify.sh` termina em `verify: OK`.

## Review Focus

1. **Instância com spec aprovada no formato antigo** (Questionário com `Resposta (…)`): nada falha. O `verifica-artefato.sh` só roda antes do Gate 1, e artefato aprovado não é verificado. A nota de atualização do README diz isso. Checagem na Task 3.
2. **Resposta dentro de comentário `<!-- Resposta … -->`** (o próprio template e cópias antigas): não conta como resposta escrita. Teste na Task 1.
3. **Gate 1 delegado na trilha enxuta:** a resposta vai para o `progress.md` e para o corpo do commit, como no humano, com `decisão:D<n> N<n>`. Checagem na Task 2.
4. **Humano que responde antes do Gate 1** (no meio do planejamento, caso comum na amostra): a resposta ganha `N<n>` na hora, e a pergunta sai do Questionário na rodada seguinte do autor. Checagem na Task 2.
5. **Parada da 3ª devolução com modo automático ligado:** a parada vale também com `enabled: true` e `gate1: D<n>`, porque a delegação cobre o Gate 1, não as rodadas. Checagem na Task 5.

---

## PR 1 — Fala do humano em um lugar

Branch: `fala-do-humano` a partir de `origin/main`. O primeiro commit leva este plano: `docs(plano): artefatos enxutos`.

### Task 1: `verifica-artefato.sh spec` recusa resposta escrita no Questionário

**Files:**
- Modify: `mecanismos/scripts/verifica-artefato.sh:199-204` (o bloco do Questionário, hoje só no `mudanca`)
- Test: `mecanismos/scripts/verifica-artefato.Tests.sh` (bloco do modo spec, depois da linha 163)

**Interfaces:**
- Produces: a mensagem `resposta escrita no Questionário fora de comentário (<doc>): a resposta fica no progress.md e no corpo do commit do Gate 1; a pergunta respondida sai do Questionário`, nos modos `spec` e `mudanca`.

- [ ] **Step 1: Escrever os testes que falham**

```sh
r=$(prepara_spec)
sub 's/^## Questionário de decisão$/&\n1. Q1: pergunta? (a) (b)\n   Resposta (humano:2026-11-19): a — ok/' $S/spec.md
tl_espera 1 "spec: resposta no Questionário escrita fora de comentário" roda spec $S
tl_contem "corpo do commit do Gate 1" "diz onde a resposta fica"
r=$(prepara_spec)
tl_espera 0 "spec: resposta em comentário não conta" roda spec $S
```

No bloco do `mudanca` (linha 265), acrescente `tl_contem "corpo do commit do Gate 1" "diz onde a resposta fica"`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/verifica-artefato.Tests.sh 2>&1 | tail -n 15`
Expected: FALHA em "spec: resposta no Questionário escrita fora de comentário" e nas duas linhas `tl_contem`.

- [ ] **Step 3: Implementar**

Tire a checagem do `if [ "$modo" = mudanca ]` de `ck_sem_aprovacao` e rode-a nos modos `spec` e `mudanca`. A seção chama `Questionário de decisão` na spec e `Questionário` no documento. Como a função `secao` casa por prefixo, `secao "$doc" Questionário` serve aos dois. Troque a mensagem pela de "Produces".

- [ ] **Step 4: Rodar e ver passar**

Run: `sh mecanismos/scripts/verifica-artefato.Tests.sh 2>&1 | tail -n 3`
Expected: nenhuma FALHA.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-artefato.sh mecanismos/scripts/verifica-artefato.Tests.sh
git commit -m "feat(verifica-artefato): spec recusa resposta escrita no Questionário"
```

### Task 2: processo e templates — registro `N<n>` e corpo do commit do Gate 1

**Files:**
- Modify: `core/processo/ciclo.md` — linha 30 ("Registro do Gate 1", trilha padrão), 44 ("Questionário", enxuta), 48 ("Registro do Gate 1", enxuta), 60 ("O orquestrador no Gate 1"), 116 ("Resposta do humano"), 105 (`progress.md`)
- Modify: `core/templates/spec.md:9` (Fonte, na linha R1), `:20-22` (Questionário e comentário do delegado)
- Modify: `core/templates/mudanca.md:13,16` (Fonte), `:57-61` (Questionário)
- Modify: `core/templates/brief.md:30` ("Já decidido": `resposta do humano (N<n>, data)`)
- Modify: `adapters/claude-code/commands/mudanca.md:11-12` (passos 4 e 5)
- Test: `scripts/coerencia-kit.Tests.sh` (bloco novo no fim: `# --- Artefatos enxutos (docs/plans/2026-11-19-artefatos-enxutos.md)`)

**Interfaces:**
- Consumes: a mensagem da Task 1.
- Produces: os formatos `N<n> (humano:…)` e `humano:<data> N<n> "<trecho>"` das Global Constraints, que a Task 3 cita nos papéis.

Texto que decide (o resto é ajuste de redação ao redor):
- **ciclo.md:116, "Resposta do humano":** "o orquestrador grava cada resposta uma vez, no `progress.md`, como `N<n> (humano:<AAAA-MM-DD>): <texto exato>`, e a repassa ao papel no brief pelo ID. O artefato cita a resposta só na `Fonte:` da regra (`humano:<data> N<n> "<trecho>"`). Pergunta respondida sai do Questionário."
- **ciclo.md:30 e :48:** "o corpo do commit de registro lista cada `N<n>` citada em intent, spec, design ou documento, com o texto exato: é o registro versionado da fala do humano (o `progress.md` não é versionado)."
- **ciclo.md:60 (delegado):** a resposta do orquestrador entra no `progress.md` como `N<n> (Gate 1 delegado, D<n>): <opção> — <motivo>`, e a regra ganha `Fonte: decisão:D<n> N<n>`.
- **spec.md e mudanca.md:** o comentário do Questionário passa a ser "Só perguntas em aberto. Respondida, a pergunta sai daqui; a resposta fica no `progress.md` e no corpo do commit do Gate 1 (`agentic/processo/ciclo.md`, "Resposta do humano")." Não sobra nenhum `Resposta (` nos templates.

- [ ] **Step 1: Escrever as checagens que falham** (no bloco novo de `coerencia-kit.Tests.sh`)

```sh
tl_espera 0 "fala do humano: formato N<n> no ciclo" tem core/processo/ciclo.md 'N<n> (humano:<AAAA-MM-DD>)'
tl_espera 0 "fala do humano: delegado com N<n>" tem core/processo/ciclo.md 'N<n> (Gate 1 delegado, D<n>)'
tl_espera 0 "fala do humano: Fonte com ID e trecho" tem core/templates/spec.md 'humano:<AAAA-MM-DD> N<n>'
tl_espera 0 "fala do humano: Fonte com ID e trecho (enxuta)" tem core/templates/mudanca.md 'humano:<AAAA-MM-DD> N<n>'
tl_espera 0 "Gate 1: corpo do commit lista as N<n>" tem core/processo/ciclo.md 'é o registro versionado da fala do humano'
tl_espera 0 "nenhuma resposta gravada no artefato" nenhum 'Resposta \((humano|Gate 1 delegado)' \
  core adapters docs/exemplos-brief README.md site
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep -E 'FALHA|OK:' | tail -n 10`
Expected: as 6 checagens novas em FALHA. A última lista `ciclo.md:44`, `ciclo.md:60`, `spec.md`, `mudanca.md:60-61` e `adapters/claude-code/commands/mudanca.md:11`.

- [ ] **Step 3: Editar os arquivos de "Files" com o texto que decide.** Depois, rode o grep dos dois lados e corrija o que aparecer:

Run: `grep -rnE 'grava (a resposta|cada resposta) no (artefato|documento)|Resposta \(|respostas do questionário' core adapters bootstrap mecanismos README.md docs/exemplos-brief site | cut -c1-160`
Expected: só ocorrências que já usam o formato novo. `revisor.md:13` ("resposta do questionário que o corpo desse commit não registra") fica para a Task 3.

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh 2>&1 | tail -n 3`
Expected: `verify: OK`.

- [ ] **Step 5: Commit**

```bash
git add core/processo/ciclo.md core/templates/spec.md core/templates/mudanca.md core/templates/brief.md adapters/claude-code/commands/mudanca.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(ciclo): a fala do humano fica no progress.md e no corpo do commit do Gate 1"
```

### Task 3: papéis — spec só com o estado atual, revisor confere pelo ID

**Files:**
- Modify: `core/papeis/dominio.md:17-19` (Produz), `:39-46` (Pronto para revisão)
- Modify: `core/papeis/revisor.md:10` (modo `spec`), `:12` (modo `mudanca`), `:13` (modo `diff`)
- Modify: `core/papeis/arquiteto.md:33,38,45,54` (modo enxuto: a regra com `Q<n>` troca de fonte pelo orquestrador, como hoje, mas no formato novo)
- Modify: `README.md`, seção `## O que muda ao atualizar o kit` (uma entrada)
- Test: `scripts/coerencia-kit.Tests.sh` (mesmo bloco da Task 2)

**Interfaces:**
- Consumes: os formatos da Task 2.

Texto que decide:
- **dominio.md, Produz:** "A spec descreve o estado atual: sem cabeçalho de rodadas, sem listas do que mudou, entrou ou saiu, sem respostas superadas. Esse histórico fica no `progress.md`." O item atual sobre "afirmação sobre o estado atual cita a fonte" continua.
- **dominio.md, Pronto para revisão**, item novo: "a spec não tem histórico de rodadas, e o Questionário só tem perguntas em aberto;".
- **revisor.md, modos `spec` e `mudanca`:** "regra com `Fonte: humano:… N<n>`: confira o trecho contra a entrada `N<n>` do `progress.md` que o brief indica em 'Leia só isto'. Regra que diz mais ou menos do que a entrada é achado **Importante**."
- **revisor.md, modo `diff`:** onde hoje diz "resposta do questionário que o corpo desse commit não registra", passa a dizer "`N<n>` citada nos artefatos que o corpo do commit do Gate 1 não registra, nas duas trilhas, é achado **Importante**".
- **README, nota de atualização:** a resposta do humano deixa de ser gravada no Questionário. Specs já aprovadas não mudam, e o `verifica-artefato.sh` não verifica artefato aprovado.

- [ ] **Step 1: Escrever as checagens que falham**

```sh
tl_espera 0 "dominio: spec sem histórico no Pronto" tem core/papeis/dominio.md 'a spec não tem histórico de rodadas, e o Questionário só tem perguntas em aberto'
tl_espera 0 "revisor spec: confere N<n> no progress.md" tem core/papeis/revisor.md 'entrada `N<n>` do `progress.md`'
tl_espera 0 "revisor diff: N<n> no corpo do commit, nas duas trilhas" tem core/papeis/revisor.md 'que o corpo do commit do Gate 1 não registra, nas duas trilhas'
tl_espera 1 "revisor: fim do texto antigo" tem core/papeis/revisor.md 'resposta do questionário que o corpo desse commit não registra'
tl_espera 0 "README: nota sobre a fala do humano" tem README.md 'deixa de ser gravada no Questionário'
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep FALHA`
Expected: as 5 checagens novas em FALHA.

- [ ] **Step 3: Editar os arquivos de "Files" com o texto que decide.** Rode de novo o grep da Task 2, Step 3. Rode também `grep -rn 'Pronto para revisão' adapters | cut -c1-120`: os adaptadores apontam para o contrato e não copiam a lista. Se algum copiar, ajuste.

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh 2>&1 | tail -n 3`
Expected: `verify: OK`.

- [ ] **Step 5: Commit**

```bash
git add core/papeis/dominio.md core/papeis/revisor.md core/papeis/arquiteto.md README.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(papeis): spec só com o estado atual; revisor confere a fala pelo ID"
```

### Task 4: revisão independente das correções e PR 1

- [ ] **Step 1:** Despache um revisor em contexto limpo, com o diff `origin/main..HEAD` e a pergunta: "alguma frase de `core/`, `adapters/`, `README.md`, `docs/exemplos-brief/` ou `site/` ainda manda gravar a resposta no artefato, ou contradiz o formato `N<n>`?". Corrija cada achado com checagem nova em `coerencia-kit.Tests.sh`.
- [ ] **Step 2:** Rode `git fetch origin && git merge origin/main` e depois `sh scripts/verify.sh 2>&1 | tail -n 3`. Expected: `verify: OK`.
- [ ] **Step 3:** Rode `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep -i 'nomes'`. Expected: OK, sem aviso de `.nomes-proibidos` ausente.
- [ ] **Step 4:** Push e PR "Fala do humano em um lugar". O corpo traz a tabela da Base de evidência, só com as linhas A1 e A3, sem nomes de projetos, e termina com `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

---

## PR 2 — Rodadas que terminam

Branch: `rodadas-que-terminam` a partir de `origin/main`, depois do merge do PR 1. O "Já decidido" por ID depende do formato `N<n>`.

### Task 5: a 3ª devolução para de verdade; oráculo antes da spec

**Files:**
- Modify: `core/processo/ciclo.md:27` (devolução), `:118` ("Oráculo")
- Modify: `README.md:259` (se repetir a regra da rodada) e a seção `## O que muda ao atualizar o kit`
- Test: `scripts/coerencia-kit.Tests.sh` (bloco novo: `# --- Rodadas que terminam`)

Texto que decide, em `ciclo.md:27`, no lugar de "o orquestrador para e leva ao humano as causas por rodada antes de despachar a correção seguinte":

> "o orquestrador não despacha a correção seguinte. Ele grava no `progress.md` `Parada (3ª devolução): <artefato> — causas por rodada: <…>` e pede ao humano uma de três saídas: decidir o ponto que reabre o artefato (a resposta vira `N<n>`), reduzir o escopo (o autor refaz o artefato com o recorte), ou autorizar mais uma rodada. Cada devolução seguinte para de novo. Sem resposta, nada é despachado, também com o modo automático ligado. Nenhuma saída aceita o artefato com Crítico ou Importante pendente."

Texto que decide, em `ciclo.md:118`, frase nova no fim: "Pedido que muda o modo de operação do sistema, ou que depende do que de fato o bloqueia hoje: o orquestrador consulta o oráculo antes do primeiro brief do `dominio` e cola a resposta no `## Impacto` desse brief."

- [ ] **Step 1: Escrever as checagens que falham**

```sh
c=core/processo/ciclo.md
tl_espera 0 "3ª devolução: parada gravada" tem $c 'Parada (3ª devolução): <artefato>'
tl_espera 0 "3ª devolução: vale com modo automático" tem $c 'Sem resposta, nada é despachado, também com o modo automático ligado'
tl_espera 0 "3ª devolução: não afrouxa o revisor" tem $c 'Nenhuma saída aceita o artefato com Crítico ou Importante pendente'
tl_espera 0 "oráculo antes do primeiro brief do dominio" tem $c 'antes do primeiro brief do `dominio`'
tl_espera 0 "kit sem aceite com achado pendente" nenhum 'aceitar .{0,40}(achados|Importantes?) .{0,30}(pendentes|em aberto)' core adapters README.md
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep FALHA`
Expected: as 4 primeiras em FALHA. A última passa e fica como trava contra a volta.

- [ ] **Step 3: Editar.** Depois rode `grep -rnE '3ª devolução|causas por rodada' core adapters README.md site | cut -c1-140`. Expected: toda ocorrência concorda com o texto novo.

- [ ] **Step 4:** Run: `sh scripts/verify.sh 2>&1 | tail -n 3`. Expected: `verify: OK`.

- [ ] **Step 5: Commit**

```bash
git add core/processo/ciclo.md README.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(ciclo): a 3ª devolução para até o humano escolher a saída; oráculo antes da spec"
```

### Task 6: o revisor recebe o delta pronto

**Files:**
- Modify: `core/templates/brief.md:27` (linha da rodada do revisor em "O que fazer") e `:36-37` ("Leia só isto")
- Modify: `core/papeis/revisor.md:15-18` ("Rodada de correção")
- Modify: `core/processo/ciclo.md:107` (rodada de correção, na lista da Orquestração)
- Test: `scripts/coerencia-kit.Tests.sh` (bloco da Task 5)

**Interfaces:**
- Produces: a cópia `NN-revisado-<arquivo>` na pasta de execução, gravada pelo orquestrador a cada despacho do revisor nos modos `spec`, `design` e `mudanca` (por exemplo, `04-revisado-spec.md`).

Texto que decide:
- **brief.md, "Leia só isto", revisor na rodada `k ≥ 2`:** "o delta vem primeiro. No modo `diff`: `git diff <SHA final revisado no parecer anterior>..HEAD`. Nos modos `spec`, `design` e `mudanca`: `diff -u <NN-revisado-<arquivo> do despacho anterior> <artefato>`. Sempre com a saída limitada. O artefato inteiro só na rodada 1."
- **revisor.md, Rodada de correção:** "leia o delta do brief e abra o resto do artefato só onde o delta toca ou onde um achado anterior aponta". O item "achado novo fora do delta, Crítico ou Importante, entra e bloqueia" continua igual.
- **ciclo.md:107:** "a cada despacho do revisor de spec, design ou mudanca, o orquestrador copia o artefato para `NN-revisado-<arquivo>` na pasta de execução".

- [ ] **Step 1: Escrever as checagens que falham**

```sh
tl_espera 0 "brief: delta do revisor nos modos sem commit" tem core/templates/brief.md 'diff -u <NN-revisado-<arquivo>'
tl_espera 0 "brief: delta do revisor no modo diff" tem core/templates/brief.md 'git diff <SHA final revisado no parecer anterior>..HEAD'
tl_espera 0 "ciclo: cópia do artefato revisado" tem core/processo/ciclo.md 'NN-revisado-<arquivo>'
tl_espera 0 "revisor: lê o delta primeiro" tem core/papeis/revisor.md 'leia o delta do brief'
tl_espera 0 "revisor: achado fora do delta continua bloqueando" tem core/papeis/revisor.md 'Achado novo fora do delta, Crítico ou Importante, entra e bloqueia'
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep FALHA`
Expected: as 4 primeiras em FALHA. A quinta já passa e trava a regra.

- [ ] **Step 3: Editar.** Confira `docs/exemplos-brief/07-revisor-diff-brief.md`: se for uma rodada `k ≥ 2`, acrescente o `git diff` em "Leia só isto".

- [ ] **Step 4:** Run: `sh scripts/verify.sh 2>&1 | tail -n 3`. Expected: `verify: OK`.

- [ ] **Step 5: Commit**

```bash
git add core/templates/brief.md core/papeis/revisor.md core/processo/ciclo.md docs/exemplos-brief scripts/coerencia-kit.Tests.sh
git commit -m "feat(brief): o revisor recebe o delta pronto na rodada de correção"
```

### Task 7: "Já decidido" por ID e aviso de tamanho do brief

**Files:**
- Modify: `core/templates/brief.md:6` (meta), `:30` ("Já decidido"), `:71-80` ("Antes de enviar")
- Test: `scripts/coerencia-kit.Tests.sh` (bloco da Task 5)

Texto que decide:
- **"Já decidido":** "o que já está na spec, no design ou na task entra só pelo ID e a origem (`R25 — humano:2026-11-19 N1`), sem reescrever o conteúdo. A resposta do humano que ainda não está em artefato entra com o texto da entrada `N<n>`."
- **"Antes de enviar"**, item novo: "`- [ ] mais de 60 linhas fora de ## Impacto e dos trechos que ele acrescenta: enxugue O que fazer e Já decidido antes de enviar;`".
- A regra de copiar o brief anterior inteiro (`brief.md:9-10`, `ciclo.md:107`) **não muda**. Escopo, "Nunca faz", "Entrega", "Teto", "Comandos", "Impacto" e "Casos a cobrir" continuam no brief novo.

- [ ] **Step 1: Escrever as checagens que falham**

```sh
b=core/templates/brief.md
tl_espera 0 "brief: Já decidido por ID" tem $b 'entra só pelo ID e a origem'
tl_espera 0 "brief: aviso acima de 60 linhas" tem $b 'mais de 60 linhas fora de ## Impacto'
tl_espera 0 "brief: correção continua copiando o anterior inteiro" tem $b 'copie para um arquivo novo o brief anterior do mesmo papel, inteiro'
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep FALHA`
Expected: as 2 primeiras em FALHA. A terceira já passa e trava a regra.

- [ ] **Step 3: Editar.** Confira `docs/exemplos-brief/02-arquiteto-brief.md:17`: o "Já decidido" deve seguir o formato por ID.

- [ ] **Step 4:** Run: `sh scripts/verify.sh 2>&1 | tail -n 3`. Expected: `verify: OK`.

- [ ] **Step 5: Commit**

```bash
git add core/templates/brief.md docs/exemplos-brief scripts/coerencia-kit.Tests.sh
git commit -m "feat(brief): Já decidido cita IDs; aviso de brief acima de 60 linhas"
```

### Task 8: revisão independente das correções e PR 2

- [ ] **Step 1:** Despache um revisor em contexto limpo, com o diff `origin/main..HEAD` e a pergunta: "alguma frase do kit ainda permite despachar depois da 3ª devolução sem resposta do humano, aceitar artefato com Importante pendente, ou dar ao revisor da rodada `k ≥ 2` só o artefato inteiro?". Corrija cada achado com checagem nova.
- [ ] **Step 2:** `git fetch origin && git merge origin/main`, depois `sh scripts/verify.sh 2>&1 | tail -n 3`. Expected: `verify: OK`.
- [ ] **Step 3:** Push e PR "Rodadas que terminam", com as linhas A6, A5 e A4 da Base de evidência, sem nomes de projetos, terminando com `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

## Como medir depois

Na primeira rodada de planejamento de uma instância com o kit novo, contar:
- devoluções por artefato e se cada parada está no `progress.md`;
- a fração do Questionário na spec aprovada (meta: 0% respondido);
- as linhas do brief fora do `## Impacto` (meta: até 60).

Os mesmos greps da Base de evidência servem. A amostra é de uma feature: o resultado é indício, não prova.
