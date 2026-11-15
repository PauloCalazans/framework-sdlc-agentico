# Revisão que converge — Design

**Data:** 2026-11-14
**Status:** aprovado (2026-11-15)
**Autor:** mantenedor do framework (decisões) · Claude (redação e análise)
**Origem:** 227 achados bloqueantes de 157 pareceres reais de duas instâncias, pareceres de orquestradores de outras duas instâncias e o SWEBOK v4.0a (texto integral).

## 1. Intenção

O framework existe para que o time use agentes em todo o ciclo com engenharia de verdade: sem "vibe" e sem um humano lendo cada linha gerada. Ele só será adotado se se provar um processo profissional **sem cerimônia desnecessária**. Se o custo de seguir o kit parecer maior que o ganho, cada dev volta à própria preferência, e o software do time passa a ter um comportamento diferente a cada pessoa que lhe dá continuidade.

Hoje o custo aparece nas rodadas de revisão e no tempo de espera. Este design ataca a **causa** das rodadas, medida achado a achado. Afrouxar a revisão está fora de questão: os dados mostram que ela pega defeito real.

## 2. Evidência

### 2.1 Instâncias

| Instância | Perfil | Uso do kit |
|---|---|---|
| **A**, referência | Java/Spring, monólito modular multi-tenant; a v0 nasceu aqui | 22 execuções, 79 pareceres |
| **B** | Python, servidor MCP de integração | 4 execuções, 78 pareceres |
| **C** | Java, servidor MCP sobre protocolo externo, com 644 commits antes do kit | 2 specs de uma task cada; sem registros de execução |
| **D** | a maior instância | parecer do orquestrador sobre o verify, com uma série de 20 tasks |

### 2.2 Por que a revisão devolve (A + B; 227 achados Crítico/Importante)

Método: dois agentes classificaram cada achado bloqueante contra o contrato do papel do kit, o perfil do projeto, o template e **o brief que o autor recebeu naquela rodada**. É uma primeira passada, sem conferência linha a linha. As fronteiras a/b e b/e duvidosas ficaram marcadas. As datas foram conferidas: nenhuma regra citada foi criada depois do parecer.

| Causa | A | B | Total |
|---|---|---|---|
| (a) defeito real (comportamento, concorrência, segurança) | 35 | 37 | **72 (32%)** |
| (b) o autor não fez o que o próprio contrato, perfil ou brief pedia | 62 | 14 | **76 (33%)** |
| (e) afirmação sobre código, API ou spec existente feita sem conferir | 54 | 15 | **69 (30%)** |
| (c) exigência do revisor que nenhum texto do autor pedia | 5 | 3 | **8 (3,5%)** |
| (d) só forma ou redação | 2 | 0 | **2 (1%)** |

Leituras:
- **Autor e revisor não estão desalinhados.** A categoria (c) fica em 3,5%. Forma e redação vieram como Menor; o parecer do orquestrador de B ("devolve por forma") não se confirma nos achados que bloquearam.
- **O arquiteto concentra o problema.** Em A, ele é autor de 89 dos 158 achados: 34 (e), 31 (b), 19 (a), 3 (c), 2 (d). Nos de arquiteto e domínio, a falha dominante é **levantamento de impacto**:
  - classe que monta DTO na aridade antiga, fora de `## Arquivos`;
  - teste citado que não existe;
  - endpoint sem chamador;
  - claim de JWT que o emissor não tem;
  - regra de outra spec aprovada alterada sem emenda.
- **O kit induz isso.** `core/papeis/arquiteto.md`, "Consome", lista spec, decisões e templates. **Não lista o código existente nem as specs afetadas.** O `design.md` tem "O que não muda", mas não tem impacto.
- **17% dos achados (38 de 227) uma máquina pegaria antes da revisão.** Exemplos:
  - critério de aceite sem task;
  - `**Branch:**` diferente da branch real;
  - arquivo citado inexistente;
  - símbolo das Interfaces ausente do contrato;
  - `test-compile` quebrado;
  - coluna "Decisão do humano" preenchida pelo autor;
  - caminho N3 em `## Arquivos` sem item N3;
  - import cruzando fronteira.
