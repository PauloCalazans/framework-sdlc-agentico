# Evidências — o que as execuções reais mediram

Este documento resume as medições que justificam as decisões do kit. A página de divulgação cita cada número daqui, pela âncora da seção.

- **Data de corte:** 2026-11-15.
- **Identificação dos projetos:** só por código (A, B, C, D), com descrição neutra.
- **Fonte dos números:** os registros de execução das instâncias (`agentic/.estado/execucao/`: briefs, pareceres e relatórios dos papéis), extraídos por script, e as análises que o mantenedor fez sobre eles. Os registros brutos ficam nos repositórios das instâncias e não são públicos.

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

## Limites

- **Amostra pequena:** B tem 5 execuções, C ainda nenhuma, e de D só há a medição do verify.
- A classificação das causas (seção 4) é uma primeira passada, com as fronteiras duvidosas marcadas na análise original.
- Parte das devoluções pode ser efeito de medição (seção 3).
- Nenhuma instância tinha a revisão que converge até a data de corte. O efeito dela ainda não foi medido.
