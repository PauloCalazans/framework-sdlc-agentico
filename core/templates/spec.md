# Spec: <nome>

**Intent:** agentic/projeto/intent/<NNN-nome>.md
**Status:** draft

## Regras
| # | Regra | Fonte | Estado |
|---|---|---|---|
| R1 | <regra de negócio> | <humano:<AAAA-MM-DD> N<n> "<trecho>" \| oráculo:arquivo:linha \| plano:arquivo:linha \| decisão:D:<slug> (ou D<n>, no registro congelado)> | <confirmada \| hipótese> |

## Critérios de aceite
- CA1 (R1): <dado … quando … então …>

## Invariantes (o que não muda)
- <comportamento existente que deve permanecer>

## Fora de escopo
- <item>

## Questionário de decisão
1. <pergunta objetiva derivada de uma hipótese> — opções: (a) <…> (b) <…>. Recomendação: <…>, porque <…>.
   <!-- Só perguntas em aberto. Respondida, a pergunta sai daqui: a resposta fica no progress.md e no corpo do commit do Gate 1 (agentic/processo/ciclo.md, "Resposta do humano"), e a regra cita humano:<AAAA-MM-DD> N<n> "<trecho>". Gate 1 delegado: coberto pelo plano, a regra passa a confirmada com Fonte plano:<arquivo>:<linha>; não coberto, o orquestrador grava a decisão como N<n> e a regra passa a confirmada com Fonte delegado N<n>. -->

## Questões em aberto
- <dúvida surgida durante a execução — registrar data e quem resolveu>

## Divergências
- <spec × código, legado ou spec aprovada × proposta, com a pergunta do Questionário (`Q<n>`) e, depois do Gate 1, a resolução>