- **Os briefs do orquestrador introduziram defeitos:** cerca de 20 em A e 7 em B. São valores prescritos (`@Min(1900)`), caminho de implementação ditado, ordem para mudar produção sem RED, esqueleto mandado para a branch errada, e listas de ataque entregues só ao revisor, nunca ao autor.
- **As rodadas seguintes nascem da correção.** Quase todo achado de rodada ≥ 2 é defeito novo criado pela correção anterior, muitas vezes a correção que o próprio parecer prescreveu. As 10 rodadas de design de uma spec de A e as 6 de B foram cascatas em torno de um único tema.

### 2.3 Os 76 achados (b): regra ignorada ou mal escrita?

| Subgrupo | Achados | Leitura |
|---|---|---|
| mecanizável (lint de artefato, compile, grep) | 20 | a regra existe; nada a impõe |
| conflito: o brief ou uma Ruling contrariou o contrato | 10 | o orquestrador desenhou pelo brief |
| interseção dos dois acima | −4 | |
| regra de julgamento, clara e ignorada | 50 | cerca de 20 de testes e dev (a revisão de diff fazendo o papel dela) e cerca de 30 de arquiteto e domínio |

Os ~30 de arquiteto e domínio repetem poucas classes, todas já escritas no contrato e coladas no brief:
- hipótese promovida a confirmada sem fonte;
- critério de aceite não verificável, ou que já passa no HEAD (três rodadas seguidas na mesma mudança);
- esqueleto com comportamento, ou sem o que o RED vai referenciar;
- itens N3 incompletos.

**A regra não está mal escrita. Ela está em prosa, enterrada em parágrafo longo (`arquiteto.md`, "Produz", um único item de 10 linhas), e o autor não tem uma lista de saída.** Só outro agente confere, uma rodada depois.

### 2.4 Caso de controle (C)

C fechou com poucas rodadas: uma task de 2.631 linhas em 23 arquivos teve 2 rodadas de diff. A causa não foi a medição ao vivo. Foi o projeto ter o conhecimento capitalizado antes do kit:
- protocolo documentado como `medido`/`inferido` desde 05/10;
- infraestrutura que já absorve as peculiaridades do protocolo;
- mudança aditiva num padrão estabelecido.

Nos perfis de C, o arquiteto e o revisor exigem a mesma coisa. Com 2 specs, C não sustenta regra nenhuma. Ele mostra que **tamanho de task não é o que gera rodada**.

### 2.5 Cerimônia e espera

- **Commits `docs(task)` e `docs(spec)`:** 33% dos commits em A e em B.
  - Em A, ~270 são Rulings, ~110 são status e ~50 ampliação de escopo.
- **Verify em B:** completo de 4 a 6 vezes por task.
- **Verify em D:**
  - `npm test` completo leva ~20 min, e 20 tasks com 2 rodadas de revisor somam ≈ 20 h de verify;
  - a etapa RED caiu de 10,5 min para 6 s com cache por SHA;
  - a base é derivada de forma diferente por script.

### 2.6 O que diz a engenharia (SWEBOK v4.0a, texto integral; citações literais no Apêndice A)

- **Requisitos, 5.1:** quem fará o design confere se a spec basta ao trabalho dele. O guia recomenda dar aos revisores *checklists*, critérios de qualidade ou uma *definition of done*.
- **Design, 6.1 e 6.3:** a revisão de design avalia cobertura de requisitos, pendências e problemas potenciais. A análise inclui *automated cross-checking*.
- **Arquitetura, 4.3:** revisões por checklist ou *active reviews* (Parnas e Weiss), em que cada item exige do revisor uma ação concreta para obter a informação. Fairbanks: arquitetura na medida do risco.
- **Qualidade, 3.4.5:** tipos de revisão da ISO/IEC 20246, entre eles *checklist-based*. "Fixing a defect in a component that has been coded is much more expensive than catching it beforehand."
- **Qualidade, 2.4 e 2.4.1:** ação corretiva e preventiva, taxonomia de defeitos e análise de causa raiz. "Numbers alone, without classification, might be insufficient to help in identifying the underlying causes."

