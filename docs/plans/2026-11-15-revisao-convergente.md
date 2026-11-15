# Revisão que converge — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deslocar a verificação para antes da revisão (impacto do arquiteto, lista única autor/revisor, barreira mecânica, brief sem desenho, causa no parecer) e cortar espera e cerimônia (verify com base única, cache de RED, dois níveis; Ruling e `em-andamento` sem commit próprio).

**Architecture:** Mudanças em três camadas do kit:
- **texto dos contratos e templates** (`core/`): conferido por `scripts/coerencia-kit.Tests.sh`;
- **scripts POSIX** (`mecanismos/scripts/`): cada um com a sua suíte `*.Tests.sh` sobre `testlib.sh`;
- **adaptadores e bootstrap**.

Cada task tem um objetivo, sobe sozinha e deixa `sh scripts/verify.sh` verde.

**Tech Stack:** POSIX sh (roda no Git Bash do Windows e no Linux), git, `testlib.sh` do kit.

**Spec:** `docs/specs/2026-11-14-revisao-convergente-design.md`

## Global Constraints

- **Shell:** POSIX `sh`, sem bashismos (`[[ ]]`, arrays, `local`, `${var//}`). O mesmo script roda no Git Bash e no Linux. Todo arquivo lido tem `\r` removido (`tr -d '\r'`).
- **Testes:** suíte `*.Tests.sh` ao lado do script, sobre `mecanismos/scripts/testlib.sh` (`tl_repo`, `tl_espera`, `tl_contem`, `tl_fim`). O critério de pronto de toda task é `sh scripts/verify.sh` → `verify: OK`.
- **Variável nova de `agentic/config`:** é opcional. Ausente, a checagem correspondente imprime `aviso: …` e é pulada; nunca falha uma instância antiga (design §10).
- **Saída de bloqueio:** `agentic: BLOQUEADO — <motivo>`. Sucesso termina com uma linha `<script>: OK …`.
- **Texto do kit:** em português, e o `core/` sem comando de stack. É proibido citar instâncias, o projeto de referência ou ferramenta de orquestração; o teste "kit sem nome do projeto de referência" continua verde.
- **Sem cerimônia nova:** nenhum arquivo novo por task ou por despacho. A autoconferência é uma seção do relatório que já existe, e não há script de métrica (design §7.6).
- **Revisor:** não afrouxa. Achado Crítico ou Importante sempre bloqueia (design §5).
- **Divisão das tasks:** por objetivo, nunca por tamanho. Cada task é commitada na branch `revisao-convergente`, com mensagem terminando em `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Artefato salvo com CRLF** (autor no Windows): o `verifica-artefato.sh` acha seções, CAs e caminhos igual ao LF. Teste na Task 1.
2. **Template com comentários `<!-- … -->`** que contêm `CA1`, `R1`, caminhos de exemplo e `<placeholder>`: nada disso conta como conteúdo. Teste na Task 1.
3. **Caminho citado com sufixo de linha** (`src/a.py:12`, `src/a.py:12-30`): confere o arquivo, sem o sufixo. Teste na Task 1.
4. **Branch empilhada cuja base já foi integrada e apagada:** `agentic_base` cai para a principal, sem erro. Teste na Task 5.
5. **Comando de teste que lê stdin:** não consome a lista de arquivos do laço do RED, e todos os arquivos são provados. Teste na Task 6.

---

### Task 1: Barreira mecânica antes do Gate 1 (`verifica-artefato.sh`)

Design §7.3, checagens 1–7.

**Files:**
- Create: `mecanismos/scripts/verifica-artefato.sh`
- Create: `mecanismos/scripts/verifica-artefato.Tests.sh`
- Modify: `mecanismos/scripts/lib-agentic.sh` (padrões `CMD_VALIDA_CONTRATO=""` e `CAMINHOS_N3=""`)
- Modify: `bootstrap/config.padrao` (as duas variáveis, com comentário)
- Modify: `bootstrap/entrevista.md` (linha "Stack": perguntar o comando que valida o contrato executável e os caminhos que são gatilho N3)
- Modify: `core/templates/brief.md` (lista "Ao receber")
- Modify: `core/processo/ciclo.md` (trilha padrão, linhas das fases 1 e 2, e "Trilha enxuta", item "Revisão antes do Gate 1")
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Produces:
  - `sh agentic/mecanismos/scripts/verifica-artefato.sh spec <dir da spec>`;
  - `… design <dir da spec>`;
  - `… mudanca <documento da mudança>`;
  - saída 0 = OK, 1 = bloqueado, 2 = uso errado. Todas as falhas são listadas antes de sair, e a última linha é `verifica-artefato: OK (<modo> <caminho>)` ou `verifica-artefato: BLOQUEADO (<n> falha(s))`.
- Consumes:
  - `agentic/config`: `CMD_VALIDA_CONTRATO` (comando rodado na raiz do worktree) e `CAMINHOS_N3` (globs separados por espaço).

**Regras de leitura (decididas aqui; valem para todo o script):**
- Seção = linhas depois de `## <título>` até o próximo `## `, sem `\r` e sem trechos `<!-- … -->` (inclusive os que ocupam várias linhas).
- **Regras da spec:** linhas `| R<n> | … |` de `## Regras`; Fonte é a 4ª coluna e Estado a 5ª.
- **Regras da mudança:** linhas `| R<n> | … |`; Fonte é a 4ª coluna e não há Estado.
- **CA:** linhas `- CA<n> (<R…>):` de `## Critérios de aceite`. As regras citadas são os `R<n>` dentro dos parênteses.
- **Caminho citado:** token entre crases que contém `/`, não começa com `<` nem tem espaço. Antes de conferir, sai o sufixo `:<n>` ou `:<n>-<m>`.
- **Existência de caminho:** o arquivo existe na árvore de trabalho, ou casa (`case`) com algum padrão de `## Arquivos` de alguma task da spec (no modo `mudanca`, do próprio documento).
- **Task:** `<dir da spec>/tasks/*.md`. Branch = valor de `**Branch:**` sem crases.

- [ ] **Step 1: Escrever a suíte com repositório-fixture**

