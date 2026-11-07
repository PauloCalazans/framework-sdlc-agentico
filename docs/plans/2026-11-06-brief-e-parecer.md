# Brief e parecer estruturados — Plano de implementação

> **Para agentes executores:** sub-skill obrigatória: `superpowers:subagent-driven-development` (recomendada) ou `superpowers:executing-plans`. Os passos usam checkbox (`- [ ]`).

**Objetivo:** levar ao kit o template de brief, o template de parecer, a seção "No brief" dos contratos e o revisor que escreve só o parecer, deixando o kit inteiro coerente com isso.

**Arquitetura:** quase tudo é texto (`core/`, `adapters/`, `README.md`, `docs/`). Uma suíte nova, `scripts/coerencia-kit.Tests.sh`, transforma cada exigência do design numa asserção que o `scripts/verify.sh` roda. Cada task acrescenta primeiro as suas asserções (falham), depois edita o texto (passam). Testes de mecanismo existentes (`instalar.Tests.sh`, `status-projeto.Tests.sh`) ganham os casos que o design pede.

**Stack:** POSIX `sh`, `grep`, `tr`, a `testlib.sh` do kit. Markdown em português.

**Spec:** `docs/specs/2026-11-06-brief-e-parecer-design.md`. Leia-o inteiro antes da primeira task; as seções citadas abaixo (5.1 a 5.8) são dele.

## Restrições globais

- Branch: `brief-e-parecer` (já criada; o commit do design é `4b67c1f`). Nunca commitar na `main`, nunca fazer merge.
- Não adicionar `docs/avaliacao-normativa-swebok-iso.md` (não rastreado, fora deste trabalho). Use `git add <caminhos>`, nunca `git add -A`.
- Nenhum arquivo do kit, mensagem de commit ou PR cita o projeto de referência, os nomes dos papéis dele (Forja, Lupa, Esquadro), `mocktail`, `worker_done`, Orca, Maestri, `Select-Object`, Maven ou `flutter`. Fale em "projeto de referência".
- Escala do revisor: Crítico / Importante / Menor; vereditos `APROVADO` / `DEVOLVIDO`. Nunca `REPROVADO`, Bloqueante ou Maior.
- Placeholders em templates e contratos usam `<...>`, nunca `{{...}}` (o `checa-instancia.sh` acusa `{{` em `agentic/processo/papeis/`).
- Nomes de arquivo na pasta de execução: `NN-<papel>[-<modo>]-brief.md`, `NN-<papel>[-<modo>]-relatorio.md`, `NN-revisor-<modo>-parecer.md`.
- Linha de retorno: `NN-<papel>: <STATUS> | <campos do papel> | <arquivo de relatório>`; no revisor, `NN-revisor-<modo>: APROVADO|DEVOLVIDO | C n I n M n | <arquivo do parecer>`.
- Toda asserção de texto ignora `\r`: neste clone (`core.autocrlf=true`) os `.md` têm CRLF.
- Toda mensagem de commit termina com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Verificação completa do kit: `sh scripts/verify.sh`; sucesso só com `verify: OK` na última linha.

## Foco da revisão

1. **CRLF no Windows:** asserção com `^`/`$` que não tira o `\r` passa no Linux e falha aqui (ou o contrário). Toda asserção da suíte nova passa pelos helpers que fazem `tr -d '\r'` (Task 1). A Task 0 corrige o único teste existente com esse defeito.
2. **Reinstalação sobre instância existente:** `brief.md` e `parecer.md` são arquivos novos e precisam chegar à instância; o `instalar.Tests.sh` confere (Tasks 1 e 2).
3. **Parecer copiado para `pareceres/` aparecendo no `status-projeto`:** o template do parecer não tem linha `**Status:**`; a Task 2 fixa isso com teste.
4. **Revisor com escrita escrevendo no worktree:** não há mecanismo; a lista "Ao receber" do template exige `git status --porcelain` vazio no worktree revisado (Task 1). A Task 4 confere que o adaptador do Claude Code segue sem `Edit`.
5. **Deriva de texto entre arquivos:** "sem ferramenta de escrita", "`task-N-brief`" ou nome de stack sobrando em algum canto do kit. As asserções `nenhum` das Tasks 1, 4 e 5 varrem `core/`, `adapters/`, `bootstrap/`, `mecanismos/`, `README.md` e `docs/portabilidade.md`.