Leitura nossa: o critério do revisor deve ser o critério de pronto do autor; o que é verificável por máquina sai da revisão humana ou de agente; defeito recorrente vira ação preventiva no processo. É o Princípio 2 ("erro repetido vira mecanismo") com medição por causa.

## 3. Objetivos

1. **O arquiteto levanta o impacto** do que desenha, no código e nas specs aprovadas, com evidência `medido`.
2. **Uma lista só por artefato:** o que o revisor confere é o critério de saída do autor.
3. **Barreira mecânica antes da revisão de spec, design e mudança:** o que é verificável por máquina não chega ao revisor.
4. **O orquestrador não desenha:** o brief leva contrato, ponteiros e respostas do humano, nunca a solução. O parecer aponta o problema, não a correção.
5. **Revisão que converge:** a correção refaz o impacto do que mudou; a rodada seguinte olha o delta; uma cascata vai ao humano com a causa.
6. **Causa medida em todo parecer**, para que a próxima análise seja contagem e não opinião.
7. **Menos espera e menos commit de cerimônia:** verify em dois níveis com base única, cache de RED e ordem barata primeiro; Ruling e status sem commit próprio.

## 4. Não objetivos

- Mudar os gates. O Gate 2 continua humano, e N3 continua parando a execução.
- Rever a escolha de modelo por papel (`modelos.md`).
- Mexer no formato de spec do domínio além do item 5.1.

## 5. Anti-objetivos (falha mesmo que funcione)

- **Afrouxar o revisor ou limitar rodadas por cota.** 32% dos achados são defeitos reais ("a app não sobe", "o domínio vaza na query", "duas criações furam o teto").
- **O orquestrador corrigir achado.** Ele não implementa, e Menor também é do autor.
- **Número fixo de tasks por spec, ou divisão por tamanho.** A task é dividida por objetivo, sobe sozinha e pode crescer.
- **Trocar cerimônia de commit por cerimônia de documento.** Cada item novo precisa remover mais custo do que acrescenta. A autoconferência é uma seção do relatório que já existe, não um arquivo novo. A seção "Impacto" substitui investigação que hoje acontece em rodadas de revisão.
- **Mecanismo com falso positivo recorrente.** Script que atrapalha sem proteger é defeito do script.

## 6. Abordagens consideradas

| Abordagem | O que faz | Por que não, ou sim |
|---|---|---|
| **A. Aliviar a revisão** (parecer de B) | veredito "aprovado com ajustes", teto de 2 rodadas, 1–3 tasks por spec | ataca o sintoma; os dados mostram (d) ≈ 0 e (a) = 32%; teto fixo empurra defeito para o Gate 2 |
| **B. Alinhar os perfis** de arquiteto e revisor | reescrever os perfis para o autor saber o que será cobrado | a assimetria medida é 3,5%; os perfis já estão alinhados |
| **C. Deslocar a verificação para antes da revisão** (**escolhida**) | impacto como entrega do arquiteto, lista única, barreira mecânica, brief sem desenho, causa medida | ataca (b) + (e) = 63%, que é onde está o custo; mantém o revisor para (a) |

## 7. Design

Cada bloco é uma task com objetivo próprio, integrável sozinha. A ordem da seção 8 é de valor, não de dependência.

### 7.1 Impacto é entrega do arquiteto

- **`core/papeis/arquiteto.md`, "Consome":** acrescenta o código do repositório e as specs aprovadas que a mudança toca.
- **"Produz":** acrescenta a seção **Impacto**, no `design.md` e no `mudanca.md`:

  | Alterado (símbolo, rota, schema, regra) | Quem usa hoje (`arquivo:linha`, `medido` por busca) | Em `## Arquivos` de qual task | Teste existente afetado | Regra de outra spec tocada → emenda |
  |---|---|---|---|---|

- **Regra de outra spec aprovada:** só muda com emenda declarada nessa seção, e a emenda vira item do Gate 1. Isso cobre o caso "JWT do identity" de A, que nenhum mecanismo pegaria.
  - **Como a emenda se materializa** (decisão de redação): o mesmo molde de "Divergência spec × código". Depois do Gate 1, a spec afetada é alterada na branch da primeira task que depende dela, num commit `docs(spec): <outra spec> — Emenda <n> (<esta spec>)`. O arquivo dessa spec entra em `## Arquivos` da task. Antes do Gate 1 a emenda existe só declarada no design, e o humano a aprova como item.