`prepara_spec <repo>` monta uma spec mínima válida:
- `agentic/projeto/specs/pedidos/spec.md`, com R1 e R2 `confirmada` (Fonte `humano:2026-11-15`), CA1 (R1) e CA2 (R2);
- `design.md` com `**Status:** draft`, `## Como isso se prova` citando CA1 e CA2, `## Impacto` citando `src/pedidos/criar.py:3` e a tabela de N3 com a última coluna `<aprovado em AAAA-MM-DD, ou recusado>`;
- `tasks/001-criar.md` com `**Branch:** pedidos/001-criar`, `## Arquivos` com `src/pedidos/*`, `## Interfaces` com ``- Produz: `criar_pedido(dados)` ``, `## N3 aprovados no Gate 1` com `- Nenhum.` e `## Critérios de pronto` citando CA1 e CA2;
- o arquivo `src/pedidos/criar.py`, contendo `def criar_pedido(dados):`.

`prepara_mudanca <repo>` monta um documento enxuto mínimo e válido em `agentic/projeto/specs/ajuste/tasks/001-ajuste.md`, na branch `ajuste/001-ajuste`.

Casos e asserções:

```sh
tl_espera 0 "spec válida passa" sh -c "cd '$r' && sh '$dir/verifica-artefato.sh' spec agentic/projeto/specs/pedidos"
tl_contem "verifica-artefato: OK (spec" "linha final de sucesso"
# spec: R3 sem CA
tl_espera 1 "spec: regra sem CA bloqueia" …;            tl_contem "R3 sem critério de aceite" "nomeia a regra"
# spec: CA9 (R9) com R9 inexistente
tl_espera 1 "spec: CA cita regra inexistente" …;        tl_contem "CA9 cita R9" "nomeia o CA"
# spec: R1 confirmada com Fonte Q2
tl_espera 1 "spec: confirmada com fonte Q<n> bloqueia" …; tl_contem "R1 confirmada com fonte Q2" "nomeia a regra"
tl_espera 0 "design válido passa" sh -c "cd '$r' && sh '$dir/verifica-artefato.sh' design agentic/projeto/specs/pedidos"
# checagem 1: CA2 fora de toda task / fora de Como isso se prova
tl_espera 1 "design: CA sem task bloqueia" …;           tl_contem "CA2 sem task" "nomeia o CA"
tl_espera 1 "design: CA fora de Como isso se prova" …;  tl_contem "CA2 fora de 'Como isso se prova'" "nomeia o CA"
# checagem 2: Impacto cita docs/inexistente.md
tl_espera 1 "design: caminho citado inexistente" …;     tl_contem "docs/inexistente.md" "nomeia o caminho"
# checagem 2: Impacto cita src/pedidos/novo.py (não existe, mas casa src/pedidos/*)
tl_espera 0 "design: caminho a criar dentro de ## Arquivos passa" …
# checagem 3
tl_espera 1 "design: branch fora do formato <spec>/NNN-" …; tl_contem "**Branch:**" "nomeia o campo"
tl_espera 1 "design: duas tasks com a mesma branch" …
tl_espera 1 "design: worktree pedidos/001-x e task 001 com outra branch" …
# checagem 4
tl_espera 1 "design: Decisão do humano preenchida" …;   tl_contem "Decisão do humano" "nomeia a coluna"
tl_espera 1 "design: Status diferente de draft" …
# checagem 5
tl_espera 1 "design: arquivo em CAMINHOS_N3 sem item N3 na task" …;  tl_contem "CAMINHOS_N3" "explica a origem"
tl_espera 0 "design: sem CAMINHOS_N3 pula com aviso" …;               tl_contem "aviso: CAMINHOS_N3" "avisa"
# checagem 6
tl_espera 1 "design: símbolo de Produz ausente do contrato" …;        tl_contem "criar_pedido" "nomeia o símbolo"
# checagem 7
tl_espera 1 "design: CMD_VALIDA_CONTRATO falha" …;                    tl_contem "CMD_VALIDA_CONTRATO" "nomeia o comando"
tl_espera 0 "design: sem CMD_VALIDA_CONTRATO pula com aviso" …
# modo mudanca
tl_espera 0 "mudança válida passa" …
tl_espera 1 "mudança: Branch diferente da branch atual" …
tl_espera 1 "mudança: Rulings não vazia antes do Gate 1" …
tl_espera 1 "mudança: resposta no Questionário escrita fora de comentário" …
tl_espera 1 "mudança: arquivo em CAMINHOS_N3 com tabela N3 sem linha" …
# Review Focus 1–3
tl_espera 0 "artefatos com CRLF passam igual" …        # unix2dos via sed 's/$/\r/'
tl_espera 0 "comentários do template não contam" …     # <!-- CA7 (R7) … `docs/x/y.md` --> no design
tl_espera 0 "sufixo :12-30 é ignorado na existência" …
tl_espera 2 "modo desconhecido é erro de uso" sh -c "cd '$r' && sh '$dir/verifica-artefato.sh' outro x"
tl_espera 1 "acumula as falhas antes de sair" …;        tl_contem "BLOQUEADO (2 falha(s))" "conta as falhas"
```

- [ ] **Step 2: Rodar a suíte e ver a falha**

Run: `sh mecanismos/scripts/verifica-artefato.Tests.sh`
Expected: FALHA em todos os casos (script inexistente), com o resumo `… falhas` diferente de 0.

- [ ] **Step 3: Implementar `verifica-artefato.sh`**

Estrutura:
- carrega `lib-agentic.sh`;
- `secao <arquivo> <título>` imprime o corpo da seção pelas regras acima;
- `falha <texto>` imprime `agentic: BLOQUEADO — <texto>` e incrementa o contador;
- uma função por checagem: `ck_regras_cas` (spec e mudanca), `ck_cas_tasks` (1), `ck_caminhos` (2), `ck_branch` (3), `ck_sem_aprovacao` (4), `ck_n3_caminhos` (5), `ck_produz` (6), `ck_contrato` (7).

Detalhes:
- **Checagem 6:** o símbolo é o token entre crases de `- Produz:` até o primeiro `(`. Procurar com `git grep -q -F --untracked -e <símbolo> -- . ':!agentic/' ':!docs/'`. Linha com `nenhum` (sem distinção de maiúsculas) é pulada.
- **Checagem 3:**
  - modo `design`: se a branch atual começa com `<nome da spec>/`, a task 001 tem essa branch;
  - modo `mudanca`: `**Branch:**` igual à branch atual.
