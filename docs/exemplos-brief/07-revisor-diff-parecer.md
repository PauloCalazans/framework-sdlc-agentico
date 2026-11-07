# Parecer — diff — pedidos/001-criar — rodada 2

**Veredito:** APROVADO · C 0 I 0 M 1
**Revisado:** d4e5f6a..b7c8d9e (correção do 06-dev sobre a GREEN d4e5f6a)
**Parecer anterior:** /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/05-revisor-diff-parecer.md

## Rodada anterior

| Achado anterior | Situação | Evidência no HEAD |
|---|---|---|
| I1 — desconto calculado no pedido, contra o D2 | corrigido | src/pedidos/desconto.*:12-30; criar_pedido.*:41 só chama `aplicar_desconto` (medido) |
| M1 — código de erro como texto solto | parcial | constante em src/pedidos/erros.*:3; ainda solto em criar_pedido.*:18 (medido) |

## Critérios de aceite

| CA | Teste | Status |
|---|---|---|
| CA-1 pedido vazio recusado | tests/pedidos/criar_pedido_test.*:12 | coberto (medido) |
| CA-2 desconto não acumula | tests/pedidos/criar_pedido_test.*:31 | coberto (medido) |

## Achados

| ID | Classe | Onde | Problema | Evidência |
|---|---|---|---|---|
| M2 | Menor | src/pedidos/criar_pedido.*:18 | resto do M1: troque o texto pela constante de erros.* | medido: `grep -n PEDIDO_VAZIO src/pedidos/*` mostra o texto em :18 |

O RED a1b2c3d está intacto: `git diff d4e5f6a b7c8d9e -- tests/` vazio (medido).

## Verificação
```
sh agentic/mecanismos/scripts/verify.sh 2>&1 | tail -3
-- escopo: OK

VERIFY: OK
```