- **O "Produz" de 10 linhas vira itens curtos.** O conteúdo não muda; a forma passa a ser verificável item a item.
- **`dominio`:** afirmação sobre o estado atual ("hoje o sistema faz X", "a doc não diz Y") cita a fonte aberta, como já se exige das regras. São 16 achados (e) do domínio.

### 7.2 Uma lista só, usada duas vezes

- **Cada contrato de autor ganha "Pronto para revisão":** `dominio` (spec), `arquiteto` (design e mudança), `testes` (RED) e `dev` (GREEN). É a lista que o revisor confere naquele modo.
- **O `revisor.md` deixa de repetir a lista.** O modo diz "confere a lista 'Pronto para revisão' do autor + o perfil + o ataque" e acrescenta só o que é do revisor:
  - independência;
  - rodar o verify ele mesmo;
  - abrir citações;
  - buscar defeito (a).
- **Perfil do projeto:** item de `Padrões` do revisor que cobra o autor tem de estar também no perfil do autor. O `checa-instancia.sh` não confere semântica, então isso é por revisão.
- **O autor registra a autoconferência no relatório que já grava:** uma linha por item, `ok`/`n.a.` com a evidência. Item `n.a.` sem motivo vale como não feito.
- **A lista de ataque montada pelo orquestrador vai igual ao autor e ao revisor.** No template de brief, ela vira a seção "Casos a cobrir".

### 7.3 Barreira mecânica antes da revisão de spec, design e mudança

Um script novo, `verifica-artefato.sh <spec|design|mudanca> <caminho>`, que o orquestrador roda na lista "Ao receber", antes de despachar o revisor. Com falha, o trabalho volta ao autor sem rodada de revisor.

- **Roda só antes do Gate 1** (decisão de redação). Não entra no `verify.sh`, porque não há regra de transição para specs e tasks já aprovadas sem a seção Impacto. Também não faz sentido verificar de novo depois do Gate 1 o que o revisor e o humano já aceitaram.
- **Artefatos aprovados antes desta versão do kit não são verificados.**

Checagens, todas sem julgamento:

1. Todo CA da spec tem task que o cobre e linha em "Como se prova". No modo `mudanca`, todo CA tem regra.
2. Todo caminho citado em `## Arquivos`, "Como se prova" e "Impacto" existe ou é criado pela task (está em `## Arquivos`).
3. `**Branch:**` da task segue `<spec>/<NNN>-<nome>` e não repete a de outra task. Quando o artefato está num worktree cuja branch já tem o prefixo da spec (o caso da trilha enxuta, e do design que o orquestrador despacha num worktree), a branch da task 001 é a do worktree.
4. Antes do Gate 1: a coluna "Decisão do humano" está vazia e nenhum texto do autor afirma aprovação. Na spec, nenhuma regra `confirmada` cita `Q<n>` ainda aberta.
5. Arquivo em `## Arquivos` que casa com um padrão de `CAMINHOS_N3` tem item N3 citado pela task. `CAMINHOS_N3` é uma variável nova e opcional em `agentic/config`, com globs separados por espaço, porque hoje os gatilhos da stack são prosa no `AGENTS.md`. Sem a variável, a checagem é pulada com aviso; o bootstrap passa a perguntar por ela.
6. Símbolo listado em "Interfaces → Produz" existe no contrato executável.
7. O contrato valida: o comando de validação do contrato do projeto (variável nova em `agentic/config`, por exemplo `CMD_VALIDA_CONTRATO`; em A, `test-compile` + ArchUnit; em C, `test-compile`). A saída registrada no design deixa de ser palavra do autor.

Fica fora: "esqueleto sem comportamento" e "CA que já passa no HEAD". Os dois dependem de julgamento ou de execução de teste que ainda não existe. Continuam com o revisor e com o `verifica-red.sh`.

### 7.4 O orquestrador não desenha; o parecer não prescreve