- **Checagem 4, modo `mudanca`:** `## Rulings` e `## Questões em aberto` só com `- Nenhuma.` ou vazias; em `## Questionário`, nenhuma linha fora de comentário começa com `Resposta`.
- **Checagem 5:** casa cada entrada de `## Arquivos` com cada glob de `CAMINHOS_N3` (`case "$entrada" in $glob)`, com `set -f`). Na trilha padrão, exige `N3-` na seção `## N3 aprovados no Gate 1` da task. Na mudança, exige uma linha `| N3-` na tabela de itens N3.
- **Checagem 7:** `( eval "$CMD_VALIDA_CONTRATO" ) </dev/null`. Com falha, imprime as últimas 20 linhas da saída.

- [ ] **Step 4: Rodar a suíte e ver passar**

Run: `sh mecanismos/scripts/verifica-artefato.Tests.sh`
Expected: `… testes, 0 falhas`

- [ ] **Step 5: Ligar ao processo**

- **`core/templates/brief.md`, "Ao receber":** item novo, antes do revisor de spec, design ou mudança: `` `sh agentic/mecanismos/scripts/verifica-artefato.sh <spec|design|mudanca> <caminho>` verde; com falha, o trabalho volta ao autor sem despachar o revisor ``.
- **`ciclo.md`:** na tabela da trilha padrão, a coluna Verificação das fases 1 e 2 vira `` `verifica-artefato.sh` → `revisor` modo … ``. No item "Revisão antes do Gate 1" da trilha enxuta, a mesma ordem. Acrescentar uma linha: "roda só antes do Gate 1; artefato aprovado antes desta versão do kit não é verificado".
- **`config.padrao`:** com comentário "Opcional. Vazio = checagem pulada com aviso".
- **`entrevista.md`:** as duas perguntas novas.
- **`coerencia-kit.Tests.sh`:** bloco `# --- Revisão que converge, Task 1` com `tem core/templates/brief.md 'verifica-artefato.sh'`, `tem core/processo/ciclo.md 'verifica-artefato.sh'` e `tem bootstrap/config.padrao 'CAMINHOS_N3='`.

- [ ] **Step 6: Verify do kit**

Run: `sh scripts/verify.sh`
Expected: `verify: OK`

- [ ] **Step 7: Commit**

```bash
git add mecanismos/scripts/verifica-artefato.sh mecanismos/scripts/verifica-artefato.Tests.sh mecanismos/scripts/lib-agentic.sh bootstrap/config.padrao bootstrap/entrevista.md core/templates/brief.md core/processo/ciclo.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(verifica-artefato): barreira mecânica antes do revisor de spec, design e mudança"
```

---

### Task 2: Impacto é entrega do arquiteto

Design §7.1, mais a regra das decisões do design sem prefixo `D` (§7.7, "Atrito").

**Files:**
- Modify: `core/papeis/arquiteto.md` ("Consome", "Produz" partido em itens curtos, "Modo enxuto")
- Modify: `core/papeis/dominio.md` ("Produz")
- Modify: `core/templates/design.md` (seção `## Impacto` e comentário em `## Decisões`)
- Modify: `core/templates/mudanca.md` (seção `## Impacto`)
- Modify: `core/processo/ciclo.md` ("Regras de fluxo": item "Emenda a outra spec")
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Produces: a seção `## Impacto`, lida pela checagem 2 da Task 1. O cabeçalho é exatamente:
  `| Alterado (símbolo, rota, schema, regra) | Quem usa hoje (arquivo:linha, medido) | Em ## Arquivos de | Teste existente afetado | Regra de outra spec → emenda |`

- [ ] **Step 1: Escrever as asserções de coerência**

```sh
for t in core/templates/design.md core/templates/mudanca.md; do
  tl_espera 0 "$t: seção ## Impacto" tem $t '## Impacto'
  tl_espera 0 "$t: colunas do Impacto" tem $t '| Alterado (símbolo, rota, schema, regra) | Quem usa hoje (arquivo:linha, medido) |'
done
tl_espera 0 "design: Impacto depois do contrato" ordem core/templates/design.md '## Contrato executável' '## Impacto'
tl_espera 0 "mudança: Impacto depois de Arquivos" ordem core/templates/mudanca.md '## Arquivos' '## Impacto'
tl_espera 0 "design: decisões sem prefixo D" tem core/templates/design.md 'sem o prefixo `D`'
tl_espera 0 "arquiteto consome o código e as specs afetadas" tem core/papeis/arquiteto.md 'specs aprovadas que a mudança toca'
tl_espera 0 "arquiteto produz o Impacto" tem core/papeis/arquiteto.md '## Impacto'
tl_espera 0 "dominio: estado atual com fonte" tem core/papeis/dominio.md 'estado atual'
tl_espera 0 "ciclo: emenda a outra spec" tem core/processo/ciclo.md 'Emenda a outra spec'
tl_espera 1 "arquiteto: Produz sem item com mais de 400 caracteres" sh -c \
  "tr -d '\r' < '$raiz/core/papeis/arquiteto.md' | sed -n '/^## Produz/,/^## /p' | awk 'length > 400' | grep -q ."
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh`
Expected: FALHA nas asserções novas.

- [ ] **Step 3: Escrever o texto**

- **`arquiteto.md`:**
  - "Consome" ganha: `- O código do repositório e as specs aprovadas que a mudança toca (leia antes de desenhar; o que você afirma sobre eles é medido).`
  - "Produz": o item atual do contrato executável (um parágrafo de 10 linhas) vira sub-itens de até 2 linhas, com o mesmo conteúdo: o que é contrato, o que pode ter corpo, stub da stack, invariante documentada, validação registrada. Novo item: `` `## Impacto` no design: cada símbolo, rota, schema ou regra alterada; quem usa hoje (`arquivo:linha`, achado por busca, `medido`); em que task está; que teste existente quebra; que regra de outra spec aprovada muda — com a emenda, que vira item do Gate 1. ``
  - "Modo enxuto": a mesma seção no documento único.
- **`design.md`:**
  - a seção `## Impacto` vai depois de `## Contrato executável`, com a tabela e o comentário "toda linha `medido`; sem impacto fora dos arquivos novos: escreva `- Nenhum (só arquivos novos).`";
  - em `## Decisões`, o comentário `<!-- numere 1, 2, 3… sem o prefixo `D`: o prefixo é das decisões do projeto (agentic/projeto/decisoes.md) -->`.
