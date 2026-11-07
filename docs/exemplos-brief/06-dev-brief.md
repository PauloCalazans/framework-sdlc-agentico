Papel: dev
Contrato: /home/dev/loja/agentic/processo/papeis/dev.md
Perfil: /home/dev/loja/agentic/projeto/papeis/dev.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/tasks/001-criar.md — fase 4 (GREEN, rodada 2)

## Escopo
Worktree: /home/dev/loja/agentic/.estado/worktrees/pedidos-001-criar (branch pedidos/001-criar). Escreva só em:
src/pedidos/criar_pedido.*, src/pedidos/desconto.*, src/pedidos/erros.*. Nunca toque em tests/. Outro arquivo: PARE e pergunte.

## O que fazer
- I1 do parecer 05: o desconto é calculado no pedido (criar_pedido.*:41), contra o D2; mova-o para desconto.*.
- M1 do parecer 05: o código de erro PEDIDO_VAZIO aparece como texto solto em dois lugares; use uma constante em src/pedidos/erros.*.
- O RED a1b2c3d continua passando, sem mudar teste nenhum.

## Já decidido
- Q1: desconto não acumula (humano:2026-11-06). R-1: o erro é código, não mensagem.

## Nunca faz
- Teste do RED parece errado: PARE e reporte `BLOQUEADO`; não contorne no código de produção.
- Nunca altere, apague ou desabilite teste do RED.
- Arquivo fora de `## Arquivos`: PARE e pergunte.
- Dependência nova: PARE e pergunte (é N3).

## Leia só isto
- src/pedidos/criar_pedido.*:30-55 — onde está o cálculo.
- agentic/projeto/specs/pedidos/design.md:28-36 — D2.

## Comandos
- `<CMD_TESTE_ARQUIVO> tests/pedidos/criar_pedido_test.* 2>&1 | tail -15` a cada passo.
- No fim, em primeiro plano: `sh agentic/mecanismos/scripts/verify.sh 2>&1 | tail -20` (VERIFY: OK).
- Proibido: tocar em tests/, ler código de dependência, git push.

## Teto
~40 requisições. Ao atingir: pare, comite o que estiver pronto e reporte onde travou.

## Entrega
- Commits (sem push): `refactor: pedidos/001 — desconto em desconto.* (I1)`; `refactor: pedidos/001 — código de erro em constante (M1)`.
- Relatório: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/06-dev-relatorio.md
- Retorno, uma linha: `06-dev: <FEITO|FEITO_COM_RESSALVAS|BLOQUEADO> | commits <shas> | verify <OK|FALHOU> | 06-dev-relatorio.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.

## Desde a rodada anterior
- Brief anterior: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/04-dev-brief.md (GREEN d4e5f6a).
- Motivo: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/05-revisor-diff-parecer.md, achados I1 e M1 (DEVOLVIDO).
- Mudou: "O que fazer", "Leia só isto", o teto, os commits e o escopo (+ src/pedidos/erros.*, já em `## Arquivos` da task). "Nunca faz" e comandos são os do 04.