---

### Task 0: Teste do manifesto tolera CRLF (defeito existente)

A linha de base já falha neste clone: `bootstrap/instalar.Tests.sh:103` compara `sha256sum` do arquivo instalado (com CRLF) com o hash do manifesto, que o `kit_hash` calcula sem `\r`. O instalador está certo; o teste não.

**Arquivos:**
- Modificar: `bootstrap/instalar.Tests.sh:103`

- [ ] **Passo 1: Confirmar a falha**

Run: `sh bootstrap/instalar.Tests.sh 2>&1 | grep FALHA`
Expected: `FALHA hash do manifesto confere com o arquivo instalado (esperado 0, obtido 1)`

- [ ] **Passo 2: Trocar a asserção** para comparar o hash do manifesto com `kit_hash` do arquivo instalado (função de `bootstrap/lib-kit.sh`, já usada no teste "hash ignora CRLF"): o hash da linha `agentic/processo/ciclo.md` do manifesto é igual a `kit_hash "$r/agentic/processo/ciclo.md"`. Mesma descrição do teste.

- [ ] **Passo 3: Rodar**

Run: `sh bootstrap/instalar.Tests.sh 2>&1 | tail -1`
Expected: `<n> testes, 0 falhas`

- [ ] **Passo 4: Commit**

```bash
git add bootstrap/instalar.Tests.sh
git commit -m "test(bootstrap): hash do manifesto confere ignorando CRLF, como o kit_hash"
```

---

### Task 1: Template de brief e suíte de coerência

Design 5.1, e a exceção do `verify` do revisor (5.3).

**Arquivos:**
- Criar: `scripts/coerencia-kit.Tests.sh`
- Criar: `core/templates/brief.md`
- Modificar: `bootstrap/instalar.Tests.sh` (lista de arquivos copiados, linhas 8-12)

**Interfaces:**
- Produz, em `scripts/coerencia-kit.Tests.sh`, os helpers que as Tasks 2 a 6 usam:
  - `tem <arquivo relativo à raiz> <texto fixo>` — 0 se o arquivo, sem `\r`, contém o texto;
  - `linha <arquivo> <ERE>` — 0 se alguma linha, sem `\r`, casa a ERE;
  - `nenhum <ERE> <caminhos...>` — 0 se nenhum arquivo dos caminhos casa a ERE (`grep -rniE`); imprime as ocorrências quando falha;
  - `ordem <arquivo> <texto A> <texto B>` — 0 se a primeira linha com A vem antes da primeira com B.
- Cada task acrescenta um bloco `# --- Task N: <assunto>` antes do `tl_fim` final.

- [ ] **Passo 1: Criar a suíte com os helpers e as asserções do brief**

Cabeçalho: `. "$raiz/mecanismos/scripts/testlib.sh"`, `raiz` = pai de `scripts/`. Asserções (todas `tl_espera 0`, salvo indicação):