- **`mudanca.md`:** a mesma seção, depois de `## Arquivos`.
- **`dominio.md`, "Produz":** `- Afirmação sobre o estado atual ("hoje o sistema…", "a documentação não diz…") cita o arquivo ou o oráculo aberto, como regra.`
- **`ciclo.md`, "Regras de fluxo":** item **Emenda a outra spec**, com o texto do design §7.1:
  - declarada no Impacto e aprovada como item no Gate 1;
  - depois do Gate 1, commit `docs(spec): <outra spec> — Emenda <n> (<esta spec>)` na branch da primeira task que depende dela, com o arquivo em `## Arquivos`.

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh`
Expected: `verify: OK`

- [ ] **Step 5: Commit**

```bash
git add core/papeis/arquiteto.md core/papeis/dominio.md core/templates/design.md core/templates/mudanca.md core/processo/ciclo.md scripts/coerencia-kit.Tests.sh
git commit -m "docs(papeis): impacto medido como entrega do arquiteto; emenda a outra spec"
```

---

### Task 3: Uma lista só, usada pelo autor e pelo revisor

Design §7.2.

**Files:**
- Modify: `core/papeis/dominio.md`, `arquiteto.md`, `testes.md`, `dev.md` (seção `## Pronto para revisão` e o "Ao terminar")
- Modify: `core/papeis/revisor.md` ("Modos")
- Modify: `core/templates/perfil-papel.md` (comentário "Como preencher")
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Produces: a seção `## Pronto para revisão` em cada contrato de autor, entre `## No brief` e `## Ao terminar`. O revisor a referencia pelo nome.

- [ ] **Step 1: Escrever as asserções**

```sh
for papel in dominio arquiteto testes dev; do
  c=core/papeis/$papel.md
  tl_espera 0 "$papel: tem Pronto para revisão" tem $c '## Pronto para revisão'
  tl_espera 0 "$papel: depois de No brief" ordem $c '## No brief' '## Pronto para revisão'
  tl_espera 0 "$papel: antes de Ao terminar" ordem $c '## Pronto para revisão' '## Ao terminar'
  tl_espera 0 "$papel: autoconferência no relatório" tem $c 'autoconferência'
done
tl_espera 0 "revisor: modos usam a lista do autor" tem core/papeis/revisor.md '"Pronto para revisão"'
tl_espera 0 "perfil: padrão do revisor espelhado no autor" tem core/templates/perfil-papel.md 'Pronto para revisão'
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh` → FALHA nas novas.

- [ ] **Step 3: Escrever as listas (conteúdo decidido aqui)**

- **`dominio` (spec):**
  - toda regra tem `Fonte:` que você abriu, e estado `confirmada` ou `hipótese`;
  - toda regra tem CA, e todo CA é dado/quando/então com resultado observável;
  - toda `hipótese` é pergunta no Questionário, com opções e recomendação;
  - afirmação sobre o estado atual cita a fonte aberta;
  - regra que contradiz spec aprovada ou glossário está em "Divergências", com pergunta;
  - nada fora do intent; nada de stack.
- **`arquiteto` (design e mudança):**
  - o contrato valida, com saída registrada (`medido`);
  - o contrato é só esqueleto, e todo corpo que não é stub está na declaração de corpos;
  - o esqueleto tem tudo que o RED vai referenciar;
  - Impacto preenchido por busca (chamadores, testes afetados, emendas), e todo arquivo dele que muda está em `## Arquivos` de uma task;
  - todo CA tem task e linha em "Como isso se prova";
  - todo gatilho N3 visível está em "Itens N3", e cada task cita os que usa;
  - decisões do design sem prefixo `D`;
  - "Decisão do humano", "Questões em aberto" e "Rulings" vazias; nada afirma aprovação;
  - `verifica-artefato.sh` verde.
- **`testes` (RED):**
  - cada CA da task tem teste que falha pelo motivo do CA, não por símbolo ausente do contrato;
  - só a resposta certa satisfaz a asserção;
  - as bordas citadas no CA são exercitadas;
  - teste de caracterização (passa no HEAD) não entra no RED;
  - os limites das regras têm caso no valor limite;
  - cada CA anotado com `→ test: <arquivo>::<nome>` no commit RED (Task 9).
- **`dev` (GREEN):**
  - verify verde;
  - nada feito para casar com o teste (estado estático, valor mágico, resposta fabricada);
  - a forma do perfil é respeitada (camadas, regra fora da apresentação);
  - nada fora do design; divergência é pergunta.

**"Ao terminar"** de cada autor ganha: `Grave no relatório a autoconferência: um item da lista "Pronto para revisão" (contrato e perfil) por linha, `ok` ou `n.a. — <motivo>`, com a evidência. Item sem marca conta como não feito.`

**`revisor.md`, modos `spec`, `design` e `mudanca`:**
- abrem com "Confere a lista "Pronto para revisão" do autor (contrato e perfil) e a seção "Casos a cobrir" do brief";
- mantêm só o que é do revisor: abrir cada citação, rodar a validação, procurar ambiguidade, defeito e escopo vazando, e a classificação errada (enxuta).

**Modo `diff`:** começa por "Confere a lista "Pronto para revisão" de `testes` e `dev`" e mantém todo o texto atual.

