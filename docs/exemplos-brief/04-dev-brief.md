Papel: dev
Contrato: /home/dev/loja/agentic/processo/papeis/dev.md
Perfil: /home/dev/loja/agentic/projeto/papeis/dev.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/tasks/001-criar.md — fase 4 (GREEN + REFACTOR)

## Escopo
Worktree: /home/dev/loja/agentic/.estado/worktrees/pedidos-001-criar (branch pedidos/001-criar). Escreva só em:
src/pedidos/criar_pedido.*, src/pedidos/desconto.*. Nunca toque em tests/. Outro arquivo: PARE e pergunte.

## O que fazer
- Faça passar o RED a1b2c3d (tests/pedidos/criar_pedido_test.*): CA-1 pedido vazio e CA-2 desconto que não acumula.
- Implementação mais simples que respeita o design (D2: o desconto é calculado em desconto.*, não no pedido).

## Já decidido
- Q1: desconto não acumula (humano:2026-11-06). R-1: o erro é código, não mensagem.

## Nunca faz
- Teste do RED parece errado: PARE e reporte `BLOQUEADO`; não contorne no código de produção.
- Nunca altere, apague ou desabilite teste do RED.
- Arquivo fora de `## Arquivos`: PARE e pergunte.
- Dependência nova: PARE e pergunte (é N3).

## Leia só isto
- tests/pedidos/criar_pedido_test.*:1-70 — o RED.
- agentic/projeto/specs/pedidos/design.md:20-45 — D1 a D3.

## Comandos
- `<CMD_TESTE_ARQUIVO> tests/pedidos/criar_pedido_test.* 2>&1 | tail -15` a cada passo.
- No fim, em primeiro plano: `sh agentic/mecanismos/scripts/verify.sh 2>&1 | tail -20` (VERIFY: OK).
- Proibido: tocar em tests/, ler código de dependência, git push.

## Teto
~60 requisições. Ao atingir: pare, comite o que estiver pronto e reporte onde travou.

## Entrega
- Commits (sem push): `feat(green): pedidos/001 — <assunto>`; `refactor: …` se houver.
- Relatório: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/04-dev-relatorio.md (SHAs, saída do verify, status).
- Retorno, uma linha: `04-dev: <FEITO|FEITO_COM_RESSALVAS|BLOQUEADO> | commits <shas> | verify <OK|FALHOU> | 04-dev-relatorio.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.