```sh
b=core/templates/brief.md
for l in '^Papel: ' '^Contrato: ' '^Perfil: ' '^Task: '; do
  tl_espera 0 "brief: cabeçalho tem a linha $l" linha $b "$l"
done
for s in '## Escopo' '## O que fazer' '## Já decidido' '## Nunca faz' '## Leia só isto' \
         '## Comandos' '## Teto' '## Entrega' '## Desde a rodada anterior' '## Assinaturas' '## API externa'; do
  tl_espera 0 "brief: seção $s" tem $b "$s"
done
tl_espera 0 "brief: obrigatórias antes das condicionais" ordem $b '## Entrega' '## Desde a rodada anterior'
tl_espera 0 "brief: lista Antes de enviar" tem $b 'Antes de enviar'
tl_espera 0 "brief: lista Ao receber" tem $b 'Ao receber'
tl_espera 0 "brief: nome de arquivo por ordem de despacho" tem $b 'NN-<papel>'
tl_espera 0 "brief: correção copia o brief anterior inteiro" tem $b 'brief anterior'
tl_espera 0 "brief: o verify do revisor nunca sai do revisor" linha $b 'nunca tira do .?revisor.? o .?verify'
tl_espera 0 "brief: ao receber confere o worktree do revisor limpo" tem $b 'git status --porcelain'
tl_espera 1 "brief: sem placeholder {{" tem $b '{{'
tl_espera 0 "kit sem nome do projeto de referência nem de ferramenta de orquestração" nenhum \
  'avitech|forja|lupa|esquadro|mocktail|worker_done|maestri|\borca\b' \
  core adapters bootstrap mecanismos README.md docs/portabilidade.md
tl_espera 0 "core/ sem comando de stack" nenhum 'select-object|maven|\bmvn\b|flutter' core
tl_fim
```

- [ ] **Passo 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -3`
Expected: falhas nas asserções de `core/templates/brief.md` (arquivo ausente); as duas varreduras `nenhum` já passam (conferido em 2026-11-06; se não passarem, pare e reporte: é deriva anterior a este trabalho). Exemplo de stack em `bootstrap/config.padrao` (Maven) é legítimo e fica fora da varredura de `core/`.

- [ ] **Passo 3: Escrever `core/templates/brief.md`**

Conteúdo pela seção 5.1 do design: comentário de preenchimento no topo (meta ~40 linhas; seção obrigatória presente, `nenhum` quando vazia; rodada de correção = copiar o brief anterior inteiro, reescrever "O que fazer", acrescentar "Desde a rodada anterior"; nunca "mesmo contrato", "mesmo escopo" ou "continuação"); o bloco de quatro linhas do cabeçalho; as oito seções obrigatórias e as três condicionais, com uma linha-guia `<...>` cada (a de `## Comandos` com a exceção do `verify` do revisor); nome dos arquivos e formato da linha de retorno; as listas "Antes de enviar" e "Ao receber" como estão no design. Neutro de stack: comandos citados como `sh agentic/mecanismos/scripts/verify.sh` e "o comando de teste por arquivo do `AGENTS.md`".

- [ ] **Passo 4: Instalador leva o template**

Em `bootstrap/instalar.Tests.sh`, acrescentar `agentic/processo/templates/brief.md` à lista do laço `copiou $f` (linha 9). Nenhuma mudança no `instalar.sh`: ele já copia `core/templates/` inteiro.

- [ ] **Passo 5: Rodar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -1 && sh bootstrap/instalar.Tests.sh 2>&1 | tail -1`
Expected: `<n> testes, 0 falhas` nas duas.

- [ ] **Passo 6: Commit**

```bash
git add scripts/coerencia-kit.Tests.sh core/templates/brief.md bootstrap/instalar.Tests.sh
git commit -m "feat(templates): template de brief de papel, com suíte de coerência do kit"
```

---

### Task 2: Template de parecer

Design 5.3 (template e escala) e 5.4 (parecer local; nada de `**Status:**`).

**Arquivos:**
- Criar: `core/templates/parecer.md`
- Modificar: `scripts/coerencia-kit.Tests.sh`, `bootstrap/instalar.Tests.sh`, `mecanismos/scripts/status-projeto.Tests.sh`

**Interfaces:**
- Consome: helpers da Task 1.

- [ ] **Passo 1: Asserções**

Em `coerencia-kit.Tests.sh`:

```sh
p=core/templates/parecer.md
for s in '## Rodada anterior' '## Critérios de aceite' '## Achados' '## Verificação'; do
  tl_espera 0 "parecer: seção $s" tem $p "$s"