**`perfil-papel.md`, "Como preencher":** `- Item de "Padrões" do revisor que cobra o autor entra também no perfil do autor, na lista "Pronto para revisão" que ele confere (conferência por revisão).`

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh` → `verify: OK`

- [ ] **Step 5: Commit**

```bash
git add core/papeis core/templates/perfil-papel.md scripts/coerencia-kit.Tests.sh
git commit -m "docs(papeis): lista Pronto para revisão compartilhada por autor e revisor"
```

---

### Task 4: Orquestrador não desenha; parecer não prescreve; revisão converge e mede a causa

Design §7.4, §7.5 e §7.6. É um objetivo só: o que circula entre as rodadas (brief → parecer → brief de correção).

**Files:**
- Modify: `core/templates/brief.md` ("O que fazer", "Já decidido", seção nova "## Casos a cobrir", "Antes de enviar", "Desde a rodada anterior")
- Modify: `core/templates/parecer.md` (coluna Causa; texto de Problema; comentário "Escala do kit": Menor não abre rodada)
- Modify: `core/papeis/revisor.md` (seção "## Rodada de correção"; em "Produz", Menor passa a "vai com a próxima correção ou no PR")
- Modify: `core/processo/ciclo.md` (tabela da trilha padrão: as duas linhas sob ela; "Orquestração"; "Rulings")
- Modify: `adapters/claude-code/CLAUDE.md` e `adapters/copilot/copilot-instructions.md`, só onde repetem "Menores … revisão final da branch". Conferir com `grep -rn "revisão final" adapters core`.
- Modify: `core/templates/pr.md` ("Parecer do revisor": uma linha por rodada)
- Modify: `scripts/coerencia-kit.Tests.sh`

- [ ] **Step 1: Escrever as asserções**

```sh
tl_espera 0 "pr: resumo por rodada" tem core/templates/pr.md 'r<k> <modo>: <veredito> · C n I n M n · causas:'
b=core/templates/brief.md
tl_espera 0 "brief: seção Casos a cobrir" tem $b '## Casos a cobrir'
tl_espera 0 "brief: Casos a cobrir é condicional (depois de Entrega)" ordem $b '## Entrega' '## Casos a cobrir'
tl_espera 0 "brief: Já decidido só com origem citável" tem $b 'origem citável'
tl_espera 0 "brief: Antes de enviar confere decisão sem origem" tem $b 'nenhuma linha decide algo sem origem citável'
p=core/templates/parecer.md
tl_espera 0 "parecer: coluna Causa" tem $p '| ID | Classe | Causa | Onde | Problema | Evidência |'
tl_espera 0 "parecer: valores de Causa" tem $p 'defeito | contrato | não conferido | sem contrato | forma'
tl_espera 0 "parecer: marca já na rodada 1" tem $p 'já na rodada 1'
tl_espera 1 "parecer: não prescreve correção" tem $p 'o que outro papel deve fazer'
tl_espera 0 "revisor: rodada de correção" tem core/papeis/revisor.md '## Rodada de correção'
tl_espera 0 "ciclo: 3ª devolução vai ao humano" tem core/processo/ciclo.md '3ª devolução'
tl_espera 0 "kit: Menor não abre rodada" tem core/processo/ciclo.md 'Menor não abre rodada'
tl_espera 0 "kit sem Menor só na revisão final" nenhum 'Menor.{0,60}revisão final da branch' core adapters
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh` → FALHA nas novas.

- [ ] **Step 3: Escrever o texto**

- **`brief.md`:**
  - **"O que fazer":** `<até 5 linhas; cada uma, uma entrega verificável — a entrega, nunca a solução: valor, nome, caminho de implementação só se vier de "Já decidido">`.
  - **"Já decidido":** `<só o que tem origem citável, um por linha com a origem: resposta do humano (data), R-n, D<n>, item N3 aprovado; ou: nenhum>`.
  - **Seção nova "## Casos a cobrir",** depois de "## Entrega" (condicional): `<casos de borda e ataques que o orquestrador quer cobertos: o MESMO texto vai no brief do autor e no do revisor>`.
  - **"Antes de enviar":** dois itens novos: `nenhuma linha decide algo sem origem citável` e `"Casos a cobrir" igual no brief do autor e no do revisor`.
  - **"Desde a rodada anterior":** acrescentar `o autor atualiza o Impacto e a autoconferência para tudo que a correção mudou`.
- **`parecer.md`:**
  - a tabela de achados vira `| ID | Classe | Causa | Onde | Problema | Evidência |`;
  - comentário com os valores de Causa: `defeito | contrato | não conferido | sem contrato | forma`; na rodada ≥ 2, `· já na rodada 1` quando o defeito já estava no artefato da rodada 1; `sem contrato` diz em Problema onde a regra deveria estar;
  - Problema: `<o que está errado e o que precisa passar a ser verdade; nunca a correção>`.
- **`revisor.md`, seção nova "## Rodada de correção",** antes de "## Consome":
  - confere cada achado anterior na tabela "Rodada anterior";
  - revisa o delta e o impacto do delta;
  - achado novo fora do delta, Crítico ou Importante, entra e bloqueia, marcado `já na rodada 1`.
- **`ciclo.md`:**
  - as duas linhas sob a tabela da trilha padrão passam a dizer: devolução volta ao autor, que atualiza o Impacto e a autoconferência do que mudou; **Menor não abre rodada**: vai com a próxima correção ou, sem ela, no PR;
  - na **3ª devolução** do mesmo artefato, o orquestrador para e leva ao humano as causas por rodada antes de despachar a 4ª;
  - "Orquestração", item 3: o brief não decide sem origem citável;
  - "Rulings": Ruling não contradiz spec nem design aprovados; se precisaria, é pergunta.
- **`pr.md`, "Parecer do revisor":** linha `- Rodadas: <uma por rodada de todos os modos da task: r<k> <modo>: <veredito> · C n I n M n · causas: <valor>=<n> …>`. É o registro durável da coluna Causa (design §7.6).

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh` → `verify: OK`. Os exemplos de `docs/exemplos-brief` são conferidos pela Task 6 da coerência. Se algum quebrar com a seção nova, ajuste o exemplo (design §11).

- [ ] **Step 5: Commit**

```bash
git add core/templates/brief.md core/templates/parecer.md core/templates/pr.md core/papeis/revisor.md core/processo/ciclo.md adapters scripts/coerencia-kit.Tests.sh docs/exemplos-brief
git commit -m "docs(revisao): brief sem desenho, parecer sem prescrição, causa medida e rodadas que convergem"
```

---

### Task 5: Base única e ordem barata no verify

Design §7.7, itens 1 e 2.

**Files:**
- Modify: `mecanismos/scripts/lib-agentic.sh` (`agentic_base`, nova `agentic_base_task`)
- Modify: `mecanismos/scripts/verify.sh`
- Modify: `mecanismos/scripts/verifica-escopo.sh`, `verifica-skip.sh`, `verifica-red.sh`, `verifica-decisoes.sh` (argumento posicional pelo merge-base)
- Test: `mecanismos/scripts/verify.Tests.sh`, `verifica-escopo.Tests.sh`, `verifica-red.Tests.sh`

**Interfaces:**
- Produces:
  - `agentic_base_task` imprime a ref da branch `**Base:**` da task da branch atual, se ela existe e ainda não está na principal; senão, nada;
  - `agentic_base` usa `AGENTIC_BASE`, depois `agentic_base_task` e por último a principal, sempre devolvendo o merge-base com HEAD;
  - nos scripts, `base=$(git merge-base HEAD "$1")` quando o argumento é dado;
  - `verify.sh` exporta `AGENTIC_BASE` antes de qualquer etapa.
  - Ordem das etapas: hooks → escopo → decisões → red → stack → skip.

- [ ] **Step 1: Escrever os testes**