- **Template de brief:**
  - "O que fazer" diz a entrega, nunca a solução;
  - "Já decidido" só traz o que tem origem citável: resposta do humano com data, Ruling `R-n`, decisão `D<n>`, item N3 aprovado;
  - valor, nome de classe ou caminho de implementação que o orquestrador quer impor é Ruling registrada ou pergunta ao humano, nunca texto solto.
- **"Antes de enviar" ganha um item:** nenhuma linha do brief decide algo que não tem origem citável.
- **Template de parecer:** a coluna "Problema" diz o que está errado e **o que precisa passar a ser verdade**, não como corrigir. O revisor não prescreve código, valor nem caminho. A frase "o que outro papel deve fazer" sai.
- **Ruling não contradiz spec nem design aprovados.** Se a Ruling precisaria contradizer, vira pergunta. Isso já está em `ciclo.md`, "Rulings"; a mudança é colar a regra no brief do orquestrador para si mesmo, na lista "Antes de enviar".

### 7.5 Revisão que converge

- **Rodada de correção:** o autor atualiza a tabela de Impacto para tudo o que a correção alterou, e a autoconferência cobre o delta.
- **Revisor na rodada k ≥ 2:**
  - confere cada achado anterior (a tabela "Rodada anterior" já existe);
  - revisa o delta e o impacto do delta;
  - achado novo fora do delta, Crítico ou Importante, **entra e bloqueia como qualquer outro**. Ele é marcado `já na rodada 1` na coluna Causa, e essa contagem mede a qualidade da rodada 1. O revisor não fica mais brando: a revisão só passa a começar pelo delta, e a rodada 1 tem de ser exaustiva para esse número cair.
- **Cascata:** na 3ª devolução do mesmo artefato, o orquestrador para e leva ao humano o histórico de causas por rodada, antes de despachar a 4ª. Não é teto: o humano decide se segue, reescreve o design ou corta escopo. Isso dá previsibilidade sem empurrar defeito adiante.
- **Menor:** não abre rodada. Vai junto com a próxima correção ou, se não houver, no PR. A instância C já fez assim duas vezes, sem prejuízo.

### 7.6 Causa em todo parecer

- **A tabela de achados do `parecer.md` ganha a coluna "Causa":**
  - `defeito`;
  - `contrato` (o texto do autor pedia);
  - `não conferido` (afirmação sobre o existente);
  - `sem contrato` (nenhum texto do autor pedia);
  - `forma`.
- **Achado `sem contrato`:** o próprio parecer aponta onde a regra deveria estar. O mantenedor decide se ela entra no contrato ou no perfil. É a ação preventiva do SWEBOK 2.4.
- **Sem script de métrica.** A contagem é `grep` nos pareceres locais. A instância A removeu um `metricas-task.sh` por ser cerimônia, e isso não volta.

### 7.7 Verify em dois níveis e com base única (instâncias B e D)

Adotar a primeira leva do parecer de D (parecer externo de 2026-11; os detalhes estão resumidos aqui para não depender dele):
1. **Base única.** Hoje o `verify.sh` lê o `**Base:**` da task e exporta `AGENTIC_BASE`, mas os scripts avulsos não: `agentic_base` só olha `AGENTIC_BASE` ou a principal. Medido em D: o `verifica-red.sh` avulso numa branch empilhada provou de novo os REDs da task de baixo e passou de 40 min. Com base posicional, `git diff "$base"` usa a ponta da base e não o merge-base, e o escopo acusou arquivos que só a base mudou. Correção:
   - `agentic_base` lê o `**Base:**` da task da branch atual, achada pelo `**Branch:**`;
   - o argumento posicional também passa pelo merge-base;
   - a base é derivada e exportada antes da etapa `stack` (hoje ela roda antes, em `verify.sh:45`), e o `CMD_VERIFY_STACK` passa a receber `AGENTIC_BASE`.
