# Decisões por arquivo e delegação local do Gate 1 — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** decisão nova vira `agentic/projeto/decisoes/<slug>.md`, citada como `D:<slug>`, sem colisão entre branches; a delegação do Gate 1 e o modo automático passam ao `agentic/auto-mode` local, fora do git.

**Architecture:** o `verifica-decisoes.sh` ganha a pasta como segunda fonte (o `decisoes.md` fica congelado) e troca a delegação por `D<n>` pela leitura de `gate1:`/`plano:`/`n3:` do `auto-mode` local. O `verifica-red.sh` aceita `D:<slug>` no trailer. O `instalar.sh` trata o `auto-mode` como arquivo do dev. Os textos do kit passam ao formato novo, conferidos pelo `coerencia-kit`.

**Tech Stack:** POSIX sh (também Git Bash no Windows), git, awk, sed; testes no `testlib.sh` do kit (`tl_repo`, `tl_espera`, `tl_contem`, `tl_fim`).

**Spec:** `docs/specs/2026-11-25-decisoes-por-arquivo-design.md`

## Global Constraints

- POSIX sh; nenhuma dependência nova nos scripts (sem node, python, jq).
- Slug: ERE `^[a-z0-9]+(-[a-z0-9]+)*$`. Referência: `D:<slug>`. Arquivo: `agentic/projeto/decisoes/<slug>.md`.
- `**Status:**` válido: ERE `^\*\*Status:\*\* (vigente|revogada em [0-9]{4}-[0-9]{2}-[0-9]{2}: .+)$`.
- `gate1:` vazio, `todas` ou lista `<nome>, <nome>` (cada nome sem espaço nem vírgula).
- Commit de registro delegado: `docs(spec|mudanca): <nome> aprovada (Gate 1 delegado)`; o formato antigo `(Gate 1 delegado, D<n>)` é aceito e o `D<n>` é ignorado.
- `verifica-decisoes.sh` em lote: nenhum processo por arquivo de decisão ou por referência (evidências §13: 48,8 s → 1,0 s).
- As `D<n>` existentes continuam resolvendo pelo `decisoes.md`; os testes atuais de referências `D<n>` e de perda de `D<n>` passam sem mudar de comportamento.
- Mensagens no formato existente: `agentic: BLOQUEADO — …`, `degradado: …`, `aviso: …`, `verifica-decisoes: OK`.
- Nada de nome de projeto em arquivo versionado (o `coerencia-kit` confere com `.nomes-proibidos`).
- Verificação final: `sh scripts/verify.sh` termina em `verify: OK`.

## Review Focus

1. Arquivo de decisão com CRLF (instância no Windows): título e `**Status:**` válidos não podem ser recusados. Teste na Task 1.
2. `D:<slug>` seguido de pontuação (`D:cache-de-precos.`, `(D:cache-de-precos)`, `D:cache-de-precos,`) e slug que é prefixo de outro (`D:cache` com só `cache-de-precos.md` existindo): resolve o slug inteiro, e `D:cache` é órfã. Teste na Task 1.
3. Arquivo dentro de `decisoes/` que não é `.md` (`.gitkeep`) ou em subpasta: ignorado, não recusado como formato. Teste na Task 1.
4. `gate1:` com espaço extra e CRLF (`gate1:  pedidos , estoque\r`): a lista é lida como `pedidos` e `estoque`. Teste na Task 2.
5. Reinstalação do kit sobre um `agentic/auto-mode` editado pelo dev (`enabled: true`): o arquivo fica intacto e não aparece em conflitos. Teste na Task 4.

---

### Task 1: `verifica-decisoes` lê a pasta de decisões

**Files:**
- Modify: `mecanismos/scripts/verifica-decisoes.sh` (cabeçalho, pulo inicial, checagens 1 e 2; checagens 3 e 4 novas)
- Test: `mecanismos/scripts/verifica-decisoes.Tests.sh`

**Interfaces:**
- Produces: `dir=agentic/projeto/decisoes`; checagens numeradas no cabeçalho como no design §4.4 (1 a 4; a 5 é da Task 2).

- [ ] **Step 1: Escrever os testes que falham**