done
tl_espera 0 "parecer: ordem das seções" ordem $p '## Rodada anterior' '## Verificação'
for t in Crítico Importante Menor APROVADO DEVOLVIDO 'C n I n M n' medido inferido 'não se aplica'; do
  tl_espera 0 "parecer: contém $t" tem $p "$t"
done
tl_espera 1 "parecer: sem linha **Status:** (status-projeto não o lista)" linha $p '^\*\*Status:\*\*'
tl_espera 0 "kit sem escala alheia" nenhum 'REPROVADO|bloqueante' core adapters README.md
```

Em `instalar.Tests.sh`: `agentic/processo/templates/parecer.md` na lista `copiou $f`.

Em `status-projeto.Tests.sh`, depois do caso "ignora arquivos _modelo" (linha 22), um parecer copiado com o cabeçalho do template não é listado:

```sh
mkdir -p "$r/agentic/projeto/specs/pedidos/pareceres"
printf '# Parecer — diff — pedidos/001 — rodada 2\n**Veredito:** APROVADO · C 0 I 0 M 1\n' \
  > "$r/agentic/projeto/specs/pedidos/pareceres/001-diff.md"
tl_espera 0 "status com parecer copiado sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_espera 1 "não lista parecer copiado para pareceres/" grep -q "pareceres/" "$TL_SAIDA"
```

- [ ] **Passo 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep -c FALHA`
Expected: ≥ 1 (parecer ausente). O caso de `status-projeto` passa já de cara: é caracterização (o `status-projeto.sh` só lista arquivo com `**Status:**`) e fica para o template não quebrar isso.

- [ ] **Passo 3: Escrever `core/templates/parecer.md`** pela seção 5.3: cabeçalho (modo, task ou artefato, intervalo de SHAs no `diff`, rodada, `**Veredito:** APROVADO | DEVOLVIDO · C n I n M n`), as quatro seções na ordem, tabela achado anterior → `corrigido` / `não corrigido` / `parcial` com `arquivo:linha` do HEAD, tabela CA ↔ teste ↔ status só no `diff` (`não se aplica` nos outros modos), achados com ID, classe, `arquivo:linha`, problema e evidência `medido`/`inferido`, verificação com comando e últimas linhas. Comentário de topo: o parecer fica em `agentic/.estado/execucao/…/NN-revisor-<modo>-parecer.md`; sem plataforma de PR, o final aprovado é copiado para `agentic/projeto/specs/<nome>/pareceres/`.

- [ ] **Passo 4: Rodar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -1; sh bootstrap/instalar.Tests.sh 2>&1 | tail -1; sh mecanismos/scripts/status-projeto.Tests.sh 2>&1 | tail -1`
Expected: `0 falhas` nas três.

- [ ] **Passo 5: Commit**

```bash
git add core/templates/parecer.md scripts/coerencia-kit.Tests.sh bootstrap/instalar.Tests.sh mecanismos/scripts/status-projeto.Tests.sh
git commit -m "feat(templates): template de parecer do revisor na escala do kit"
```

---

### Task 3: Seção "No brief" e "Ao terminar" nos contratos; perfil em forma de ação

Design 5.2 e 5.7.

**Arquivos:**
- Modificar: `core/papeis/dominio.md`, `arquiteto.md`, `testes.md`, `dev.md`, `revisor.md`, `core/templates/perfil-papel.md`, `scripts/coerencia-kit.Tests.sh`

- [ ] **Passo 1: Asserções**

```sh
for papel in dominio arquiteto testes dev revisor; do
  c=core/papeis/$papel.md
  tl_espera 0 "$papel: tem ## No brief" tem $c '## No brief'
  tl_espera 0 "$papel: No brief antes de Ao terminar" ordem $c '## No brief' '## Ao terminar'
  tl_espera 0 "$papel: No brief com 3 a 5 itens" sh -c \
    "n=\$(tr -d '\r' < '$raiz/$c' | sed -n '/^## No brief/,/^## /p' | grep -c '^- '); [ \$n -ge 3 ] && [ \$n -le 5 ]"
  tl_espera 0 "$papel: Ao terminar grava relatório e devolve a linha" tem $c 'linha de retorno'
  tl_espera 1 "$papel: sem placeholder {{ no contrato" sh -c "grep -q '{{' '$raiz/$c'"