2. **Ordem barata primeiro:** hooks → escopo → decisões → red → stack → skip (o `skip` lê os relatórios do `stack`).
3. **Cache da prova de RED por SHA.** Existe um protótipo em D, mas o kit **reimplementa a partir desta descrição** (decisão do mantenedor, 2026-11-15). Os 64 casos atuais do `verifica-red.Tests.sh` têm de continuar passando, e os casos novos são escritos no kit:
   - cada arquivo provado falhando grava `<sha do RED> <assinatura> <arquivo>` em `<git common dir>/agentic/red-provados`;
   - a assinatura é o hash de `CMD_PREPARAR_TESTE` mais o comando de teste;
   - arquivo já provado não sobe worktree;
   - a recusa de produção no RED e a contagem de asserções contra o HEAD rodam sempre;
   - `AGENTIC_RED_SEM_CACHE=1` força nova prova;
   - RED que passava, saída 126/127 e preparo com falha nunca são guardados.
4. **`</dev/null` no laço do RED.**
5. **Dois níveis:**
   - `verify.sh --rapido`: etapas baratas + o comando rápido da stack (variável nova, por exemplo `CMD_VERIFY_RAPIDO`), usado no laço de testes e dev;
   - completo: obrigatório uma vez antes do PR e no revisor em modo `diff`. A lista "Ao receber" passa a pedir o completo só nesses dois pontos.

Os demais itens do parecer de D (baseline de falhas conhecidas, verify em segundo plano, reuso por `write-tree`, tempo por etapa) ficam para depois da medição.

**Atrito medido em C, só documentação:**
- A sequência teste de caracterização (`test:`, verde) → `test(red):` entra em `testes.md`. O `verifica-red.sh` está certo em exigir que todo arquivo do RED falhe.
- **O caso do `verifica-decisoes.sh` foi reproduzido na leitura (2026-11-15) e não é falso positivo.** O design de C numerou as próprias decisões como `D9` e `D11`. O prefixo `D` é das decisões do projeto: com ele, as de número 1 a 8 colidiam em silêncio com decisões vigentes, e o script recusou 9 e 11 como inexistentes. O humano de C já fixou a regra ("as decisões de design não levam prefixo D, apenas as de projeto"). Ela entra no template `design.md` e na lista "Pronto para revisão" do arquiteto; o script não muda.

**Correção de ordem (2026-11-15):** a etapa `skip` lê os relatórios JUnit que o `stack` gera. Por isso ela fica depois do `stack`, e a ordem final é hooks → escopo → decisões → red → stack → skip.

### 7.8 Commits de cerimônia

- **Ruling sem commit próprio.** A linha entra em `## Rulings` e vai no próximo commit real da task (RED, GREEN, correção ou publicação). Em A, isso elimina ~270 commits sem perder o registro. O revisor continua conferindo a seção.
- **Só `em-andamento` passa a ser derivado do git** pelo `status-projeto.sh`: task `pendente` cuja branch existe com commits além do Gate 1 aparece como "em andamento (derivado do git)". O passo de `/nova-task` que escreve `em-andamento` sai, nos dois adaptadores.
  - Task que já tem `em-andamento` escrito continua válida; o script lê o que está escrito.
  - `em-revisão` (revisão aprovada, aguardando publicação) e `publicada` continuam escritos e com o mesmo significado. Derivá-los dependeria do registro de execução, que é local e diverge entre clones.
- **Ampliação de escopo continua em `docs(task)`,** porque muda o que o `verifica-escopo.sh` aceita. Ela fica mais rara com a seção Impacto.

## 8. Ordem sugerida e meta de cada bloco

Medir nas duas próximas execuções de cada instância, com a coluna "Causa".

| Ordem | Bloco | Meta |
|---|---|---|
| 1 | 7.3 barreira mecânica | zero achado das checagens 1–7 chegando ao revisor |
| 2 | 7.1 impacto do arquiteto | (e) de arquiteto e domínio ≤ 10% dos achados (hoje 30%) |
| 3 | 7.4 brief sem desenho e parecer sem prescrição | achado com origem no brief = 0 |
| 4 | 7.2 lista única | (b) ≤ 15% (hoje 33%) |
| 5 | 7.5 convergência | rodadas por artefato ≤ 3 sem escalonamento; achado marcado "já estava na rodada 1" ≤ 10% |
| 6 | 7.6 causa no parecer | 100% dos pareceres com a coluna |
| 7 | 7.7 verify | completo ≤ 2 por task; tempo de espera por task medido antes e depois em D |
| 8 | 7.8 cerimônia | commits `docs(*)` ≤ 15% |