Helper novo no arquivo de testes: `dec <repo> <slug> [status]` grava `agentic/projeto/decisoes/<slug>.md` com `# <slug>`, linha em branco e `**Status:** <status>` (padrão `vigente`). Testes, um `tl_espera` cada, com o código esperado:

| Teste | Situação | Código | `tl_contem` |
|---|---|---|---|
| só a pasta, sem `decisoes.md`, referência resolve | `dec cache-de-precos`; spec cita `D:cache-de-precos.` | 0 | — |
| referência `D:<slug>` órfã | spec cita `D:frete` sem arquivo | 1 | `D:frete (em agentic/projeto/specs/x/design.md)` |
| prefixo de slug não resolve | só `cache-de-precos.md`; spec cita `(D:cache)` | 1 | `D:cache (em` |
| decisão em arquivo cita outra | `dec a`; `decisoes/b.md` cita `D:zzz` | 1 | `D:zzz (em agentic/projeto/decisoes/b.md)` |
| `D<n>` sem `decisoes.md` é órfã | só a pasta; spec cita `D3` | 1 | `D3 (em` |
| arquivo da base apagado | base com `dec a`; HEAD sem ele | 1 | `revogue-a): a` |
| arquivo da base renomeado | base `a.md`; HEAD `a2.md` | 1 | `revogue-a): a` |
| `### D<n>` nova no registro congelado | base `reg 1`; HEAD `reg 1 2` | 1 | `D2` e `decisoes/<slug>.md` |
| `### D<n>` da base que continua | base e HEAD `reg 1 2` | 0 | — |
| nome fora do slug | `decisoes/Cache_Precos.md` | 1 | `Cache_Precos.md: nome não é slug` |
| sem título | arquivo começando por `**Status:**` | 1 | `sem título` |
| status inválido | `**Status:** aprovado` | 1 | `**Status:**` |
| revogada válida | `dec a "revogada em 2026-11-25: trocada por b"` | 0 | — |
| CRLF | arquivo válido gravado com `\r\n` | 0 | — |
| `.gitkeep` e subpasta ignorados | `decisoes/.gitkeep`, `decisoes/x/y.md` sem formato | 0 | — |
| sem registro nem pasta | repo vazio | 0 | `pulado` |

O teste existente "Gate 1 delegado sem registro de decisões bloqueia" sai nesta task (a delegação deixa de depender de decisão; a Task 2 cobre o `auto-mode`).

- [ ] **Step 2: Rodar e confirmar que falham**

Run: `sh mecanismos/scripts/verifica-decisoes.Tests.sh`
Expected: falhas nos testes novos; os antigos de `D<n>` continuam `ok`.

- [ ] **Step 3: Implementar**

- Pulo inicial: sem `decisoes.md` **e** sem a pasta, imprime `verifica-decisoes: sem registro de decisões — pulado` e sai 0. O bloqueio "auto-mode delega o Gate 1, mas não há decisão" sai.
- `definidas` passa a ser vazio quando o `decisoes.md` não existe.
- (1) Uma varredura: o `find … -exec grep -o -E` atual com a ERE `(^|[^A-Za-z0-9_])(D[0-9]+|D:[a-z0-9]+(-[a-z0-9]+)*)([^A-Za-z0-9_-]|$)`, sobre `agentic/projeto/**/*.md` fora o `decisoes.md` (a pasta entra; o `auto-mode` sai). `D<n>` resolve em `$definidas`; `D:<slug>` resolve na lista de slugs da pasta (`find "$dir" -maxdepth 1 -type f -name '*.md'`, nome sem `.md`), passada ao `awk` pelo ambiente, como o `ausentes` atual. Saída: `  D:<slug> (em <arquivo>)`, no mesmo bloco das `D<n>`.
- (2) Pasta: `git ls-tree --name-only "$base" -- "$dir/"` contra a lista de HEAD; os ausentes saem em `agentic: BLOQUEADO — decisão(ões) da base ausente(s) em agentic/projeto/decisoes/ (decisão não se apaga nem se renomeia; revogue-a): <slug> <slug>`.
- (3) `### D<n>` em HEAD fora da base: `agentic: BLOQUEADO — decisão nova no registro congelado agentic/projeto/decisoes.md: D<n> … (decisão nova vai em agentic/projeto/decisoes/<slug>.md)`. Sem base, não roda (a mensagem `degradado:` atual já cobre).
- (4) Um `awk` sobre todos os `.md` do primeiro nível da pasta, sem `\r`: nome fora do slug → `<arquivo>: nome não é slug`; primeira linha não vazia sem `# ` → `<arquivo>: sem título "# "`; nenhuma linha casando a ERE de status → `<arquivo>: sem **Status:** vigente | revogada em <AAAA-MM-DD>: <motivo>`. Bloco: `agentic: BLOQUEADO — decisão fora do formato em agentic/projeto/decisoes/:` e uma linha por problema.
- Cabeçalho do script: as checagens 1 a 4 descritas como no design §4.4.

