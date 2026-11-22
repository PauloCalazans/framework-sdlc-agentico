# Prova do RED por caminho — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** o `verifica-red` prova cada arquivo de teste do RED pelo executor declarado para o caminho dele, prepara só o que o RED toca, reconhece teste colocalizado, aceita as provas pela suíte já guardadas e deixa a saída em log.

**Architecture:** blocos `TESTE_<n>_*` no `agentic/config`, lidos por funções novas do `lib-agentic.sh` (classificação e escolha do executor). O `verifica-red.sh` usa essas funções na recusa de produção, na escolha do caminho de prova, no preparo, no cache e no log; o `verifica-skip.sh` usa a classificação. Uma ajuda opcional, `red-junit.sh`, traduz JUnit XML em código de saída.

**Tech Stack:** POSIX sh (também Git Bash no Windows), git; testes no `testlib.sh` do kit (`tl_repo`, `tl_espera`, `tl_contem`, `tl_fim`).

**Spec:** `docs/specs/2026-11-21-red-por-caminho-design.md`

## Global Constraints

- POSIX sh; nenhuma dependência nova nos scripts do kit (sem node, python, jq).
- A configuração nova mora no `agentic/config` (caminho protegido); nenhum arquivo de configuração novo.
- Sem as chaves `TESTE_<n>_*`, os testes existentes de `verifica-red.Tests.sh` e `verifica-skip.Tests.sh` passam **sem alteração**.
- Nada de nome de projeto em arquivo versionado; instâncias por letra. Conferir com `.nomes-proibidos` (o `coerencia-kit` faz isso).
- Toda regra nova descrita no script e na documentação (`ciclo.md`, `README.md`, `config.padrao`, `entrevista.md`) e conferida no `scripts/coerencia-kit.Tests.sh`.
- Mensagens no formato existente: `agentic: BLOQUEADO — …`, `degradado: …`, `aviso: …`, `RED <curto>: … (ok)`.
- Verificação final: `sh scripts/verify.sh` termina em `verify: OK`.

## Review Focus

1. Bloco com `TESTE_<n>_PADROES` e `TESTE_<n>_COMANDO` vazio: hoje viraria `eval ""` (código 0, "PASSAVAM"); o esperado é bloquear como configuração inválida. Teste na Task 1, parte B.
2. Numeração com buraco (`TESTE_1`, `TESTE_3`): a leitura para no 2 e o 3 sumiria em silêncio; o esperado é `aviso:` nomeando o bloco ignorado. Teste na Task 1, parte A.
3. `TESTE_<n>_RC_RED` não numérico: o esperado é bloquear como configuração inválida, não comparar texto. Teste na Task 1, parte B.
4. `{classe}` num arquivo sem linha `package`: o esperado é o nome do arquivo sem extensão. Teste na Task 1, parte B.
5. Arquivo de teste com espaço ou aspas simples no caminho, roteado por executor: o esperado é o caminho intacto em `{}`, como já acontece com `CMD_TESTE_ARQUIVO`. Teste na Task 1, parte B.

---

### Task 1: Mecanismos (partes A a E, uma rodada só)

Uma rodada de RED e GREEN para tudo: escreva os testes de **todas** as partes (Step 1 de cada uma), rode e veja falhar; depois implemente as partes na ordem A → E (cada uma usa as funções da anterior) e rode cada suíte; no fim, rode tudo e faça **um commit só** ("Fechamento da Task 1"). As partes não têm commit próprio.

#### Parte A — Classificação de arquivo de teste e leitura dos executores

**Files:**
- Modify: `mecanismos/scripts/lib-agentic.sh` (funções novas no fim)
- Modify: `mecanismos/scripts/verifica-red.sh:106` (GREEN sem RED) e `:276-283` (recusa de produção e lista do RED)
- Modify: `mecanismos/scripts/verifica-skip.sh:16-31` (varredura do marcador)
- Create: `mecanismos/scripts/lib-agentic.Tests.sh`
- Test: `mecanismos/scripts/verifica-red.Tests.sh`, `mecanismos/scripts/verifica-skip.Tests.sh` (casos acrescentados no fim, antes do `tl_fim`)

