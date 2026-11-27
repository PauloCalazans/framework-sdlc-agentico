---
description: Inicia a Fase 0 — captura uma ideia, ticket ou incidente como intent.md.
---
Pedido: $ARGUMENTS

Você é o orquestrador. Crie o registro de execução em `agentic/.estado/execucao/<AAAA-MM-DD>-<nome>/`, na árvore principal (`agentic/processo/ciclo.md`, "Orquestração"), e despache o `dominio` com um brief montado por `agentic/processo/templates/brief.md`, com o pedido acima. Pedido que muda o modo de operação do sistema, ou que depende do que de fato o bloqueia hoje: consulte o oráculo antes deste despacho e cole a resposta no `## Impacto` do brief (`agentic/processo/ciclo.md`, "Oráculo"). As perguntas que ele devolver no relatório, você faz ao humano nesta sessão, grava cada resposta como `N<n>` no `progress.md` (`agentic/processo/ciclo.md`, "Resposta do humano") e a repassa pelo ID, com o texto, no brief seguinte (`agentic/processo/ciclo.md`, "Resposta do humano"); o `dominio` nunca conversa direto com o humano.

O `dominio` usa `agentic/processo/templates/intent.md` e grava `agentic/projeto/intent/NNN-<nome>.md` com `**Status:** draft` (NNN = próximo número livre em `agentic/projeto/intent/`). Ao final, mostre o caminho e pergunte se pode seguir à especificação; isso não aprova o intent, que é aprovado no Gate 1 junto com spec e design (`agentic/processo/ciclo.md`). Com o Gate 1 delegado (`agentic/auto-mode` local com `enabled: true` e a spec em `gate1:`, `todas` ou pelo nome), siga à especificação sem perguntar; a aprovação do intent acontece no Gate 1 delegado.
