Papel: arquiteto
Contrato: /home/dev/loja/agentic/processo/papeis/arquiteto.md
Perfil: /home/dev/loja/agentic/projeto/papeis/arquiteto.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/spec.md — fase 2 (design)

## Escopo
Árvore principal /home/dev/loja (branch main, sem commit até o Gate 1). Escreva só em: agentic/projeto/specs/pedidos/
(design.md e tasks/) e no esqueleto do contrato executável em src/pedidos/. Outro arquivo: PARE e pergunte.

## O que fazer
- design.md com decisões numeradas, "o que não muda" e "Itens N3 (aprovação no Gate 1)".
- Contrato executável em src/pedidos/ (interfaces e tipos, só esqueleto), validado com o build do AGENTS.md.
- Tasks em tasks/NNN-<nome>.md, cada uma com `**Branch:**`, `## Arquivos` e critérios de pronto.

## Já decidido
- Q1 do questionário: desconto não acumula (humano:2026-11-06).

## Nunca faz
- Nada além do contrato executável: esqueleto que compila, sem lógica de produção.
- Regra de negócio divergente: PARE e transforme em pergunta; nunca altere a spec.
- Nunca escreva aprovação de gate, resposta do humano nem Ruling.

## Leia só isto
- agentic/projeto/specs/pedidos/spec.md:1-90 — regras e critérios de aceite.
- agentic/projeto/decisoes.md:1-40 — decisões vigentes.

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
