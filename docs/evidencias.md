# Evidências — o que as execuções reais mediram

Este documento resume as medições que justificam as decisões do kit. A página de divulgação cita cada número daqui, pela âncora da seção.

- **Data de corte:** 2026-11-15 nas seções 1 a 10; 2026-11-22 nas seções 11 a 16.
- **Identificação dos projetos:** só por código (A, B, C, D), com descrição neutra.
- **Fonte dos números:** os registros de execução das instâncias (`agentic/.estado/execucao/`: briefs, pareceres e relatórios dos papéis), extraídos por script, e as análises que o mantenedor fez sobre eles. Das seções 11 a 16 em diante, também as transcrições locais das sessões e os logs do verify. Os registros brutos ficam nos repositórios e nas máquinas das instâncias e não são públicos.

<a id="e1"></a>
## 1. Projetos e amostra

O kit foi instalado em **4 projetos** reais:

| Código | Projeto | Uso medido |
|---|---|---|
| **A** | sistema de gestão em Java/Spring, onde o kit nasceu | 31 execuções |
| **B** | servidor MCP em Python | 5 execuções |
| **C** | projeto Java maduro, com o kit instalado desde 2026-11-06 | sem execuções registradas até a data de corte |
| **D** | a maior instância, com uma série de 20 tasks | medição do custo do verify (seção 10) |

A e B somam **36 execuções** e **705 despachos** de papéis (cada despacho é um agente chamado com um brief). Por papel:

| | Revisor | Dev | Testes | Arquiteto | Domínio |
|---|---|---|---|---|---|
| Despachos | 208 | 156 | 215 | 89 | 36 |

A soma por papel dá 704: um despacho do total de 705 não foi atribuído a nenhum dos cinco papéis na extração.

<a id="e2"></a>
## 2. Onde a revisão acontece

Em 187 revisões com modo identificado, **57%** (107) foram revisões de artefato, isto é, de spec, design ou documento de mudança, **antes de existir código**. O design é o artefato mais revisado: 62 revisões, quase tantas quanto as de diff de código (78).

Leitura: o custo da revisão está na especificação, não no código. Isso motivou o `## Impacto` no design (seção 6).

<a id="e3"></a>
## 3. Devolução

| | A | B | Total |
|---|---|---|---|
| Revisões devolvidas | 60% | 49% | **55%** |
| Revisor por dev (despachos) | 1,08 | 1,96 | 1,33 |
| Papel com mais despachos | testes (35%) | revisor (37%) | — |

O gargalo muda com a instância: em B é o revisor; em A é o `testes`, por testes legados contraditórios descobertos tarde.

Na instância A, a devolução **subiu** quando o kit passou a revisar spec e design: de 50% para 61%. Pode ser efeito de medição, porque antes não havia veredito padronizado, ou efeito real, porque artefatos revisados devolvem mais. A revisão que converge (seção 4) vai ser medida contra essa linha.

<a id="e4"></a>
## 4. Causas dos achados bloqueantes

Foram classificados por causa **227** achados Crítico e Importante, vindos de 157 pareceres de A e B. Cada achado foi comparado ao contrato do papel, ao perfil, ao template e ao brief que o autor recebeu naquela rodada.

| Causa | Achados | % |
|---|---|---|
| defeito real | 72 | **32%** |
| o autor não fez o que o contrato, o perfil ou o brief pedia | 76 | **33%** |
| afirmação sobre código, API ou spec sem conferir | 69 | **30%** |
| exigência do revisor sem base em texto | 8 | **3,5%** |
| só forma ou redação | 2 | **1%** |

Leitura: a revisão **não** devolve por forma; exigência sem base e forma somam menos de 5%. O problema está no autor que entrega sem conferir. Daí vieram o `## Pronto para revisão` (autoverificação), a coluna "Causa" no parecer e a regra de que o parecer não prescreve a correção.

Análise completa: `docs/specs/2026-11-14-revisao-convergente-design.md`.

