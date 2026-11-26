# Decisões por arquivo e delegação local do Gate 1 — Design

**Data:** 2026-11-25
**Status:** aprovado (2026-11-25)
**Autor:** mantenedor do framework (decisões) · Claude (redação e análise)
**Origem:** um time real vai adotar o kit com vários devs, cada um no seu clone, em specs diferentes (conversa de 22/11, retomada em 25/11). Os volumes vêm dos registros de decisões das instâncias A a E e de uma instância de teste, lidos sem alteração em 25/11.

## 1. Intenção

Hoje o kit supõe um humano com um orquestrador por repositório. Com vários devs, dois pontos quebram no merge:

1. **`D<n>` colide sem aviso.** Duas branches saem da principal com a D6 como última decisão, e cada uma cria a sua D7. O conflito do `decisoes.md` é resolvido à mão: mantendo as duas, o registro fica com dois `### D7` (a função `ids` do `verifica-decisoes.sh` faz `sort -u` e conta uma só); sobrescrevendo, a decisão da principal se perde e a checagem de "decisão que sumiu" passa, porque o número continua lá.
2. **A delegação do Gate 1 e o modo automático são do repositório, não do dev.** `agentic/auto-mode` é um arquivo versionado só. Se um dev delega o Gate 1 e outro não quer delegar, um sobrescreve o outro.

O que se quer: decisões que não colidem por construção, e delegação e modo automático por dev, sem perder a proteção de que só o humano autoriza.

## 2. Evidência

| Dado | Fonte |
|---|---|
| Registros de 3 a 20 decisões; o maior tem 176 linhas e 29 KB (A); D tem 14, 4 revogadas | `agentic/projeto/decisoes.md` das instâncias A–E e de teste |
| Ritmo: 12 das 20 decisões de A entraram no dia do bootstrap; as outras 8 em um mês. D criou 14 em 6 dias | `git log -p` do registro em A; commits do registro em D |
| 3 das 20 decisões de A são delegações do Gate 1, uma por plano (D14, D16, D19) | registro de A |
| A cita `D<n>` 1.120 vezes, em 157 dos 304 arquivos de `agentic/projeto/`; só a D2 aparece 246 vezes, a maioria em `spec.md` e `design.md`, e são decisões do projeto (nenhum design de A define `D<n>` próprio) | varredura de `agentic/projeto/**/*.md` em A |
| Os agentes não leem o registro inteiro: em A, 6 leituras do arquivo, todas por intervalo, e 21 buscas por Grep. A amostra é parcial, porque A roda boa parte no opencode | telemetria do Claude Code de A (`~/.claude/projects`) |
| O `verifica-decisoes.sh` caiu de 48,8 s para 1,0 s ao deixar de abrir um processo por item | `docs/evidencias.md` §13 |

**Alternativa descartada (implementada e descartada em 25/11):** manter o arquivo único e a numeração sequencial, e bloquear a colisão depois que ela acontece (número repetido, número novo que a principal já usa, título da base trocado). O aviso só chega ao segundo dev depois que o primeiro integrou, a renumeração é manual e passa por spec, design, tasks e Rulings, o título de uma decisão integrada deixa de poder ser corrigido, e tudo depende da principal local atualizada. Ela trata o sintoma; a causa é o arquivo único com um contador global.

## 3. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
- Decisão nova nunca colide com a de outra branch, nem pede renumeração.
- Delegação do Gate 1 e modo automático valem para o dev que os ligou, no clone dele.
- Só o humano autoriza: a delegação fica num arquivo que o agente não edita.
- As decisões `D<n>` existentes continuam válidas, sem migração.

**Não-objetivos**
- Gatilhos N3 do `AGENTS.md` sumindo em merge e a visão do time no `status-projeto` (os outros dois pontos de 22/11). Ficam para depois.
- Quem aprova o Gate 1 da spec de outro dev. No modelo escolhido (22/11, opção A), cada dev é o humano da própria spec.

**Anti-objetivos**
- Nenhum índice de decisões escrito à mão: ele traria de volta o arquivo único que todos editam.
- Nenhuma migração obrigatória das `D<n>`: em A, ela mexeria em 157 arquivos.