**Interfaces:**
- Produces:
  - `agentic_executores` → imprime os `n` válidos, um por linha, de 1 até o primeiro sem `TESTE_<n>_PADROES`; para cada `TESTE_<m>_PADROES` definido com `m` além do buraco, imprime em stderr `aviso: TESTE_<m>_PADROES ignorado — falta TESTE_<k>_PADROES` (k = primeiro buraco). Nunca falha.
  - `agentic_executor_campo <n> <CAMPO>` → imprime `TESTE_<n>_<CAMPO>` (`CAMPO` ∈ `PADROES PREPARO COMANDO RC_RED`); vazio se não definido. `n` não numérico → retorna 1.
  - `agentic_executor <arquivo>` → imprime o primeiro `n` cujo padrão casa (`case "$arquivo" in $padrao)`, com `set -f` ao dividir os padrões); retorna 1 se nenhum.
  - `agentic_e_teste <arquivo>` → 0 se casa prefixo de `DIRS_TESTE` ou `agentic_executor` acha bloco; senão 1. Não trata `docs/` nem `agentic/projeto/` (quem chama mantém a isenção).

- [ ] **Step 1: Testes da lib (falham)**

`lib-agentic.Tests.sh`: repo com `tl_repo`, `agentic/config` escrito por cada caso, e as funções chamadas por `sh -c "cd '$r' && . '$dir/lib-agentic.sh' && <função>"`.
```sh
# config: DIRS_TESTE="tests/"; TESTE_1_PADROES="frontend/src/*.spec.ts"; TESTE_2_PADROES="backend/a/src/test/* backend/b/src/test/*"
tl_espera 0 "e_teste: prefixo de DIRS_TESTE" … agentic_e_teste tests/x.sh
tl_espera 0 "e_teste: colocalizado casa padrão" … agentic_e_teste frontend/src/app/x/x.component.spec.ts
tl_espera 1 "e_teste: produção ao lado não casa" … agentic_e_teste frontend/src/app/x/x.component.ts
tl_espera 0 "executor: segundo padrão do bloco 2" … '[ "$(agentic_executor backend/b/src/test/T.kt)" = 2 ]'
tl_espera 1 "executor: nenhum bloco" … agentic_executor src/main.kt
tl_espera 0 "executores: 1 e 2" … '[ "$(agentic_executores | tr "\n" " ")" = "1 2 " ]'
# config com TESTE_1_PADROES e TESTE_3_PADROES:
tl_espera 0 "executores: para no buraco" … '[ "$(agentic_executores 2>/dev/null)" = 1 ]'
tl_contem "aviso: TESTE_3_PADROES ignorado — falta TESTE_2_PADROES" "executores: avisa o bloco ignorado"
tl_espera 1 "campo: n não numérico" … agentic_executor_campo x COMANDO
```

- [ ] **Step 2: Rodar e ver falhar** — `sh mecanismos/scripts/lib-agentic.Tests.sh` → falhas por função inexistente.

- [ ] **Step 3: Implementar as quatro funções no `lib-agentic.sh`**

Leitura por `eval "agentic_v=\${TESTE_${n}_${campo}:-}"` só depois de validar `n` (`case $n in ''|*[!0-9]*) return 1`) e `campo` (lista fixa). O aviso do buraco: `set | sed -n 's/^TESTE_\([0-9][0-9]*\)_PADROES=.*/\1/p'` comparado com o primeiro buraco.

- [ ] **Step 4: Rodar e ver passar** — `sh mecanismos/scripts/lib-agentic.Tests.sh` → `N testes, 0 falhas`.

- [ ] **Step 5: Testes de uso (falham)**

Em `verifica-red.Tests.sh`, com `prepara` + `config_extra "$r" 'TESTE_1_PADROES="src/*.spec.sh"'` e `TESTE_1_COMANDO="sh {}"`:
```sh
tl_espera 0 "colocalizado: RED com src/soma.spec.sh é aceito (não é produção)" …
tl_espera 1 "colocalizado: RED que também toca src/soma.sh é recusado" …
tl_contem "src/soma.sh" "colocalizado: aponta a produção"
tl_espera 0 "colocalizado: commit test: só com src/soma.spec.sh não conta como GREEN sem RED" …   # fixture de task com CA já usada nos casos de vínculo; branch só com 'test: …' tocando src/soma.spec.sh
tl_contem "nenhum commit test(red):" "colocalizado: o test: só de teste passa sem bloqueio"
```
Em `verifica-skip.Tests.sh`, `prepara` + `TESTE_1_PADROES="src/*.spec.py"`:
```sh
tl_espera 1 "colocalizado: marcador em src/x.spec.py commitado bloqueia" …
tl_espera 0 "colocalizado: marcador em src/x.py (produção) não bloqueia" …
```