- **`verify.Tests.sh`:**
  - `tl_espera 0 "etapas na ordem barata" …`, e depois o `awk` confere que as linhas `== hooks`, `== escopo`, `== decisoes`, `== red`, `== stack` e `== skip` aparecem nessa ordem no `$TL_SAIDA`;
  - `tl_espera 0 "stack recebe AGENTIC_BASE da task empilhada" …`, com `CMD_VERIFY_STACK="echo base=\$AGENTIC_BASE"` e `tl_contem "base=pedidos/001" …`.
- **`verifica-red.Tests.sh`:**
  - `tl_espera 0 "avulso em branch empilhada não prova o RED da base" …`. A base tem um RED cujo teste passa no HEAD da base. A task 002 tem `**Base:** pedidos/001`; rodar `verifica-red.sh` sem argumento e sem `AGENTIC_BASE`. Esperado: `tl_contem "nenhum commit test(red):"` ou só os REDs da 002.
- **`verifica-escopo.Tests.sh`:**
  - `tl_espera 0 "base posicional usa merge-base: arquivo que só a base mudou depois não conta" …`. A branch 002 sai da 001, a 001 recebe um commit novo em `src/outro.py`, e roda-se `verifica-escopo.sh <task 002> pedidos/001`.
- **Review Focus 4:**
  - `tl_espera 0 "Base apagada depois de integrada cai para a principal" …`. A task tem `**Base:** pedidos/001`, a branch 001 foi integrada na main e apagada; `verify.sh` termina `VERIFY: OK` e mostra `base: principal`.

- [ ] **Step 2: Rodar e ver falhar**

Run:
```
sh mecanismos/scripts/verify.Tests.sh
sh mecanismos/scripts/verifica-red.Tests.sh
sh mecanismos/scripts/verifica-escopo.Tests.sh
```
Expected: FALHA nos casos novos.

- [ ] **Step 3: Implementar**

- Mover para `agentic_base_task` em `lib-agentic.sh` a derivação que hoje está em `verify.sh:52-66`: a task pelo `**Branch:**`, a `**Base:**`, a ref local ou `origin/`, e o teste "já integrada na principal".
- `verify.sh` chama essa função, exporta `AGENTIC_BASE` e imprime a linha `base: …`, tudo antes de `etapa hooks`. Em seguida reordena as etapas.
- Nos quatro scripts, trocar `base=${1:-$(agentic_base)}` por: com argumento, `base=$(git merge-base HEAD "$1") || agentic_falha "base inválida: $1"`; sem argumento, `agentic_base`.

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh` → `verify: OK`. As baterias atuais, incluindo os 64 casos do `verifica-red.Tests.sh`, continuam verdes.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/lib-agentic.sh mecanismos/scripts/verify.sh mecanismos/scripts/verifica-*.sh mecanismos/scripts/*.Tests.sh
git commit -m "fix(verify): base única para todos os scripts e etapas baratas primeiro"
```

---

### Task 6: Cache da prova de RED por SHA

Design §7.7, itens 3 e 4, reimplementado pela descrição.

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh`
- Test: `mecanismos/scripts/verifica-red.Tests.sh`
- Modify: `core/processo/ciclo.md` ("Regras de fluxo", "Verificação": uma frase sobre o cache e `AGENTIC_RED_SEM_CACHE=1`)

**Interfaces:**
- Produces:
  - arquivo `$(git rev-parse --git-common-dir)/agentic/red-provados`, com uma linha por prova: `<sha completo do RED> <assinatura> <arquivo>`;
  - assinatura: `printf '%s\n%s\n%s\n' "$CMD_PREPARAR_TESTE" "$CMD_TESTE_ARQUIVO" "$CMD_TESTE" | git hash-object --stdin`;
  - no modo degradado (sem `CMD_TESTE_ARQUIVO`), o campo arquivo é `*suite*`;
  - a variável `AGENTIC_RED_SEM_CACHE=1` ignora a leitura do cache, mas a gravação continua.

- [ ] **Step 1: Escrever os testes**

Preparação: `CMD_TESTE_ARQUIVO="echo x >> '$cont'; sh {}"`, com `$cont` fora do repositório. Ele conta quantas vezes cada arquivo foi executado.

```sh
tl_espera 0 "1ª prova executa" …;  [ "$(wc -l < "$cont")" -eq 1 ]
tl_espera 0 "2ª chamada usa o cache e não sobe worktree" …; tl_espera 0 "contador continua 1" sh -c "[ \$(wc -l < '$cont') -eq 1 ]"
tl_contem "já provado" "diz que usou o cache"
# muda CMD_TESTE_ARQUIVO no config (assinatura nova) → prova de novo
tl_espera 0 "assinatura nova prova de novo" …; contador 2
tl_espera 0 "AGENTIC_RED_SEM_CACHE=1 prova de novo" …; contador 3
# worktree ligado (git worktree add) na mesma branch: usa o cache do diretório comum
tl_espera 0 "cache compartilhado entre worktrees" …; contador inalterado
# RED que passava: bloqueia nas duas chamadas (nunca é guardado)
tl_espera 1 "RED que passava não é guardado (1ª)" …; tl_espera 1 "… nem na 2ª" …
# CMD_PREPARAR_TESTE="exit 1": bloqueia nas duas chamadas
tl_espera 1 "preparo com falha não é guardado" …
# produção no RED: bloqueia mesmo com prova guardada
tl_espera 1 "recusa de produção roda mesmo com cache" …
# asserção removida depois: bloqueia mesmo com prova guardada
tl_espera 1 "contagem de asserções roda mesmo com cache" …
# Review Focus 5: CMD_TESTE_ARQUIVO="cat >/dev/null; sh {}" e RED com tests/a.sh e tests/b.sh
tl_espera 0 "comando que lê stdin não come a lista de arquivos" …
tl_contem "(tests/a.sh)" "provou a.sh"; tl_contem "(tests/b.sh)" "provou b.sh"
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `sh mecanismos/scripts/verifica-red.Tests.sh` → FALHA nos novos.

- [ ] **Step 3: Implementar em `verifica-red.sh`**

- Novas funções `red_provado <sha> <arquivo>` (retorna 0 se a linha existe com a assinatura atual e `AGENTIC_RED_SEM_CACHE` não é 1) e `guarda_prova <sha> <arquivo>` (acrescenta a linha; cria o diretório).
- **No laço por RED:**
  - filtra `$lista`, deixando de fora os arquivos já provados, que imprimem `RED <curto>: já provado (<arquivo>) (ok)`;
  - se não sobrar nenhum arquivo (ou, no modo degradado, `*suite*` já provado), pula `worktree add`;
  - `avalia_rc` guarda a prova só no ramo `*)`, que é falha legítima;
  - toda execução de teste recebe `</dev/null`.