- [ ] **Step 4: Rodar e confirmar que passam**

Run: `sh mecanismos/scripts/verifica-decisoes.Tests.sh`
Expected: `… testes, 0 falhas`

- [ ] **Step 5: Medir**

Run: num repo temporário com 100 arquivos em `decisoes/` e 300 `.md` citando `D:<slug>`, `time sh mecanismos/scripts/verifica-decisoes.sh`.
Expected: abaixo de 2 s no Git Bash; anotar o número para o PR.

- [ ] **Step 6: Commit**

```bash
git add mecanismos/scripts/verifica-decisoes.sh mecanismos/scripts/verifica-decisoes.Tests.sh
git commit -m "feat(verifica-decisoes): decisões por arquivo, registro D<n> congelado"
```

### Task 2: delegação do Gate 1 pelo `auto-mode` local

**Files:**
- Modify: `mecanismos/scripts/verifica-decisoes.sh` (checagens 3 e 4 atuais viram a checagem 5)
- Modify: `bootstrap/auto-mode.padrao` (conteúdo do design §5.1, verbatim)
- Modify: `mecanismos/scripts/status-projeto.Tests.sh:36-39` (`gate1: D4` → `gate1: todas`; o código do `status-projeto.sh` não muda)
- Test: `mecanismos/scripts/verifica-decisoes.Tests.sh`

**Interfaces:**
- Consumes: Task 1 (pulo inicial só para as checagens de decisão).
- Produces: chaves do `auto-mode`: `enabled`, `gate1`, `plano`, `n3`; nome do artefato extraído do assunto `docs(<tipo>): <nome> aprovada (Gate 1 delegado[, D<n>])`.

- [ ] **Step 1: Escrever os testes que falham**

Os testes atuais de "Gate 1 delegado" (seção `vig`/`modo`/`gate`) são reescritos para o formato novo. O helper `modo` continua gravando o `auto-mode`, e `plano()` grava `agentic/projeto/planos/p.md`.

| Teste | `auto-mode` | Commits da branch | Código | `tl_contem` |
|---|---|---|---|---|
| delegação por nome passa | `enabled: true` / `gate1: x` / `plano: agentic/projeto/planos/p.md` | `docs(spec): x aprovada (Gate 1 delegado)` | 0 | — |
| `todas` passa | `gate1: todas` + plano | idem | 0 | — |
| nome fora da lista bloqueia | `gate1: y, z` + plano | idem | 1 | `x` |
| lista com espaço e CRLF | `gate1:  x , y\r` + plano | idem | 0 | — |
| modo desligado bloqueia | `enabled: false`, `gate1: x` + plano | idem | 1 | `sem delegação vigente` |
| `gate1:` vazio bloqueia o commit delegado | `enabled: true`, `gate1:` | `docs(mudanca): x aprovada (Gate 1 delegado)` | 1 | — |
| formato antigo aceito pelo nome | `gate1: x` + plano | `docs(spec): x aprovada (Gate 1 delegado, D2)` | 0 | — |
| `gate1: D2` bloqueia como formato antigo | `gate1: D2` | — | 1 | `formato antigo` |
| `plano:` ausente bloqueia | `gate1: x`, sem `plano:` | — | 1 | `plano:` |
| `plano:` inexistente bloqueia | `plano: agentic/projeto/planos/nao.md` | — | 1 | `plano:` |
| Gate 1 humano depois libera | `gate1:` vazio | delegado de `x` e depois `docs(spec): x aprovada (Gate 1)` | 0 | — |
| sem `auto-mode`: não verificável, não bloqueia | arquivo ausente | delegado de `x` | 0 | `delegação não verificável neste clone` |

