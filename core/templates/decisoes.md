# Registro de decisões

Registro congelado: decisão nova vai em `agentic/projeto/decisoes/<slug>.md` (template `agentic/processo/templates/decisao.md`), citada como `D:<slug>`; o `verifica-decisoes.sh` bloqueia `### D<n>` nova aqui. As `D<n>` deste registro continuam valendo.

Cada decisão vale para o projeto inteiro até ser revogada. Nunca apague uma decisão: mova-a para "Decisões revogadas" com a data e o motivo (o `verifica-decisoes.sh` bloqueia decisão que some em relação à principal e referência `D<n>` sem decisão).

## Vigentes

### D1 — <título>
- **Decisão:** <…>
- **Por quê:** <…>
- **Consequência:** <…>
- **Verificado por:** <mecanismo | por revisão>
- **Data:** <AAAA-MM-DD>

## Decisões revogadas

<nenhuma>