Meta de conjunto: (a) passa a ser a maior fatia dos achados. É a revisão gastando o tempo com o que só ela pega.

## 9. O desconfortável, declarado

- **A classificação é de primeira passada,** feita por agentes. A fronteira a/b/e tem casos discutíveis, marcados no CSV. As proporções servem para orientar; não são exatas.
- **A amostra são duas instâncias com pareceres,** com stacks e domínios diferentes. C e D entram como contraste e como medição de verify.
- **A autoconferência pode virar carimbo.** Por isso ela não substitui nada: a barreira mecânica e o revisor independente continuam. O ganho esperado vem de o autor ter a lista antes, não de o revisor confiar nela.
- **A seção Impacto acrescenta texto ao design.** A aposta é que ela custe menos que as rodadas que hoje fazem o mesmo levantamento em série. Se não custar menos, a meta 2 mostra.
- **Cascata ao humano na 3ª devolução** troca autonomia por previsibilidade. Com o Gate 1 delegado, isso quer dizer parar uma execução que hoje seguiria sozinha.
- **O SWEBOK é guia, não norma.** As citações sustentam a direção, não uma conformidade.

## 10. Alcance da entrega

O plano entrega o kit, o bootstrap (perguntas novas: `CMD_VALIDA_CONTRATO`, `CMD_VERIFY_RAPIDO`, `CAMINHOS_N3`) e uma nota de atualização para as instâncias. As instâncias recebem a versão pela atualização normal do kit, cada uma no seu tempo. A medição da seção 8 começa na primeira execução de cada instância depois da atualização. Variável ausente nunca quebra uma instância antiga: a checagem correspondente é pulada com aviso.

## 11. Deixado ao construtor

- Nome e interface exatos do `verifica-artefato.sh`, e como ele lê `design.md`, `task.md` e `mudanca.md` sem frágil dependência de formatação. Se precisar, o template ganha marcadores estáveis.
- Nome das variáveis novas de `agentic/config` e o comportamento quando não estão definidas (pular a checagem 7 com aviso ou falhar).
- Redação dos itens "Pronto para revisão" de cada papel, a partir das listas atuais do `revisor.md` e dos perfis.
- Como o `status-projeto.sh` detecta parecer `diff` sem depender de plataforma.
- Testes de cada script no padrão `*.Tests.sh` existente.
- Atualizar `docs/exemplos-brief` se algum exemplo contrariar 7.4.

## Apêndice A — SWEBOK v4.0a, trechos literais

- **Requisitos, 5.1:** "software engineers who will do architecture, design or construction of the software that satisfies these requirements check that the document is sufficient to support their work. Providing checklists, quality criteria or a "definition of done" to the reviewers can guide them to focus on specific aspects of the requirements specification."
- **Arquitetura, 4.3:** "Many reviews are informal or expertise-based, and some are more structured, organized around a checklist of topics to cover. Parnas and Weiss proposed an effective approach to conducting reviews, called active reviews, where instead of checklists, each evaluation item entails a specific activity by a reviewer to obtain the needed information."
- **Design, 6.1:** "Design reviews are intended as comprehensive examinations of a design to assess concerns such as status or degree of completion, coverage of requirements, open or unresolved issues and potential problems."
- **Design, 6.3:** "Static analysis: formal or semiformal static (nonexecutable) analysis that can be used to evaluate a design (for example, fault-tree analysis or automated cross-checking)."
- **Qualidade, 3.4.5:** "Reviews are valuable because they can identify issues early in development or even before a component is designed. Fixing a defect in a component that has been coded is much more expensive than catching it beforehand." e "Checklist-based reviews — systematic reviews identifying issues based on checklists".
- **Qualidade, 2.4.1:** "Numbers alone, without classification, might be insufficient to help in identifying the underlying causes and thus to prevent them in the future. Therefore, software engineers should establish a meaningful defect classification taxonomy […] Other SQM activities attempt to eliminate their causes (e.g., root cause analysis (RCA))."
- **Arquitetura, leituras (Fairbanks):** "do just enough software architecture to mitigate the identified risks […] The risk-driven approach is harmonious with low-ceremony and agile approaches."