- [ ] **Step 6: Rodar e ver falhar** — as duas suítes.

- [ ] **Step 7: Trocar os três laços de prefixo do `verifica-red.sh` e a varredura do `verifica-skip.sh` por `agentic_e_teste`**

No `verifica-skip.sh`: `git diff "$base" -U0 --no-color` sem pathspec, separado por arquivo (linhas `+++ b/<arquivo>`), contando só linhas `+` de arquivos com `agentic_e_teste`; os não rastreados idem. A checagem "DIRS_TESTE vazio" passa a exigir `DIRS_TESTE` **ou** pelo menos um executor.

- [ ] **Step 8: Rodar e ver passar** — `sh mecanismos/scripts/verifica-red.Tests.sh` e `sh mecanismos/scripts/verifica-skip.Tests.sh` → `0 falhas`, inclusive os casos antigos sem mudança.


#### Parte B — Prova pelo executor, preparo por executor e contrato do código

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh` (`comando_arquivo`, `avalia_rc`, montagem de `$pend` e o laço de execução, `:229-336`)
- Test: `mecanismos/scripts/verifica-red.Tests.sh`

**Interfaces:**
- Consumes: `agentic_executores`, `agentic_executor`, `agentic_executor_campo` (parte A).
- Produces:
  - `$pend` passa a ter linhas `<n>\t<arquivo>` (executor), `a\t<arquivo>` (`CMD_TESTE_ARQUIVO`) ou `s\t*suite*` (no máximo uma por RED).
  - `comando_arquivo <modelo> <arquivo>` → modelo com `{}` trocado pelo caminho e `{classe}` pela classe, ambos entre aspas simples. A classe vem de `classe_jvm <arquivo>` (lida no worktree do RED): `package` + nome sem extensão, ou só o nome.
  - `avalia_rc <rc> <rotulo> <comando> <chave> [rc_red]`: com `rc_red` preenchido, só `rc = rc_red` é RED; outro código diferente de 0 → `agentic: BLOQUEADO — <rotulo> não é evidência no RED <curto> (código <rc>, esperado <rc_red>)`.

- [ ] **Step 1: Testes (falham)** — fixture `prepara_exec`: `prepara_multi` + dois executores que registram a chamada num contador:
```sh
# TESTE_1_PADROES="tests/a_*.sh"  TESTE_1_COMANDO="echo 1 >> '$cont'; sh {}"   TESTE_1_PREPARO="echo p1 >> '$cont'"
# TESTE_2_PADROES="tests/b_*.sh"  TESTE_2_COMANDO="echo 2 >> '$cont'; sh {}"   TESTE_2_PREPARO="echo p2 >> '$cont'"
tl_espera 0 "executor: cada arquivo pelo seu executor" …                # RED com tests/a_soma.sh e tests/b_soma.sh
tl_espera 0 "executor: contador tem 1 e 2, p1 e p2 uma vez cada" …
tl_espera 0 "executor: preparo só do executor tocado (sem p2)" …        # RED só com tests/a_soma.sh
tl_espera 1 "executor: arquivo do executor 2 que já passava bloqueia" …
tl_contem "tests/b_soma.sh" "executor: aponta o arquivo que passava"
tl_espera 0 "fallback: arquivo sem executor e sem CMD_TESTE_ARQUIVO cai na suíte" …
tl_contem "degradado: tests/t_soma.sh sem executor — RED provado pela suíte inteira" "fallback: avisa por arquivo"
tl_espera 0 "fallback: dois arquivos sem executor rodam a suíte uma vez só" …
tl_espera 0 "fallback: CMD_TESTE_ARQUIVO preenchido atende o arquivo sem executor" …
tl_espera 0 "fallback: CMD_PREPARAR_TESTE só roda com prova por CMD_TESTE_ARQUIVO ou suíte" …
tl_espera 0 "rc_red: código igual ao RC_RED é RED" …                    # COMANDO="sh {}; exit 10" com falha → script sai 10; RC_RED="10"
tl_espera 1 "rc_red: outro código não é evidência" …                    # mesmo comando, RC_RED="7"
tl_contem "não é evidência" "rc_red: explica"
tl_espera 1 "config: COMANDO vazio bloqueia" … ; tl_contem "TESTE_1_COMANDO vazio" "config: aponta a chave"
tl_espera 1 "config: RC_RED não numérico bloqueia" … ; tl_contem "TESTE_1_RC_RED" "config: aponta a chave"
tl_espera 0 "classe: {classe} com package vira pacote.Nome" …            # tests/a_T.kt com 'package com.x', COMANDO grava {classe} no contador; conferir 'com.x.a_T'
tl_espera 0 "classe: sem package vira só o nome" …
tl_espera 0 "executor: caminho com espaço e aspas simples intacto em {}" …
```

- [ ] **Step 2: Rodar e ver falhar** — `sh mecanismos/scripts/verifica-red.Tests.sh`.

- [ ] **Step 3: Implementar**

Antes do laço dos REDs: para cada `n` de `agentic_executores`, `COMANDO` vazio → `agentic_falha "TESTE_<n>_COMANDO vazio em agentic/config"`; `RC_RED` não vazio e não numérico → `agentic_falha "TESTE_<n>_RC_RED não numérico em agentic/config: <valor>"`. A regra "RED sem arquivo de teste com asserção bloqueia" passa a valer quando há executor **ou** `CMD_TESTE_ARQUIVO`. O aviso `degradado: CMD_TESTE_ARQUIVO não configurado` só aparece quando não há executor nem `CMD_TESTE_ARQUIVO`. No worktree: preparos distintos dos executores de `$pend` (ordem de `n`), mais `CMD_PREPARAR_TESTE` se `$pend` tem `a` ou `s`; falha de qualquer preparo bloqueia com `agentic: BLOQUEADO — preparo <TESTE_<n>_PREPARO|CMD_PREPARAR_TESTE> falhou no RED <curto>; não há evidência.`

- [ ] **Step 4: Rodar e ver passar** — `sh mecanismos/scripts/verifica-red.Tests.sh` → `0 falhas`.


#### Parte C — Assinatura por executor, migração das provas e prova do completo

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh` (`assinatura`, `red_provado`, `guarda_prova`, `:195-227`)
- Modify: `mecanismos/scripts/verify.sh:122-124` (`p_sig`)
- Test: `mecanismos/scripts/verifica-red.Tests.sh`, `mecanismos/scripts/verify.Tests.sh`