done
for papel in dominio arquiteto testes dev; do
  tl_espera 0 "$papel: No brief depois de Independência" ordem core/papeis/$papel.md '## Independência' '## No brief'
done
tl_espera 0 "revisor: No brief depois de Nunca faz" ordem core/papeis/revisor.md '## Nunca faz' '## No brief'
tl_espera 0 "revisor: verify em primeiro plano no No brief" tem core/papeis/revisor.md 'em primeiro plano'
tl_espera 1 "oráculo não ganha No brief" tem core/papeis/_oraculo.md '## No brief'
tl_espera 0 "perfil: Padrões e Nunca faz em forma de ação" tem core/templates/perfil-papel.md 'forma de ação'
```

- [ ] **Passo 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep -c FALHA`
Expected: ≥ 20.

- [ ] **Passo 3: Escrever as seções.** Texto de cada `## No brief` exatamente como as listas da seção 5.2 do design (uma linha `- ` por cláusula; o revisor com "rode a verificação você mesmo, em primeiro plano, antes de aprovar"). Abrir a seção com uma frase: "O orquestrador cola no brief as linhas que valem para a rodada." Nenhuma cláusula nova: cada linha reescreve uma regra que o próprio contrato já tem; se não achar a regra-fonte no contrato, pare e reporte. "Ao terminar" de cada contrato: a frase atual "Entregue: …" passa a "Grave no arquivo de relatório que o brief indica: …" e termina com "e devolva a linha de retorno do brief". No `revisor.md`, só a seção nova e o "Ao terminar" mudam aqui (o "Nunca faz" é da Task 4). No `perfil-papel.md`, uma linha no comentário de preenchimento: itens de "Padrões" e "Nunca faz neste projeto" em forma de ação, porque o orquestrador os cola no brief.

- [ ] **Passo 4: Rodar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -1; sh bootstrap/instalar.Tests.sh 2>&1 | tail -1; sh bootstrap/checa-instancia.Tests.sh 2>&1 | tail -1`
Expected: `0 falhas` nas três (os testes do instalador conferem que cada contrato ainda manda ler o perfil).

- [ ] **Passo 5: Commit**

```bash
git add core/papeis/dominio.md core/papeis/arquiteto.md core/papeis/testes.md core/papeis/dev.md core/papeis/revisor.md core/templates/perfil-papel.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(papeis): seção No brief e relatório em arquivo em todo contrato"
```

---

### Task 4: Revisor escreve só o parecer, no kit inteiro

Design 5.3 ("Nunca faz"), 5.6 e as linhas do revisor na tabela da 5.8.

**Arquivos:**
- Modificar: `core/papeis/revisor.md` ("Nunca faz", linha 26), `core/processo/modelos.md:41`, `README.md:27` e `README.md:58`, `adapters/claude-code/agents/revisor.md`, `adapters/copilot/agents/revisor.agent.md`, `bootstrap/instalar.Tests.sh:136`, `scripts/coerencia-kit.Tests.sh`

- [ ] **Passo 1: Asserções**

Em `coerencia-kit.Tests.sh`:

```sh
k='core adapters bootstrap mecanismos README.md docs/portabilidade.md'
tl_espera 0 "kit não descreve o revisor como sem escrita" nenhum \
  'sem ferramenta de escrita|não tem write/edit|omite write/edit|omite `edit`|negue escrita|editar arquivos\.|edita arquivo ou revisa' $k
