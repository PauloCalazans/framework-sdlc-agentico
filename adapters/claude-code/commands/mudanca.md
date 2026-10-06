---
description: Mudança pequena de comportamento pela trilha enxuta (um documento → Gate 1 → RED → GREEN → revisão → PR).
---
Mudança: $ARGUMENTS

1. Despache o `arquiteto` em modo enxuto (`docs/agentic/papeis/arquiteto.md`, seção "Modo enxuto") com a descrição acima. Se ele identificar gatilho N3 e recusar, pare e siga a trilha padrão (`/intent`).
2. Grave o documento em `docs/specs/<nome>/tasks/001-<nome>.md` a partir de `docs/agentic/templates/mudanca.md`.
3. Mostre o documento ao humano e peça aprovação (Gate 1). Sem hipóteses: toda regra chega `confirmada` e "Questões em aberto" vazio. Sem aprovação explícita, pare.
4. Prossiga como `/nova-task` (a aprovação do documento substitui a checagem de spec e design; worktree, `em-andamento`, fases RED → GREEN → revisão → publicação, Gate 2, remoção do worktree), lembrando o `revisor` em modo `diff` de conferir a elegibilidade da trilha enxuta (critério em `docs/agentic/ciclo.md`). Classificação errada ou gatilho N3 novo: pare e promova à trilha padrão, registrando uma Ruling.
