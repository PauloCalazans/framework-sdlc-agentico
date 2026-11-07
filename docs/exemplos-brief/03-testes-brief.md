Papel: testes
Contrato: /home/dev/loja/agentic/processo/papeis/testes.md
Perfil: /home/dev/loja/agentic/projeto/papeis/testes.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/tasks/001-criar.md — fase 3 (RED)

## Escopo
Worktree: /home/dev/loja/agentic/.estado/worktrees/pedidos-001-criar (branch pedidos/001-criar). Escreva só em:
tests/pedidos/criar_pedido_test.* e no documento da task. Nunca toque em src/. Outro arquivo: PARE e pergunte.

## O que fazer
- CA-1: pedido sem item é recusado com o erro PEDIDO_VAZIO.
- CA-2: desconto não acumula: com dois cupons, vale o maior.
- Cada teste falha hoje pelo motivo certo (asserção, não erro de compilação).

## Já decidido
- Q1: desconto não acumula (humano:2026-11-06). R-1: o erro é código, não mensagem.

## Nunca faz
- Escreva só nos diretórios de teste (e no documento da task); nunca em código de produção.
- Antes do commit, rode o comando do brief e confira que cada teste falha pelo motivo certo.
- Teste que passaria com qualquer implementação não vale: reescreva.
- Critério de aceite que não dá para testar como está escrito: PARE e reporte `BLOQUEADO` com a pergunta.
- Reaproveite as fixtures de tests/pedidos/fixtures/; não crie dados redundantes.

## Leia só isto
- src/pedidos/criar_pedido.*:1-30 — o contrato executável (esqueleto).
- tests/clientes/cadastrar_cliente_test.*:1-40 — modelo de setup e de um teste.

## Comandos
- O comando de teste por arquivo do AGENTS.md: `<CMD_TESTE_ARQUIVO> tests/pedidos/criar_pedido_test.* 2>&1 | tail -15`.
- Quem roda o verifica-red.sh: o orquestrador. Não o rode.
- Proibido: tocar em src/, rodar o verify.sh, ler código de dependência, git push.

## Teto
~50 requisições. Ao atingir: pare, comite o que estiver pronto e reporte onde travou.

## Entrega
- Commits (sem push): `test(red): pedidos/001 — pedido vazio recusado e desconto que não acumula`.
- Relatório: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/03-testes-relatorio.md (SHA, saída da falha, mapa CA → teste).
- Retorno, uma linha: `03-testes: <FEITO|BLOQUEADO> | commit <sha> | falham <n> (motivo) | 03-testes-relatorio.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.