tl_espera 0 "revisor: escreve só o parecer" tem core/papeis/revisor.md 'só o parecer'
tl_espera 0 "revisor: parecer fora do worktree" tem core/papeis/revisor.md 'fora do worktree'
tl_espera 0 "revisor: continua rodando o verify ele mesmo" tem core/papeis/revisor.md 'Rode o `verify.sh` você mesmo'
tl_espera 0 "adapter Claude Code: revisor com Write" linha adapters/claude-code/agents/revisor.md '^tools: .*\bWrite\b'
tl_espera 1 "adapter Claude Code: revisor sem Edit" linha adapters/claude-code/agents/revisor.md '^tools: .*\bEdit\b'
tl_espera 0 "adapter Copilot: revisor com edit" linha adapters/copilot/agents/revisor.agent.md "^tools: .*'edit'"
```

Em `instalar.Tests.sh:136`: o caso vira `tl_espera 0 "--copilot: revisor com a ferramenta edit (só o parecer)" grep -qF "'edit'" …`. Acrescentar, perto da linha 12, sobre a instalação padrão: `.claude/agents/revisor.md` tem `Write` e não tem `Edit` na linha `tools:` (dois `tl_espera`).

- [ ] **Passo 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep FALHA`
Expected: falham "sem escrita" (lista as ocorrências em `revisor.md`, `modelos.md`, `README.md` e nos dois adaptadores), "só o parecer", "fora do worktree", "com Write" e "com edit".

- [ ] **Passo 3: Editar o texto**, pela tabela da seção 5.8:
  - `revisor.md`, "Nunca faz": "Escrever qualquer arquivo além do parecer, no caminho que o brief dá, fora do worktree que você revisa. Redução, não garantia. **Verificado por:** `git status --porcelain` vazio no worktree revisado, na conferência ao receber; e revisão." O "Quem você é" e o "Rode o `verify.sh` você mesmo" do modo `diff` ficam.
  - `modelos.md`, item 4 "Ferramentas": o revisor vai para um produto que restrinja a escrita; sem isso, "só o parecer" fica por revisão e pela conferência ao receber, e a decisão de composição diz isso.
  - `README.md:27`: "…em contexto limpo, escreve só o parecer e nunca corrige" | "contrato do papel + adaptador + conferência ao receber". `README.md:58`: "escreve além do parecer ou revisa o que produziu".
  - Adaptadores: `tools: Read, Grep, Glob, Bash, Write` e `tools: ['read', 'search', 'execute', 'edit']`; a nota de cada um: pode escrever só o parecer, no caminho do brief; o resto é verificado na conferência ao receber e por revisão.

- [ ] **Passo 4: Rodar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -1; sh bootstrap/instalar.Tests.sh 2>&1 | tail -1`
Expected: `0 falhas` nas duas.

- [ ] **Passo 5: Commit**

```bash
git add core/papeis/revisor.md core/processo/modelos.md README.md adapters/claude-code/agents/revisor.md adapters/copilot/agents/revisor.agent.md bootstrap/instalar.Tests.sh scripts/coerencia-kit.Tests.sh
git commit -m "feat(revisor): escreve só o parecer, fora do worktree, em todo o kit"
```

---

### Task 5: Orquestração usa o template, no kit inteiro

Design 5.4, 5.5 e as linhas restantes da tabela da 5.8.

**Arquivos:**
- Modificar: `core/processo/ciclo.md:101-105`, `core/templates/AGENTS.md:12`, `adapters/claude-code/commands/nova-task.md` (passo 4), `adapters/claude-code/commands/mudanca.md` (passo 2), `docs/portabilidade.md:23`, `core/templates/pr.md` ("Parecer do revisor"), `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consome: helpers da Task 1 e a variável `k` (lista de caminhos da varredura) definida no bloco da Task 4.

- [ ] **Passo 1: Asserções**