- [ ] **Step 2: Rodar e confirmar que falham**

Run: `sh mecanismos/scripts/verifica-decisoes.Tests.sh`
Expected: falhas nos testes reescritos.

- [ ] **Step 3: Implementar**

- A checagem 5 roda também sem registro de decisões. O pulo da Task 1 vale só para as checagens 1 a 4; por isso, reorganize o script em duas partes ou troque o `exit 0` do pulo por uma flag.
- Leitura do `auto-mode`: primeira linha de cada chave, sem `\r` e sem espaço nas pontas. `gate1:` vira uma lista separada por vírgula, com espaço aparado em cada item.
- **Formato:**
  - `gate1:` casando `^D[0-9]+$` → `agentic: BLOQUEADO — gate1: D<n> em agentic/auto-mode é do formato antigo (a delegação não é mais uma decisão): use todas ou a lista de specs e mudanças`.
  - Item com espaço interno → `agentic: BLOQUEADO — gate1: em agentic/auto-mode precisa ser vazio, todas ou <nome>, <nome> (encontrado: …)`.
  - `gate1:` preenchido sem `plano:` de arquivo existente → `agentic: BLOQUEADO — gate1: preenchido em agentic/auto-mode exige plano: com um arquivo existente (encontrado: …)`.
- **Commits:** cada assunto de `base..HEAD` com `Gate 1 delegado` é casado por `sed -n 's/^docs(\(spec\|mudanca\)): \(.*\) aprovada (Gate 1 delegado\(, D[0-9]*\)\{0,1\})$/\2/p'`, escrito em sh portátil, com alternativa por dois `sed`, se o `\|` não for aceito. Ele é coberto quando `enabled: true` e `gate1:` é `todas` ou contém o nome. Também é coberto quando há um assunto `docs(<tipo>): <nome> aprovada (Gate 1)` na branch, como no código atual. Os não cobertos vão para `agentic: BLOQUEADO — commit registra Gate 1 delegado sem delegação vigente (agentic/auto-mode com enabled: true e gate1: cobrindo o artefato):`.
- **Sem `auto-mode` e com commits delegados:** imprime `verifica-decisoes: delegação não verificável neste clone (sem agentic/auto-mode):` e os commits, sem mudar o status.

- [ ] **Step 4: Rodar e confirmar que passam**

Run: `sh mecanismos/scripts/verifica-decisoes.Tests.sh && sh mecanismos/scripts/status-projeto.Tests.sh`
Expected: as duas suítes com `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-decisoes.sh mecanismos/scripts/verifica-decisoes.Tests.sh mecanismos/scripts/status-projeto.Tests.sh bootstrap/auto-mode.padrao
git commit -m "feat(verifica-decisoes): delegação do Gate 1 pelo auto-mode local, sem D<n>"
```