- A checagem de produção e a contagem de asserções ficam fora do `if` do cache.
- Atualizar o cabeçalho do script com o item (4) "cache".

- [ ] **Step 4: Rodar e ver passar**

Run: `sh scripts/verify.sh` → `verify: OK`. Os 64 casos antigos continuam verdes.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-red.sh mecanismos/scripts/verifica-red.Tests.sh core/processo/ciclo.md
git commit -m "perf(verifica-red): prova do RED guardada por SHA e assinatura; stdin isolado"
```

---

### Task 7: Verify em dois níveis

Design §7.7, item 5.

**Files:**
- Modify: `mecanismos/scripts/verify.sh` (opção `--rapido`)
- Modify: `mecanismos/scripts/lib-agentic.sh` (`CMD_VERIFY_RAPIDO=""`)
- Modify: `bootstrap/config.padrao`, `bootstrap/entrevista.md`
- Modify: `core/templates/brief.md` ("Ao receber"), `core/processo/ciclo.md` ("Verificação"), `core/papeis/testes.md` e `dev.md` ("Pronto para revisão": verify rápido no laço, completo antes de devolver)
- Modify: `adapters/claude-code/commands/verify.md`, `adapters/copilot/prompts/verify.prompt.md`
- Test: `mecanismos/scripts/verify.Tests.sh`, `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Produces:
  - `verify.sh [--rapido] [--task <task.md>]`, com as opções em qualquer ordem;
  - modo rápido: etapas hooks → escopo → decisões → red → `stack-rapido` (`CMD_VERIFY_RAPIDO`), sem `skip`;
  - última linha `VERIFY RÁPIDO: OK` ou `VERIFY RÁPIDO: FALHOU em:…`; o modo rápido nunca imprime `VERIFY: OK`;
  - sem `CMD_VERIFY_RAPIDO`: `aviso: CMD_VERIFY_RAPIDO não configurado — usando CMD_VERIFY_STACK`.

- [ ] **Step 1: Escrever os testes**

```sh
tl_espera 0 "rápido usa CMD_VERIFY_RAPIDO" …;  tl_contem "VERIFY RÁPIDO: OK" "linha final própria"
tl_espera 1 "rápido não imprime VERIFY: OK" grep -q "^VERIFY: OK" "$copia"
tl_espera 1 "rápido não roda skip" grep -q "== skip" "$copia"
tl_espera 0 "rápido sem a variável usa o stack completo com aviso" …; tl_contem "aviso: CMD_VERIFY_RAPIDO" "avisa"
tl_espera 0 "--task e --rapido em qualquer ordem" …
tl_espera 0 "coerência: Ao receber pede o completo antes do PR" tem core/templates/brief.md 'verify.sh --rapido'
```

- [ ] **Step 2: Rodar e ver falhar** — `sh mecanismos/scripts/verify.Tests.sh` → FALHA nos novos.

- [ ] **Step 3: Implementar e escrever o texto**

- **`verify.sh`:** laço de argumentos; `modo=rapido` troca a etapa `stack`, pula `skip` e troca o rótulo final.
- **`brief.md`, "Ao receber":** depois do RED, `verifica-red.sh`; depois de cada GREEN no laço, `verify.sh --rapido`; antes de despachar o revisor `diff` e antes do PR, `verify.sh` completo.
- **`ciclo.md`, "Verificação":** "o completo roda uma vez antes do PR e no revisor `diff`; no laço, o rápido".
- **`config.padrao`** e **`entrevista.md`:** a variável e a pergunta ("comando rápido: lint e testes tocados").
- **Adaptadores de `/verify`:** aceitam `--rapido`.

- [ ] **Step 4: Rodar e ver passar** — `sh scripts/verify.sh` → `verify: OK`

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verify.sh mecanismos/scripts/verify.Tests.sh mecanismos/scripts/lib-agentic.sh bootstrap core adapters scripts/coerencia-kit.Tests.sh
git commit -m "feat(verify): nível rápido no laço; completo antes do PR e no revisor"
```

---

### Task 8: Ruling e `em-andamento` sem commit próprio; caracterização antes do RED

Design §7.8 e o atrito do `verifica-red` (§7.7).

**Files:**
- Modify: `mecanismos/scripts/status-projeto.sh`
- Test: `mecanismos/scripts/status-projeto.Tests.sh`
- Modify: `core/processo/ciclo.md` ("Rulings → Onde"; trilha enxuta, "Sequência de commits"; "Status dos artefatos")
- Modify: `core/templates/task.md` e `mudanca.md` (comentário do Status: `em-andamento` deriva do git)
- Modify: `adapters/claude-code/commands/nova-task.md`, `adapters/copilot/prompts/nova-task.prompt.md` (passo 3 e passo 4), `adapters/claude-code/commands/mudanca.md`, `adapters/copilot/prompts/mudanca.prompt.md`
- Modify: `core/papeis/testes.md` (caracterização)
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Produces: na lista de artefatos do `status-projeto.sh`, uma task `pendente` cuja branch (`**Branch:**`) existe e está à frente da principal aparece como `- <arquivo>: em-andamento (derivado do git)`.

- [ ] **Step 1: Escrever os testes**

```sh
# task pendente com branch à frente da main
tl_espera 0 "status deriva em-andamento do git" …; tl_contem "001-criar.md: em-andamento (derivado do git)" "mostra derivado"
# task pendente sem branch
tl_espera 0 "pendente sem branch fica pendente" …;  tl_contem "001-criar.md: pendente" "mostra pendente"
# task com em-andamento escrito (legado)
tl_espera 0 "em-andamento escrito continua lido" …; tl_contem "001-criar.md: em-andamento" "lê o escrito"
# coerência
tl_espera 1 "nova-task não escreve em-andamento" tem adapters/claude-code/commands/nova-task.md 'Marque a task `**Status:** em-andamento`'
tl_espera 0 "ciclo: Ruling vai no próximo commit da task" tem core/processo/ciclo.md 'próximo commit da task'
tl_espera 1 "enxuta: sem commit de em-andamento" tem core/processo/ciclo.md '`docs(task): … em-andamento`'
tl_espera 0 "testes: caracterização antes do RED" tem core/papeis/testes.md 'caracterização'
```

- [ ] **Step 2: Rodar e ver falhar** — `sh mecanismos/scripts/status-projeto.Tests.sh` e `sh scripts/coerencia-kit.Tests.sh` → FALHA nos novos.

- [ ] **Step 3: Implementar e escrever o texto**

- **`status-projeto.sh`:** no `case "$s"`, ramo `pendente*`. Lê o `**Branch:**` do arquivo; se `git rev-parse --verify -q "<branch>^{commit}"` e `git rev-list --count "$BRANCH_PRINCIPAL..<branch>"` > 0, então `s="em-andamento (derivado do git)"`.
- **`ciclo.md`:**
  - "Rulings → Onde": a linha entra em `## Rulings` e vai no próximo commit da task (RED, GREEN, correção ou publicação); não há commit só de Ruling;
  - "Sequência de commits" da enxuta: sem `docs(task): … em-andamento`;
  - "Status": `em-andamento` deriva do git; `em-revisão` e `publicada` continuam escritos.