```sh
tl_espera 0 "kit sem task-N-brief/relatorio" nenhum 'task-N-(brief|relatorio)' $k
c=core/processo/ciclo.md
for t in 'agentic/processo/templates/brief.md' 'NN-<papel>' 'Desde a rodada anterior' 'brief anterior' \
         'linha de retorno' 'Ao receber' 'pareceres/'; do
  tl_espera 0 "ciclo: Orquestração cita $t" tem $c "$t"
done
tl_espera 0 "AGENTS: papel grava o relatório e devolve a linha" tem core/templates/AGENTS.md 'linha de retorno'
tl_espera 0 "nova-task: brief pelo template" tem adapters/claude-code/commands/nova-task.md 'agentic/processo/templates/brief.md'
tl_espera 0 "nova-task: conferência ao receber" tem adapters/claude-code/commands/nova-task.md 'Ao receber'
tl_espera 0 "mudanca: brief pelo template" tem adapters/claude-code/commands/mudanca.md 'agentic/processo/templates/brief.md'
tl_espera 0 "portabilidade: brief pelo template" tem docs/portabilidade.md 'agentic/processo/templates/brief.md'
tl_espera 0 "pr: parecer em pareceres/ sem plataforma de PR" tem core/templates/pr.md 'pareceres/'
```

- [ ] **Passo 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep FALHA`
Expected: falham as asserções acima; a de `task-N` lista `ciclo.md` e `portabilidade.md`.

- [ ] **Passo 3: Editar o texto.** `ciclo.md`, "Orquestração", item 2: as duas linhas de `task-N-*` dão lugar às cinco regras da seção 5.5 (brief pelo template e conferido por "Antes de enviar"; rodada de correção = despacho novo com o brief anterior copiado inteiro mais "Desde a rodada anterior", nunca continuação; relatório gravado pelo papel, retorno é só a linha; "Ao receber" antes de passar adiante; parecer local, final aprovado em `agentic/projeto/specs/<nome>/pareceres/` quando não há plataforma de PR). O `progress.md` fica. Os demais arquivos, pela tabela da 5.8. Os prompts do Copilot e o `copilot-instructions.md` não mudam (apontam para os comandos e para o `AGENTS.md`).

- [ ] **Passo 4: Rodar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -1; sh bootstrap/instalar.Tests.sh 2>&1 | tail -1`
Expected: `0 falhas` nas duas (o caso "ponteiros dos agentes e prompts levam a arquivos instalados" continua verde).

- [ ] **Passo 5: Commit**

```bash
git add core/processo/ciclo.md core/templates/AGENTS.md adapters/claude-code/commands/nova-task.md adapters/claude-code/commands/mudanca.md docs/portabilidade.md core/templates/pr.md scripts/coerencia-kit.Tests.sh
git commit -m "feat(processo): orquestrador monta o brief pelo template e confere ao receber"
```

---

### Task 6: Briefs e parecer de exemplo

Critério de pronto 1 e 2 do design. Um projeto fictício (task `pedidos/001-criar`, worktree `/home/dev/loja/agentic/.estado/worktrees/pedidos-001-criar`), comandos só do kit (`sh agentic/mecanismos/scripts/verify.sh`, `verifica-red.sh`, `verifica-escopo.sh`) e "o comando de teste por arquivo do `AGENTS.md`".

**Arquivos:**
- Criar em `docs/exemplos-brief/`: `01-dominio-brief.md`, `02-arquiteto-brief.md`, `03-testes-brief.md`, `04-dev-brief.md`, `05-revisor-diff-brief.md`, `06-dev-brief.md` (correção, depois do parecer 05), `07-revisor-diff-brief.md` (confirmação), `07-revisor-diff-parecer.md`
- Modificar: `scripts/coerencia-kit.Tests.sh`

- [ ] **Passo 1: Asserções**