## 4. Decisões por arquivo

### 4.1 Formato

Cada decisão nova é um arquivo `agentic/projeto/decisoes/<slug>.md`. O slug segue `^[a-z0-9]+(-[a-z0-9]+)*$` e descreve a decisão (`tenant-rls-dois-niveis`, `cache-de-precos`). Template novo, `core/templates/decisao.md`:

```markdown
# <título>

**Status:** vigente

- **Decisão:** <…>
- **Por quê:** <…>
- **Consequência:** <…>
- **Verificado por:** <mecanismo | por revisão>
- **Data:** <AAAA-MM-DD>
```

- **Revogar:** a linha vira `**Status:** revogada em <AAAA-MM-DD>: <motivo>`. O arquivo fica, e referências a ele continuam válidas.
- **Título e texto podem ser corrigidos.** O que identifica a decisão é o nome do arquivo; renomear conta como apagar.
- **Referência:** `D:<slug>`, em toda posição onde hoje cabe `D<n>`: o `Fonte:` das regras (`decisão:D:<slug>`), as Rulings, "Já decidido" do brief e o trailer `Assercoes-removidas: <arquivo> <n> (D:<slug>)` do `verifica-red`.
- **Colisão de slug** só acontece se duas branches escolherem o mesmo nome. O git acusa um conflito add/add no merge, que é visível. Nenhuma checagem é necessária.
- **Decisão que mexe em gatilho N3** continua atualizando o `AGENTS.md` no mesmo commit ("Decisão que mexe em gatilho").

### 4.2 Convivência com as `D<n>`

- O `decisoes.md` fica onde está, congelado: suas `D<n>` continuam valendo e podem ser revogadas nele (movidas para "Decisões revogadas", como hoje).
- `### D<n>` nova no `decisoes.md` é bloqueada, com a mensagem "decisão nova vai em `agentic/projeto/decisoes/<slug>.md`". Sem isso, o contador antigo continuaria em uso e a colisão voltaria.
- Instância nova não tem `decisoes.md`. O bootstrap grava as decisões iniciais (stack e comandos de verificação, ferramenta de arquitetura, CI, composição do time, baseline de testes pulados) como arquivos.
- O template `core/templates/decisoes.md` ganha uma linha no topo: o registro está congelado, e decisão nova vai em `decisoes/`. Ele deixa de ser usado pelo bootstrap e perde o bloco comentado da delegação do Gate 1 (§5).

### 4.3 Leitura pelos agentes

- O nome do arquivo é o índice: `ls agentic/projeto/decisoes/` mostra o que existe, e o papel lê só a decisão que importa. O `arquiteto` passa a ter como entrada a pasta e, se existir, o `decisoes.md` congelado.
- O brief continua citando a decisão pelo ID em "Já decidido". Um `D:<slug>` aponta direto para o arquivo, sem intervalo de linhas.

### 4.4 `verifica-decisoes.sh`

| # | Checagem | Hoje |
|---|---|---|
| 1 | Toda referência resolve: `D<n>` num `### D<n>` do `decisoes.md`; `D:<slug>` num arquivo `decisoes/<slug>.md`. Varre `agentic/projeto/**/*.md`, inclusive os arquivos de `decisoes/`, fora o `decisoes.md` | só `D<n>`, e também no `auto-mode` |
| 2 | Nada da base some: nenhuma `D<n>` da base ausente em HEAD, nenhum arquivo de `decisoes/` da base ausente em HEAD | só `D<n>` |
| 3 | `### D<n>` presente em HEAD e ausente na base bloqueia | novo |
| 4 | Todo arquivo de `decisoes/` tem slug válido, título `# ` e `**Status:**` `vigente` ou `revogada em <AAAA-MM-DD>: <motivo>` | novo |
| 5 | Delegação do Gate 1: §5.3 | `gate1: D<n>` vigente |

**Restrição de custo:** as checagens continuam em lote, sem processo por arquivo: uma varredura da pasta, um `git ls-tree` da base para a lista de arquivos, um `awk` por conjunto. O tempo medido do script entra no PR.