**Interfaces:**
- Consumes: `agentic_executor_campo`, formato de `$pend` (parte B).
- Produces:
  - `assinatura_de <tipo>`: `tipo` = `<n>` → hash de `PADROES\nPREPARO\nCOMANDO\nRC_RED` do bloco; `a` ou `s` → a assinatura de hoje (`CMD_PREPARAR_TESTE`, `CMD_TESTE_ARQUIVO`, `CMD_TESTE`).
  - `red_provado <sha> <arquivo> <assinatura>`; `guarda_prova <sha> <arquivo> <assinatura>`. Formato da linha do cache inalterado.
  - `red_provado_suite <sha>`: 0 se há linha `<sha> <qualquer> *suite*`; com `AGENTIC_RED_SEM_CACHE=1`, retorna 1.

- [ ] **Step 1: Testes (falham)**
```sh
tl_espera 0 "migração: prova *suite* de assinatura antiga vale depois de ligar executores" …
#   RED provado no degradado (CMD_TESTE contando); depois config_extra com TESTE_1_* e outro CMD_TESTE; contador não sobe
tl_contem "provado antes pela suíte (assinatura anterior) (ok)" "migração: diz de onde veio a prova"
tl_espera 0 "migração: AGENTIC_RED_SEM_CACHE=1 refaz pelo executor" …    # contador do executor sobe
tl_espera 0 "assinatura: mudar o executor 2 não refaz a prova do executor 1" …
tl_espera 0 "assinatura: mudar o executor 1 refaz a prova dele" …
```
Em `verify.Tests.sh`, junto dos casos da prova do completo:
```sh
tl_espera 0 "prova do completo: mudar TESTE_1_COMANDO roda tudo de novo" …   # não aparece "já provado nesta árvore"
```