```sh
for f in "$raiz"/docs/exemplos-brief/*-brief.md; do
  e=docs/exemplos-brief/$(basename "$f")
  tl_espera 0 "$e: primeira linha é Papel de um contrato do kit" sh -c \
    "p=\$(head -n1 '$f' | tr -d '\r' | sed -n 's/^Papel: \([a-z]*\).*/\1/p'); [ -n \"\$p\" ] && [ -f '$raiz/core/papeis/'\$p.md ]"
  tl_espera 0 "$e: contrato com caminho absoluto" linha $e '^Contrato: (/|[A-Za-z]:/)'
  tl_espera 0 "$e: perfil com caminho absoluto" linha $e '^Perfil: (/|[A-Za-z]:/)'
  for s in '## Escopo' '## O que fazer' '## Já decidido' '## Nunca faz' '## Leia só isto' '## Comandos' '## Teto' '## Entrega'; do
    tl_espera 0 "$e: seção $s" tem $e "$s"
  done
  tl_espera 0 "$e: teto com número" sh -c "tr -d '\r' < '$f' | sed -n '/^## Teto/,/^## /p' | grep -q '[0-9]'"
done
for e in docs/exemplos-brief/06-dev-brief.md docs/exemplos-brief/07-revisor-diff-brief.md; do
  tl_espera 0 "$e: correção traz Desde a rodada anterior" tem $e '## Desde a rodada anterior'
done
tl_espera 0 "parecer de confirmação: Rodada anterior" tem docs/exemplos-brief/07-revisor-diff-parecer.md '## Rodada anterior'
tl_espera 0 "exemplos sem nome de stack, de projeto de referência ou de ferramenta de orquestração" nenhum \
  'avitech|forja|lupa|esquadro|mocktail|worker_done|maestri|\borca\b|select-object|maven|\bmvn\b|flutter' docs/exemplos-brief
```

- [ ] **Passo 2: Rodar e ver falhar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | grep -c FALHA`
Expected: ≥ 3 (as asserções do 06, do 07 e do parecer, cujos arquivos ainda não existem).

- [ ] **Passo 3: Escrever os exemplos** pelo template, cada um com até ~40 linhas. Sem perder nenhuma cláusula que os briefs maduros do projeto de referência traziam: escopo com "PARE e pergunte"; "nunca toque em <testes|produção>"; leitura com intervalo; comando com saída limitada; lista de proibidos (push, `verify` pelo papel que não é o revisor, leitura de dependência); teto com ação; commits sem push; arquivo de relatório; linha de retorno; canal de dúvida. No 03, o `verifica-red.sh` fica com o orquestrador; no 05 e no 07, o `verify.sh` fica com o revisor. O 06 é cópia do 04 com "O que fazer" reescrito e "Desde a rodada anterior" citando `05-revisor-diff-parecer.md` e os IDs dos achados. O parecer 07 confirma achados do 05 na tabela "Rodada anterior".

- [ ] **Passo 4: Rodar**

Run: `sh scripts/coerencia-kit.Tests.sh 2>&1 | tail -1`
Expected: `<n> testes, 0 falhas`.

- [ ] **Passo 5: Commit**

```bash
git add docs/exemplos-brief scripts/coerencia-kit.Tests.sh
git commit -m "docs(exemplos): um brief por papel, uma correção e um parecer de confirmação"
```

---

### Task 7: Varredura final e verificação do kit

- [ ] **Passo 1: Varredura** (design 5.8, último parágrafo)

Run: `grep -rniE "revisor|brief|relatório|parecer|\bWrite\b|'edit'" core adapters bootstrap mecanismos README.md docs/portabilidade.md | grep -v '\.Tests\.sh:'`
Expected: toda ocorrência é coerente com o design. A que não for, corrija no arquivo e acrescente uma asserção à suíte; commit `docs(<área>): …`.

- [ ] **Passo 2: Verificação completa**

Run: `sh scripts/verify.sh 2>&1 | tail -3`
Expected: última linha `verify: OK`.

- [ ] **Passo 3: Critérios de pronto do design (seção 7)**, um a um, com o comando que prova cada um, colados no relatório final: exemplos por papel (Task 6), parecer de confirmação (Task 6), `verify: OK`, `task-N` ausente e revisor sem "sem escrita" (asserções `nenhum` das Tasks 4 e 5).

- [ ] **Passo 4: Publicação.** Pergunte ao dono antes do push. Com o OK: `git push -u origin brief-e-parecer` e PR para `main` com o resumo por task, a saída do `verify`, a correção da Task 0 destacada como defeito anterior, e o rodapé `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. O merge é do dono.