Sem `decisoes.md` e sem `decisoes/`: pulado, como hoje.

## 5. Delegação do Gate 1 local

### 5.1 O arquivo

`agentic/auto-mode` sai do git e entra no `.gitignore`. Cada dev tem o seu. O caminho é o mesmo, então a proteção contra edição pelo agente (o `deny` dos adaptadores, princípio 4) continua valendo sem mudança, e o `status-projeto` continua lendo de onde lê.

A decisão `D<n> — Delegação do Gate 1` deixa de existir. O conteúdo dela passa ao arquivo:

```
# Modo automático: com enabled: true o orquestrador encadeia tasks e publica PRs sem confirmação.
# Nunca faz merge. Arquivo local, fora do git; alterar é decisão humana.
enabled: false
# Gate 1 delegado ao orquestrador (vale só com enabled: true; vazio = Gate 1 humano):
#   todas | <spec ou mudança>, <spec ou mudança>
gate1:
# Plano que orienta as respostas do orquestrador (versionado em agentic/projeto/planos/):
plano:
# Itens N3 que o orquestrador aprova: nenhum | <item>, <item>
n3: nenhum
```

- **Por que não o `progress.md`:** o `progress.md` é escrito pelo orquestrador a cada passo; uma autorização num arquivo que o agente edita permitiria a autodelegação. E ele é por execução, enquanto a delegação vale para as várias specs de um plano.
- **O plano continua versionado** em `agentic/projeto/planos/`: é material do time. Só a autorização é local.

### 5.2 Rastro

- Commit de registro: `docs(spec): <nome> aprovada (Gate 1 delegado)` e `docs(mudanca): <nome> aprovada (Gate 1 delegado)`, sem `D<n>`.
- O corpo do commit copia `gate1`, `plano` e `n3` do arquivo local, além das `N<n>` que já lista hoje. Esse commit é o registro versionado da delegação, e o humano o confere no Gate 2.
- A resposta que o orquestrador dá fora do plano passa de `N<n> (Gate 1 delegado, D<n>): …` a `N<n> (Gate 1 delegado): …`, e a `Fonte:` da regra, de `decisão:D<n> N<n>` a `delegado N<n>`.

### 5.3 Verificação (`verifica-decisoes.sh`, item 5)

- `gate1:` vazio, `todas` ou uma lista de nomes separados por vírgula; outro formato bloqueia. Com `gate1:` preenchido, `plano:` aponta um arquivo existente.
- **Corpo do commit, em qualquer clone (também na CI):** todo commit da branch com "Gate 1 delegado" no formato novo exige no corpo uma linha `gate1:` cobrindo o `<nome>` do commit (`todas` ou o nome na lista) e uma linha `plano:` com arquivo existente em HEAD. Sem elas, ou com `gate1:` que não cobre, bloqueia: `agentic: BLOQUEADO — commit registra Gate 1 delegado sem gate1:/plano: no corpo (copie-os do agentic/auto-mode)`.
- **Arquivo local, quando existe:** o `agentic/auto-mode` é lido da árvore principal do repositório (o diretório pai de `git rev-parse --git-common-dir`), também quando o verify roda num worktree; uma cópia dentro do worktree é ignorada. Com ele presente, o commit exige ainda `enabled: true` e `gate1:` cobrindo o `<nome>`, ou um Gate 1 humano do mesmo artefato registrado na branch, em qualquer posição (como hoje).
- **Sem o arquivo na árvore principal** (o clone de outro dev, a CI): só a parte do arquivo local deixa de ser conferida; o script declara `delegação não verificável neste clone` para os commits cujo corpo está completo. A exigência do corpo continua valendo.
- **Commit no formato antigo** (`Gate 1 delegado, D<n>`), numa branch aberta antes da atualização: conferido pela mesma regra do nome, e o `D<n>` é ignorado.

## 6. Migração