- [ ] **Step 2: Rodar e ver falhar** — as duas suítes.

- [ ] **Step 3: Implementar**

Ordem da consulta por arquivo: prova com a assinatura do tipo atual → `RED <curto>: já provado (<arquivo>) (ok)`; senão, se o RED tem prova `*suite*` de qualquer assinatura → `RED <curto>: provado antes pela suíte (assinatura anterior) (ok)` e o RED inteiro é dado por provado. No `verify.sh`, acrescentar ao `p_sig` a saída de `for n in $(agentic_executores 2>/dev/null); do` com os quatro campos de cada bloco.

- [ ] **Step 4: Rodar e ver passar** — as duas suítes → `0 falhas`; os casos antigos de cache (`cache: assinatura nova prova de novo`, em modo `CMD_TESTE_ARQUIVO`) seguem verdes.


#### Parte D — Log do verifica-red

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh` (execuções do preparo e dos testes, hoje `>/dev/null 2>&1`)
- Modify: `mecanismos/scripts/verifica-escopo.sh:39` (ignorar o log)
- Test: `mecanismos/scripts/verifica-red.Tests.sh`, `mecanismos/scripts/verifica-escopo.Tests.sh`

**Interfaces:**
- Produces: `agentic/.estado/verifica-red.log`, reescrito a cada execução do script; uma seção por execução: `== RED <curto> <arquivo|*suite*|preparo> (<executor n|CMD_TESTE_ARQUIVO|CMD_TESTE|CMD_PREPARAR_TESTE>)`, a saída, e `-- <rc> em <s> s`.

- [ ] **Step 1: Testes (falham)**
```sh
tl_espera 0 "log: escrito com a seção do arquivo" grep -qF "== RED " "$r/agentic/.estado/verifica-red.log"
tl_espera 0 "log: guarda a saída do teste" grep -qF "esperado 5, obtido 0" "$r/agentic/.estado/verifica-red.log"
tl_espera 1 "log: RED que passava bloqueia e repete o trecho" …
tl_contem "últimas 40 linhas" "log: anuncia o trecho repetido"
tl_espera 0 "log: reescrito na execução seguinte (uma seção só)" …
```
Em `verifica-escopo.Tests.sh`: `verifica-red.log` presente não conta como fora do escopo.

- [ ] **Step 2: Rodar e ver falhar.**

- [ ] **Step 3: Implementar** — `mkdir -p agentic/.estado`; cada execução escreve num temporário, anexado ao log com cabeçalho e rodapé; em bloqueio daquela execução, `echo "== (falhou; últimas 40 linhas)"` + `tail -n 40` do temporário. `</dev/null` mantido. Duração por `date +%s` antes e depois.

- [ ] **Step 4: Rodar e ver passar** — `verifica-red.Tests.sh` e `verifica-escopo.Tests.sh` → `0 falhas`.


#### Parte E — Ajuda `red-junit.sh`

**Files:**
- Create: `mecanismos/scripts/red-junit.sh`
- Create: `mecanismos/scripts/red-junit.Tests.sh`

**Interfaces:**
- Produces: `sh agentic/mecanismos/scripts/red-junit.sh '<glob dos XML>' -- <comando…>` → roda o comando (o código dele é ignorado), expande o glob depois e sai `1` (≥1 `<testcase` e ≥1 `<failure`), `0` (≥1 `<testcase` e nenhum `<failure` nem `<error`), `126` (sem XML, zero `<testcase`, ou `<error` sem `<failure`). Sem `--` ou sem comando: `126` com mensagem de uso em stderr. Imprime em stdout `red-junit: casos <c> failure <f> error <e> -> <rc>`.

- [ ] **Step 1: Testes (falham)** — o comando de cada caso grava um XML fixo em `r/out/`:
```sh
tl_espera 1 "junit: failure é RED"            sh red-junit.sh "$r/out/*.xml" -- sh -c "<grava testcase+failure>"
tl_espera 0 "junit: casos sem falha passam"   …
tl_espera 126 "junit: sem XML não é evidência" …
tl_espera 126 "junit: zero casos não é evidência" …
tl_espera 126 "junit: só error (compilação/coleta) não é evidência" …
tl_espera 1 "junit: failure e error juntos é RED" …
tl_espera 126 "junit: sem -- é uso inválido" …
tl_contem "red-junit: casos 1 failure 1 error 0 -> 1" "junit: resumo na saída"   # após o 1º caso
```
- [ ] **Step 2: Rodar e ver falhar** — `sh mecanismos/scripts/red-junit.Tests.sh`.
- [ ] **Step 3: Implementar** — contagem com `grep -o '<testcase' | wc -l` (e `<failure`, `<error`) somada pelos arquivos, como o `verifica-skip.sh` já faz com `<skipped`.
- [ ] **Step 4: Rodar e ver passar.**

#### Fechamento da Task 1

- [ ] **Rodar tudo** — `sh scripts/verify.sh` → `verify: OK` (inclui os testes antigos de `verifica-red`, `verifica-skip`, `verifica-escopo` e `verify` sem alteração).
- [ ] **Commit único**
```bash
git add mecanismos/scripts/
git commit -m "feat(verifica-red): prova do RED pelo executor do caminho