### Task 3: trailer `Assercoes-removidas` com `D:<slug>`

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh:18` (cabeçalho), `:60-63` (`ref_registrada`), `:184-189` (classificação da referência)
- Test: `mecanismos/scripts/verifica-red.Tests.sh`

**Interfaces:**
- Consumes: formato do slug e caminho da pasta (Global Constraints).

- [ ] **Step 1: Escrever os testes que falham**

Copie o teste existente de trailer com `D<n>` e troque a referência:
- "trailer com `D:<slug>` registrado antes da remoção dá crédito": o arquivo `agentic/projeto/decisoes/remove-x.md` é adicionado num commit anterior à remoção, e o trailer é `(D:remove-x)`. Esperado: o mesmo resultado do teste `D<n>` equivalente.
- "trailer com `D:<slug>` sem arquivo é ignorado": nenhum arquivo. Esperado: o mesmo bloqueio do caso `D<n>` não registrado, com a mensagem `D:remove-x não foi registrada sob agentic/projeto/ antes da remoção`.
- "`D:` com slug inválido é ignorado": `(D:Remove_X)`. Esperado: `referência não é R-n, D<n>, D:<slug> nem Emenda n`.

- [ ] **Step 2: Rodar e confirmar que falham**

Run: `sh mecanismos/scripts/verifica-red.Tests.sh`
Expected: falhas nos 3 testes novos.

- [ ] **Step 3: Implementar**

- Na classificação, `D:*` com slug válido segue adiante, sem número. Esse caso fica fora do `case "$ra_num"`. A mensagem do caso inválido passa a ser a do Step 1.
- `ref_registrada <rev> <ref>`, para `D:<slug>`: é registrada quando `git diff --name-only --diff-filter=A "$base" "$1" -- agentic/projeto/decisoes/<slug>.md` não é vazio, ou quando uma linha acrescentada sob `agentic/projeto/` contém a referência com a fronteira `([^[:alnum:]-]|$)` depois do slug.
- No cabeçalho, a linha 18 passa a listar `<R-n | D<n> | D:<slug> | Emenda n>`.

- [ ] **Step 4: Rodar e confirmar que passam**

Run: `sh mecanismos/scripts/verifica-red.Tests.sh`
Expected: `0 falhas`

- [ ] **Step 5: Commit**

```bash
git add mecanismos/scripts/verifica-red.sh mecanismos/scripts/verifica-red.Tests.sh
git commit -m "feat(verifica-red): trailer de remoção aceita D:<slug>"
```

### Task 4: instalação com `auto-mode` local e pasta de decisões

**Files:**
- Modify: `bootstrap/instalar.sh:98` e o bloco de `acrescenta` (`:162`)
- Modify: `bootstrap/checa-instancia.sh:11-12` e `:24`
- Test: `bootstrap/instalar.Tests.sh`, `bootstrap/checa-instancia.Tests.sh`

**Interfaces:**
- Consumes: `bootstrap/auto-mode.padrao`, da Task 2.
- Produces: `agentic/processo/templates/auto-mode`, versionado e do kit; `agentic/auto-mode`, local e do dev.

- [ ] **Step 1: Escrever os testes que falham**

`instalar.Tests.sh`:
- "instalação cria o template e o auto-mode local": os dois arquivos existem. O `.gitignore` tem a linha `agentic/auto-mode`. O `.kit-manifesto` lista `agentic/processo/templates/auto-mode`, mas não `agentic/auto-mode`.
- "reinstalação não toca no auto-mode do dev": depois de gravar `enabled: true` no `agentic/auto-mode`, a reinstalação o deixa igual, e `agentic/.estado/conflitos-instalacao.txt` não cita o arquivo.
- "auto-mode versionado pede ação humana": com `agentic/auto-mode` commitado antes da reinstalação, a saída contém `git rm --cached agentic/auto-mode`.
- "cria a pasta de decisões": o diretório `agentic/projeto/decisoes` existe.

`checa-instancia.Tests.sh`:
- "pasta de decisões sem decisoes.md é aceita": nenhum `PROBLEMA` sobre decisões.
- "sem pasta e sem decisoes.md é problema": a saída contém `agentic/projeto/decisoes/`.
- "auto-mode ausente é aviso": a saída contém `AVISO` e `cp agentic/processo/templates/auto-mode agentic/auto-mode`, e o caso não conta como problema.

- [ ] **Step 2: Rodar e confirmar que falham**

Run: `sh bootstrap/instalar.Tests.sh; sh bootstrap/checa-instancia.Tests.sh`
Expected: falhas nos testes novos.

- [ ] **Step 3: Implementar**

**`instalar.sh`**
- `copia "$fw/bootstrap/auto-mode.padrao" agentic/processo/templates/auto-mode`.
- Se `agentic/auto-mode` não existe, `cp` do padrão, fora do `copia`, para o arquivo não entrar no manifesto nem na lista de conflitos.
- `mkdir -p "$alvo/agentic/projeto/decisoes"`.
- `acrescenta .gitignore "agentic/auto-mode"`.
- Se `git -C "$alvo" ls-files --error-unmatch agentic/auto-mode` dá 0, imprime no fim `Ação humana: agentic/auto-mode agora é local, por dev; tire-o do git com git rm --cached agentic/auto-mode (o arquivo fica).`

**`checa-instancia.sh`**
- Tira `agentic/projeto/decisoes.md` e `agentic/auto-mode` da lista de obrigatórios.
- `PROBLEMA` quando não existem nem `agentic/projeto/decisoes/` nem `agentic/projeto/decisoes.md`.
- `AVISO: agentic/auto-mode ausente (local, por dev; modo automático desligado): cp agentic/processo/templates/auto-mode agentic/auto-mode` quando falta o arquivo.
- O grep de `{{` passa a incluir `agentic/projeto/decisoes`.

- [ ] **Step 4: Rodar e confirmar que passam**

Run: `sh bootstrap/instalar.Tests.sh && sh bootstrap/checa-instancia.Tests.sh`
Expected: as duas com `0 falhas`; os testes existentes (`instalar.Tests.sh:11,24,38`) continuam `ok`.

- [ ] **Step 5: Commit**

```bash
git add bootstrap/instalar.sh bootstrap/instalar.Tests.sh bootstrap/checa-instancia.sh bootstrap/checa-instancia.Tests.sh
git commit -m "feat(instalar): auto-mode local por dev e pasta de decisões"
```

### Task 5: processo e templates no formato novo

**Files:**
- Create: `core/templates/decisao.md` (conteúdo do design §4.1, verbatim)
- Modify: `core/templates/decisoes.md` (linha do congelamento no topo; sai o bloco comentado da delegação)
- Modify: `core/processo/ciclo.md` (linhas 20, 27, 30, 41, 42, 45, 48, 56–66, 82, 94, 129)
- Modify: `core/principios.md:15,26`, `core/processo/modelos.md:13`
- Modify: `core/templates/spec.md`, `mudanca.md`, `design.md`, `pr.md`, `brief.md`, `AGENTS.md` (cada menção a `D<n>` e a `decisoes.md`)
- Test: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: formatos fixados nas Tasks 1–3.

- [ ] **Step 1: Escrever as checagens de coerência que falham**

Em `scripts/coerencia-kit.Tests.sh`:
- Troque o texto conferido na linha 470 por `N<n> (Gate 1 delegado)`.
- Troque o da linha 503 por ``a saída é sempre do humano (`humano:`), nunca da delegação``.
- Acrescente estas checagens:

| Checagem | Forma |
|---|---|
| ciclo: decisão nova em arquivo | `tem core/processo/ciclo.md 'agentic/projeto/decisoes/<slug>.md'` |
| ciclo: referência `D:<slug>` | `tem core/processo/ciclo.md '`D:<slug>`'` |
| ciclo: auto-mode local | `tem core/processo/ciclo.md 'agentic/auto-mode` é local'` |
| template de decisão com status | `tem core/templates/decisao.md '**Status:** vigente'` |
| registro antigo congelado | `tem core/templates/decisoes.md 'congelado'` |
| sem delegação por `D<n>` | `nenhum 'gate1: D<n>\|Gate 1 delegado, D<n>\|D<n> — Delegação do Gate 1' core adapters bootstrap README.md` |
| fonte da resposta delegada | `tem core/processo/ciclo.md '`delegado N<n>`'` |

- [ ] **Step 2: Rodar e confirmar que falham**

Run: `sh scripts/coerencia-kit.Tests.sh`
Expected: falhas nas checagens novas e nas duas trocadas.

- [ ] **Step 3: Reescrever os textos**

- **Regra para cada menção:**
  - Onde o texto cria decisão, passa a criá-la em `agentic/projeto/decisoes/<slug>.md`, pelo template `decisao.md`.
  - Onde o texto cita uma decisão, ela passa a ser `D:<slug>`, e as antigas aparecem como "`D<n>`, no registro congelado".
  - Onde a delegação era `D<n>`, ela passa ao `agentic/auto-mode` local (`gate1`, `plano`, `n3`), e o commit fica `(Gate 1 delegado)`, com `gate1`, `plano` e `n3` copiados no corpo.
- **`ciclo.md`, "Gate 1 delegado":**
  - O texto diz que `agentic/auto-mode` é local, por dev, fora do git e editado só pelo humano.
  - Delegar e revogar passam a ser editar `gate1:`.
  - A resposta fora do plano fica `N<n> (Gate 1 delegado): …`, com a `Fonte:` `delegado N<n>`.
  - O "Verificado por" descreve a checagem 5 e o caso "não verificável neste clone".
- **`ciclo.md`, "Decisão que mexe em gatilho":** a regra do `AGENTS.md` continua, citando a decisão por `D:<slug>`.

- [ ] **Step 4: Conferir os dois lados**

Run: `grep -rnE 'D<n>|decisoes\.md' core` e `sh scripts/coerencia-kit.Tests.sh`
Expected:
- Cada ocorrência restante de `D<n>` diz respeito ao registro congelado.
- `coerencia-kit` com `0 falhas`.

- [ ] **Step 5: Commit**

```bash
git add core scripts/coerencia-kit.Tests.sh
git commit -m "docs(ciclo): decisões por arquivo e delegação local nos textos do processo"
```

### Task 6: papéis, comandos, bootstrap e README

**Files:**
- Modify: `core/papeis/arquiteto.md:11,24,28,32,36`, `core/papeis/dominio.md`, `core/papeis/testes.md`
- Modify: `adapters/claude-code/commands/mudanca.md:11-12`, `nova-task.md:8`, `intent.md:8`
- Modify: `bootstrap/entrevista.md:42,44,45,47,59`
- Modify: `README.md:75-85` e a árvore em `:238`
- Test: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: textos da Task 5, já integrados.

- [ ] **Step 1: Escrever as checagens de coerência que falham**

- Troque a linha 297 do `coerencia-kit` por `tem README.md 'grava `enabled: true`, `gate1:` e `plano:`'`.
- Acrescente estas checagens:
  - `tem core/papeis/arquiteto.md 'agentic/projeto/decisoes/'` (entrada e saída do papel)
  - `tem bootstrap/entrevista.md 'agentic/projeto/decisoes/<slug>.md'`
  - `tem bootstrap/entrevista.md 'cp agentic/processo/templates/auto-mode agentic/auto-mode'`
  - estender o `nenhum` da Task 5 a `adapters/claude-code/commands`

- [ ] **Step 2: Rodar e confirmar que falham**

Run: `sh scripts/coerencia-kit.Tests.sh`
Expected: falhas nas checagens novas.

- [ ] **Step 3: Reescrever os textos**

- **`arquiteto`:**
  - Lê `ls agentic/projeto/decisoes/` e só a decisão que importa, além do `decisoes.md` congelado quando ele existir.
  - Decisão nova vai em `agentic/projeto/decisoes/<slug>.md`, entra em `## Arquivos` e tem slug descritivo.
  - Cita decisão em `Fonte:` como `decisão:D:<slug>`.
- **`entrevista.md`:**
  - O item 5 grava as decisões iniciais como arquivos.
  - Os itens 7, 8 e 59 também passam a gravar em arquivo.
  - O item 9 deixa de gravar decisão de delegação: propõe ao humano `enabled: true`, `gate1:`, `plano:` e `n3:` no `agentic/auto-mode` local, como ação humana.
- **Comandos:** o registro delegado fica `(Gate 1 delegado)`.
- **README:**
  - O passo 2 da delegação passa a usar `gate1:` e `plano:`.
  - O parágrafo do `verifica-decisoes` descreve a pasta, o registro congelado e a delegação local.
  - Na árvore, `auto-mode` aparece como "local, por dev".

- [ ] **Step 4: Verificação final**

Run: `grep -rnE 'D<n>|decisoes\.md|gate1: D' core adapters bootstrap README.md` e `sh scripts/verify.sh`
Expected:
- Restam só as menções ao registro congelado.
- A saída termina em `verify: OK`.

- [ ] **Step 5: Commit**

```bash
git add core/papeis adapters bootstrap/entrevista.md README.md scripts/coerencia-kit.Tests.sh
git commit -m "docs: papéis, comandos, bootstrap e README com decisões por arquivo e delegação local"
```
