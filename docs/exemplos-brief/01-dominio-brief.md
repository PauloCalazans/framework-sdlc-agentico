Papel: dominio
Contrato: /home/dev/loja/agentic/processo/papeis/dominio.md
Perfil: /home/dev/loja/agentic/projeto/papeis/dominio.md
Task: /home/dev/loja/agentic/projeto/intent/003-pedidos.md — fase 1 (especificação)

## Escopo
Árvore principal /home/dev/loja (branch main, sem commit: a spec só é commitada no Gate 1). Escreva só em:
agentic/projeto/specs/pedidos/spec.md. Precisa de outro arquivo: PARE e pergunte pelo canal de dúvida.

## O que fazer
- spec.md a partir do intent 003, pelo template agentic/processo/templates/spec.md, cada regra com `Fonte:` e estado.
- Questionário de decisão no fim: toda `hipótese` vira pergunta com opções e a sua recomendação.

## Já decidido
- Pedido sem item é recusado (humano:2026-11-05, no intent).

## Nunca faz
- Regra vinda de oráculo: cite `arquivo:linha`.
- `hipótese` não vira `confirmada` sem fonte: sem fonte, vira pergunta do questionário.
- Nada de stack, arquitetura ou nome de classe: isso não é seu.
- Comportamento legado que parece errado: registre legado × proposta e leve ao questionário; não escolha.

## Leia só isto
- agentic/projeto/intent/003-pedidos.md:1-40 — o pedido do humano.
- legado/pedidos/regras.txt:10-60 — oráculo das regras de desconto em vigor.

## Comandos
- Busca só com pasta e saída limitada: `grep -n "<termo>" legado/pedidos/*.txt | head -20`.
- Proibido: busca recursiva sem pasta, leitura de arquivo inteiro fora da lista, git commit, git push.

## Teto
~30 requisições. Ao atingir: pare e reporte até onde chegou e o que falta.

## Entrega
- Commits: nenhum.
- Relatório: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/01-dominio-relatorio.md
- Retorno, uma linha: `01-dominio: <FEITO|BLOQUEADO> | confirmadas <n> hipóteses <n> perguntas <n> | 01-dominio-relatorio.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.
