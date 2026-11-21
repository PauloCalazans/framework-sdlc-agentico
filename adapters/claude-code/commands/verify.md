---
description: Roda a verificação completa do projeto e reporta. Nunca conserta.
---
Rode `sh agentic/mecanismos/scripts/verify.sh $ARGUMENTS` e reporte a saída: etapas que passaram, etapas que falharam e as mensagens relevantes.

Não conserte nada neste comando — reportar é o trabalho. Aceita `--rapido` (nível do laço: stack rápida, sem `skip`); sem ele, é o completo. Nunca afirme sucesso sem ter visto `VERIFY: OK` (completo) ou `VERIFY RÁPIDO: OK` (`--rapido`) na saída. `VERIFY: OK (já provado nesta árvore)` é sucesso: a mesma árvore já passou pelo completo. Para ler uma etapa que a saída não mostrou, abra o log que ela aponta (`agentic/.estado/verify.log`) em vez de rodar o verify de novo.