- **Instalação nova:** `instalar.sh` copia o padrão para `agentic/processo/templates/auto-mode` (versionado, do kit, no manifesto), cria `agentic/auto-mode` a partir dele só quando o arquivo não existe (fora do manifesto: o arquivo é do dev), acrescenta `agentic/auto-mode` ao `.gitignore` e cria `agentic/projeto/decisoes/`.
- **Outro dev no mesmo repositório:** o clone não traz `agentic/auto-mode`. Sem ele, o modo automático está desligado e o Gate 1 é humano. Para ligar, o dev copia `agentic/processo/templates/auto-mode` para `agentic/auto-mode` e edita.
- **Instância existente:** o `instalar.sh` acrescenta a linha ao `.gitignore` e, se `agentic/auto-mode` estiver versionado, lista no resumo da instalação a ação humana `git rm --cached agentic/auto-mode` (o arquivo local fica). Ele não roda esse comando.
- **Delegações antigas** (`D<n> — Delegação do Gate 1`): continuam no `decisoes.md` como histórico, e o humano as revoga quando quiser. O `gate1: D<n>` antigo no `auto-mode` local passa a bloquear com a mensagem de formato, apontando o formato novo.
- **`checa-instancia.sh`:** deixa de exigir `agentic/projeto/decisoes.md` e passa a exigir `agentic/projeto/decisoes/` (ou o `decisoes.md`, em instância antiga). A busca por `{{` cobre os dois. `agentic/auto-mode` ausente deixa de ser problema e vira aviso, com o comando de cópia do template.

## 7. O desconfortável, declarado

- **Duas fontes de decisão por muito tempo** nas instâncias existentes: o `decisoes.md` congelado e a pasta. O `arquiteto` tem de olhar as duas.
- **Dois formatos de referência para sempre:** `D7` e `D:cache-de-precos`.
- **A delegação deixa de ser vista pelo time antes de valer.** Hoje ela é uma decisão versionada; agora só aparece no commit de registro, depois de usada. O Gate 2 é o ponto de conferência.
- **Fora do clone de quem delegou, o commit "Gate 1 delegado" não é verificado** contra a delegação, só declarado não verificável. O que todo clone confere é o corpo do commit: `gate1:` cobrindo o `<nome>` e `plano:` com arquivo existente em HEAD (a revisão final acrescentou essa exigência; o formato antigo, com `D<n>` no assunto, não a tem). O `agentic/auto-mode` é lido da árvore principal do repositório, também quando o verify roda num worktree.
- **O `deny` cobre só a edição pelo agente:** escrita por shell no `agentic/auto-mode` não deixa rastro no git, porque o arquivo é local. Antes, versionado, um `printf >` ou `rm` aparecia no `git status` e no PR; agora o rastro conferido é o corpo do commit de registro, que o humano vê no Gate 2.
- **Slug escolhido por agente pode ser ruim** (genérico demais, ou parecido com outro). A revisão do design e do documento enxuto confere.

## 8. Arquivos afetados

- **Scripts e testes:** `mecanismos/scripts/verifica-decisoes.sh`, `verifica-red.sh` (trailer com `D:<slug>`), `status-projeto.sh` (linha do Gate 1), `bootstrap/instalar.sh`, `bootstrap/checa-instancia.sh`, `bootstrap/auto-mode.padrao` e os `*.Tests.sh` de cada um; `scripts/coerencia-kit.Tests.sh`.
- **Processo:** `core/processo/ciclo.md` (Gate 1 delegado, Decisões novas, Registro do Gate 1, Rulings, Remoção de comportamento), `core/principios.md`, `core/processo/modelos.md`.
- **Templates:** `decisao.md` (novo), `decisoes.md`, `spec.md`, `mudanca.md`, `design.md`, `pr.md`, `brief.md`, `AGENTS.md`.
- **Papéis e comandos:** `core/papeis/arquiteto.md`, `dominio.md`, `testes.md`; `adapters/claude-code/commands/mudanca.md`, `nova-task.md`, `intent.md`.
- **Bootstrap e documentação:** `bootstrap/entrevista.md`, `README.md`.

Pela regra de coerência do kit, cada menção a `D<n>` é conferida com grep nos dois lados (o texto e o mecanismo que o verifica), e a checagem correspondente entra no `coerencia-kit`.