- **`nova-task`, nos dois adaptadores:**
  - passo 3 vira "crie `agentic/.estado/execucao/<AAAA-MM-DD>-<nome>/progress.md` …" (sem marcar Status);
  - passo 4: "commitada na branch" → "vai no próximo commit da task".
- **`mudanca`, nos dois adaptadores:** tirar `em-andamento` da lista do passo 6.
- **`testes.md`:** item em "Produz": `Teste de caracterização (prova o que já funciona e passa no HEAD) vai num commit `test:` antes do `test(red):`; o RED só leva testes que falham.`

- [ ] **Step 4: Rodar e ver passar** — `sh scripts/verify.sh` → `verify: OK`

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/status-projeto.sh mecanismos/scripts/status-projeto.Tests.sh core adapters scripts/coerencia-kit.Tests.sh
git commit -m "refactor(processo): Ruling e em-andamento sem commit próprio; caracterização antes do RED"
```

---

### Task 9: Vínculo CA → teste no commit RED

Design §7.9 (avaliação normativa, proposta 5.1).

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh` (checagem nova, item (5) do cabeçalho)
- Test: `mecanismos/scripts/verifica-red.Tests.sh`
- Modify: `core/papeis/testes.md` ("Produz": a anotação no commit RED)
- Modify: `core/templates/task.md` e `core/templates/mudanca.md` (comentário com o formato da anotação)
- Modify: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: a task da branch atual, achada pelo `**Branch:**` (a mesma busca de `agentic_base_task`, Task 5).
- Produces:
  - formato da anotação, numa linha de `## Critérios de pronto` (task) ou `## Critérios de aceite` (mudança): `CA<n> (<R…>): <texto> → test: <arquivo>::<nome>`. Mais de um teste fica separado por `; `;
  - mensagens `agentic: BLOQUEADO — CA<n> sem → test: na task <arquivo>` e `agentic: BLOQUEADO — <arquivo> anotado em CA<n> não foi tocado por commit test(red):`;
  - task sem nenhuma anotação: `aviso: task sem anotação → test: (anterior a esta versão do kit) — vínculo CA → teste não verificado`.

- [ ] **Step 1: Escrever os testes**

```sh
tl_espera 0 "todo CA anotado com arquivo do RED passa" …
tl_espera 1 "CA sem anotação, com outro anotado, bloqueia" …;   tl_contem "CA2 sem → test:" "nomeia o CA"
tl_espera 1 "arquivo anotado fora dos commits RED bloqueia" …; tl_contem "tests/outro.sh" "nomeia o arquivo"
tl_espera 0 "task sem nenhuma anotação passa com aviso" …;      tl_contem "aviso: task sem anotação" "avisa"
tl_espera 0 "dois testes num CA separados por ; " …
tl_espera 0 "anotação com CRLF" …
tl_espera 0 "branch sem task (trilha rápida) não checa" …
```

- [ ] **Step 2: Rodar e ver falhar** — `sh mecanismos/scripts/verifica-red.Tests.sh` → FALHA nos novos.

- [ ] **Step 3: Implementar**

- Ao fim do `verifica-red.sh`, se há commits RED e a task da branch existe:
  - extrai as linhas `CA<n>` da seção, sem `` e sem comentários;
  - os arquivos anotados são o texto depois de `→ test:`, até `::`, para cada item separado por `; `;
  - o conjunto dos tocados é a união de `git diff-tree --name-only -r` dos commits RED.
- **Texto:**
  - `testes.md`, "Produz": a anotação no mesmo commit `test(red):`;
  - comentário nos templates com o formato.

- [ ] **Step 4: Rodar e ver passar** — `sh scripts/verify.sh` → `verify: OK`

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-red.sh mecanismos/scripts/verifica-red.Tests.sh core/papeis/testes.md core/templates/task.md core/templates/mudanca.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(verifica-red): vínculo CA → teste anotado no commit RED"
```

---

### Task 10: Nota de atualização para as instâncias

Design §10.

**Files:**
- Modify: `README.md` (seção "## O que muda ao atualizar o kit", depois de "## O que é instalado no projeto")
- Modify: `scripts/coerencia-kit.Tests.sh`

- [ ] **Step 1: Asserção** — `tl_espera 0 "README: nota de atualização" tem README.md '## O que muda ao atualizar o kit'`. Rodar e ver falhar.

- [ ] **Step 2: Escrever a seção**

Até 15 linhas:
- as três variáveis novas e opcionais (`CMD_VALIDA_CONTRATO`, `CAMINHOS_N3`, `CMD_VERIFY_RAPIDO`) e o efeito de deixá-las vazias;
- o `verifica-artefato.sh` na lista "Ao receber";
- a seção Impacto e "Pronto para revisão";
- a coluna Causa no parecer e o resumo das rodadas no PR;
- a anotação `CA → test:` no commit RED;
- `em-andamento` derivado;
- Ruling sem commit próprio;
- artefatos aprovados antes da atualização não são verificados de novo;
- como medir: `grep` da coluna Causa nos pareceres de `agentic/.estado/execucao/`.

- [ ] **Step 3: Rodar** — `sh scripts/verify.sh` → `verify: OK`

- [ ] **Step 4: Commit**

```bash
git add README.md scripts/coerencia-kit.Tests.sh
git commit -m "docs(readme): o que muda ao atualizar o kit (revisão que converge)"
```