<a id="e5"></a>
## 5. Volume por severidade

Nos pareceres de A e B há **528** achados Menores contra **260** Crítico + Importante (15 Críticos e 245 Importantes). Com a regra "Menor não abre rodada", dois terços dos achados deixam de custar uma nova rodada de revisão.

<a id="e6"></a>
## 6. Anatomia de duas cascatas de design

As duas execuções com mais revisões de design (10 rodadas em A, 17 revisões em B) somam 31 achados Crítico e Importante:

- **58%** vieram de impacto não levantado: quem usa o que muda, testes que o exercitam, specs que citam a regra;
- **61%** nasceram da correção da rodada anterior;
- **0** foram de forma.

Leitura: o motor das rodadas é a correção aplicada sobre o sintoma, sem levantar impacto, muitas vezes prescrita pelo próprio parecer ou pelo brief do orquestrador. Daí vieram o `## Impacto` no design e no brief, o "brief sem desenho", o "parecer sem prescrição" e a parada na 3ª devolução.

<a id="e7"></a>
## 7. Custo de contexto do brief

Medido em 114 briefs reais da instância A:

| Brief | Requisições | Cache lido |
|---|---|---|
| `testes`, sem modelo de brief | 117 | 25,8M |
| `testes`, com modelo de brief | 69 | **5,3M (−80%)** |
| `dev`, com modelo e teto ignorado | 219 | 27,7M |
| `dev`, com modelo e teto explícito e acompanhado | 61 | 6,5M |

Leitura: o que derruba o custo é "leia só isto (arquivo:linhas)", comando com saída curta e teto declarado. Além disso, **regra que está só no contrato linkado não é seguida por modelo barato**: os desvios pararam quando as cláusulas "Nunca faz" passaram a vir coladas no brief, escritas como ação.

Análise completa: `docs/specs/2026-11-06-brief-e-parecer-design.md`.

<a id="e8"></a>
## 8. Trilha enxuta

Na validação v1, uma mudança pequena seguiu a trilha padrão e gerou **309** linhas de documentação em 4 arquivos. Uma mudança equivalente na trilha enxuta gerou **58** linhas, num documento único: cerca de **80%** menos. A trilha enxuta manteve o RED provado, o revisor independente (que achou um defeito real) e os dois gates.

Fonte: `docs/validacao-v1.md`, seção 5.2.

<a id="e9"></a>
## 9. RED e documentação

Na instância A, **32 de 40** commits RED também editavam o documento da task. Uma regra que bloqueasse documentação no RED barraria quase todos. Por isso o `verifica-red.sh` isenta `docs/` e `intent/`, e compara as asserções por arquivo de teste.

Fonte: `docs/validacao-v1.md`, seção 9.

<a id="e10"></a>
## 10. Custo do verify (D)

Numa série de 20 tasks com duas rodadas de revisão cada, o verify inteiro em toda chamada foi estimado em **~20 h**, o maior custo do ciclo naquela stack.

| Medição | Valor |
|---|---|
| prova do RED antes do cache | 10,5 min |
| prova do RED com cache por SHA | **6 s** |
| suíte de testes inteira | ~20 min |

Leitura: o verify não é a causa raiz do custo, que está nas seções 4 e 6, mas é um multiplicador em stacks lentas. Daí vieram o cache da prova do RED por SHA, o `verify.sh --rapido` no laço do `dev` e a base única pelo merge-base.

<a id="e11"></a>
## 11. A fala do humano dentro da spec

Em 18 specs de A, B e C, o Questionário já respondido ocupava de 7% a 38% do texto da spec aprovada, com mediana de **~20%**. A resposta ficava na spec, que devia descrever só o estado atual.

Daí veio: cada resposta é gravada uma vez, como `N<n>` no `progress.md`, e o registro versionado é o corpo do commit do Gate 1. A spec cita a `N<n>` e não guarda a resposta.