Executores TESTE_<n>_* no agentic/config (padrões, preparo, comando, RC_RED),
classificação única de arquivo de teste (teste colocalizado), preparo só dos
executores tocados, assinatura por executor, prova pela suíte já guardada
aceita na migração, log em agentic/.estado/verifica-red.log e a ajuda
red-junit.sh."
```

### Task 2: Documentação, instalação e coerência

**Files:**
- Modify: `mecanismos/scripts/verifica-red.sh:1-26` (comentário de topo: caminho de prova, migração, log)
- Modify: `bootstrap/config.padrao` (bloco comentado depois de `CMD_TESTE_ARQUIVO`: um executor de arquivo e um por módulo, com `{}`, `{classe}`, `RC_RED` e `red-junit.sh`)
- Modify: `bootstrap/entrevista.md:22` (pergunta por executor quando há mais de um)
- Modify: `core/processo/ciclo.md:95` ("Verificação": caminho de prova por arquivo, migração, `verifica-red.log`)
- Modify: `README.md` (linha do `verifica-red` na tabela de mecanismos e a seção de configuração, se houver)
- Modify: `scripts/coerencia-kit.Tests.sh`
- Test: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consumes: nomes das chaves e mensagens da Task 1, exatamente como lá.

- [ ] **Step 1: Checagens de coerência (falham)** — no estilo `tem <arquivo> '<texto>'`:
```sh
tl_espera 0 "config.padrao: documenta TESTE_<n>_PADROES"   tem bootstrap/config.padrao 'TESTE_1_PADROES'
tl_espera 0 "config.padrao: cita red-junit.sh"             tem bootstrap/config.padrao 'red-junit.sh'
tl_espera 0 "ciclo: prova por executor do caminho"         tem core/processo/ciclo.md 'TESTE_<n>_'
tl_espera 0 "ciclo: log do verifica-red"                   tem core/processo/ciclo.md 'verifica-red.log'
tl_espera 0 "ciclo: migração das provas pela suíte"        tem core/processo/ciclo.md 'provado antes pela suíte'
tl_espera 0 "lib: os quatro campos documentados existem"   tem mecanismos/scripts/lib-agentic.sh 'PADROES PREPARO COMANDO RC_RED'
tl_espera 0 "entrevista: pergunta por executor"            tem bootstrap/entrevista.md 'TESTE_<n>_'
```
- [ ] **Step 2: Rodar e ver falhar** — `sh scripts/coerencia-kit.Tests.sh`.
- [ ] **Step 3: Escrever os textos** (o `ciclo.md` com as frases exatas das checagens; nenhum nome de projeto).
- [ ] **Step 4: Rodar tudo** — `sh scripts/verify.sh` → `verify: OK`.
- [ ] **Step 5: Commit**
```bash
git add mecanismos/scripts/verifica-red.sh bootstrap/config.padrao bootstrap/entrevista.md core/processo/ciclo.md README.md scripts/coerencia-kit.Tests.sh
git commit -m "docs(verifica-red): executores por caminho, migração e log no ciclo, na instalação e no README"
```
