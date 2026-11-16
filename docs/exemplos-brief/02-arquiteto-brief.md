Papel: arquiteto
Contrato: /home/dev/loja/agentic/processo/papeis/arquiteto.md
Perfil: /home/dev/loja/agentic/projeto/papeis/arquiteto.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/spec.md — fase 2 (design)

## Escopo
Árvore principal /home/dev/loja (branch main, sem commit até o Gate 1). Escreva só em: agentic/projeto/specs/pedidos/
(design.md e tasks/) e no esqueleto do contrato executável em src/pedidos/. Outro arquivo: PARE e pergunte.

## O que fazer
- design.md com decisões numeradas, "o que não muda" e "Itens N3 (aprovação no Gate 1)".
- Contrato executável em src/pedidos/ (assinaturas e tipos, corpos no stub da stack), validado com o build do AGENTS.md,
  e a declaração de corpos no design (vazia ou com o porquê).
- Tasks em tasks/NNN-<nome>.md, cada uma com `**Branch:**`, `## Arquivos` e critérios de pronto.

## Já decidido
- Q1 do questionário: desconto não acumula (humano:2026-11-06).

## Nunca faz
- Contrato executável só com esqueleto: corpo com comportamento é o stub da stack; corpo que não é stub vai na declaração de corpos, com o porquê.
- Regra de negócio divergente: PARE e transforme em pergunta; nunca altere a spec.
- Nunca escreva aprovação de gate, resposta do humano nem Ruling.
- `## Impacto`: só das buscas do `## Impacto` e dos comandos do brief, cada linha conferida no trecho; busca que falta além dos comandos do brief: PARE e peça.

## Leia só isto
- agentic/projeto/specs/pedidos/spec.md:1-90 — regras e critérios de aceite.
- agentic/projeto/decisoes.md:1-40 — decisões vigentes.
- agentic/projeto/specs/cupons/spec.md:10-20 — R3, do `## Impacto`.

## Impacto
- `grep -rn "Pedido\|pedido" src tests | head -20` → sem resultado: nenhum chamador nem teste existente (o módulo é novo).
- `grep -n "desconto\|cupom" agentic/projeto/specs/*/spec.md | head -20` → `agentic/projeto/specs/cupons/spec.md:14: | R3 | Cupom vale só para cliente cadastrado | …`

## Comandos
- Validação do contrato: o comando de build do AGENTS.md, com `2>&1 | tail -15`. Rode uma vez no fim.
- Proibido: git commit, git push, criar branch, ler código de dependência.

## Teto
~40 requisições. Ao atingir: pare e reporte o que está pronto e o que falta.

## Entrega
- Commits: nenhum.
- Relatório: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/02-arquiteto-relatorio.md
- Retorno, uma linha: `02-arquiteto: <FEITO|BLOQUEADO> | contrato <valida|falha> | tasks <n> | N3 <n> | 02-arquiteto-relatorio.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.