Fonte: `docs/plans/2026-11-19-artefatos-enxutos.md`, "Base de evidência"; PR #23.

<a id="e12"></a>
## 12. Rodadas que não paravam

Em 22 artefatos de planejamento com pareceres locais, **10 de 22** passaram de 3 devoluções, e dois designs chegaram a 9 e 10. Nenhum `progress.md` registrava a parada da 3ª devolução, que o kit já pedia.

Daí veio: na 3ª devolução o orquestrador para de verdade e o humano escolhe a saída (decidir o ponto, reduzir o escopo ou autorizar mais uma rodada). Nenhuma saída aceita artefato com Crítico ou Importante pendente. Na rodada 2 em diante, o revisor recebe o delta pronto.

Fonte: `docs/plans/2026-11-19-artefatos-enxutos.md`, "Base de evidência"; PR #24.

<a id="e13"></a>
## 13. Scripts lentos em todo verify

Medido em A, B e C, numa máquina Windows com Git Bash:

| Script | A antes | A depois |
|---|---|---|
| `verifica-decisoes.sh`, que roda em todo verify, inclusive no `--rapido` | **48,8 s** | **1,0 s** |
| `status-projeto.sh`, que roda em todo início de sessão | **32,3 s** | **3,1 s** |

Daí veio: uma varredura só para todos os arquivos, no lugar de processos por arquivo e por referência. A saída é idêntica antes e depois.

Fonte: PR #25.

<a id="e14"></a>
## 14. O contexto do orquestrador

Nas transcrições de B, onde todos os papéis rodam como subagentes (1.861 requisições do orquestrador), o orquestrador tem **54%** do peso em tokens do ciclo. O contexto médio dele é de **378 mil** tokens por requisição, e a compactação só acontecia perto do limite de 1 milhão.

Daí veio: a sessão do orquestrador compacta aos 200 mil tokens e retoma pelo `progress.md`, na mesma sessão. Na simulação com o mesmo crescimento, o contexto médio cai para **130 mil**. O ganho é simulado: ainda não foi medido numa instância.

Fonte: PR #26.

<a id="e15"></a>
## 15. O verify completo rodado de novo

Em B, o verify completo ocupa 34% do tempo do revisor `diff`, e **21 de 61** rodadas foram repetição na mesma execução, porque a saída cortada por `| grep` ou `| tail` escondia o motivo da falha. Em A e D, o orquestrador rodou o completo no mesmo commit que o revisor tinha acabado de aprovar, em **4 de 4** tasks conferidas.

Daí veio: a saída inteira vai para `agentic/.estado/verify.log`, e um completo já aprovado na mesma árvore termina em "já provado nesta árvore", sem rodar de novo.

Fonte: PR #28.

<a id="e16"></a>
## 16. RED pela suíte inteira (D)

Em D, um monorepo com quatro executores de teste, cada RED novo levava de **30 a 40 min**, porque o kit só provava o RED pela suíte inteira. Provado pelo executor do arquivo, o RED real levou de **0,4 s** (node) a **254 s** (Kotlin).

Daí veio: executores `TESTE_<n>_*` por padrão de caminho, só com configuração. Cada arquivo do RED é provado pelo executor do seu caminho.

Fonte: `docs/specs/2026-11-21-red-por-caminho-design.md`, seção 2; PR #29.

## Limites

- **Amostra pequena:** B tem 5 execuções, C ainda nenhuma, e de D só há a medição do verify.
- A classificação das causas (seção 4) é uma primeira passada, com as fronteiras duvidosas marcadas na análise original.
- Parte das devoluções pode ser efeito de medição (seção 3).
- Nenhuma instância tinha a revisão que converge até a data de corte. O efeito dela ainda não foi medido.
- Os ajustes das seções 11 a 16 entraram no kit entre 2026-11-19 e 2026-11-22. O efeito deles nas instâncias ainda não foi medido, e o ganho da seção 14 é simulado.
