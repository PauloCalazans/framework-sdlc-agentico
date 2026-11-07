Papel: revisor — modo diff
Contrato: /home/dev/loja/agentic/processo/papeis/revisor.md
Perfil: /home/dev/loja/agentic/projeto/papeis/revisor.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/tasks/001-criar.md — fase 5 (confirmação, rodada 2)

## Escopo
Worktree: /home/dev/loja/agentic/.estado/worktrees/pedidos-001-criar (branch pedidos/001-criar). Você só lê, e só
escreve o parecer, fora do worktree. Não corrige e não comita.

## O que fazer
- Para cada achado do parecer 05 (I1, M1): corrigido, não corrigido ou parcial, com `arquivo:linha` do HEAD.
- Revise o intervalo novo d4e5f6a..b7c8d9e: nada além do que I1 e M1 pediam, e o RED a1b2c3d intacto.

## Já decidido
- Q1: desconto não acumula (humano:2026-11-06). R-1: o erro é código, não mensagem.

## Nunca faz
- Escreva só o parecer, no caminho do brief, fora do worktree; não corrija nada.
- Abra cada citação e rode a verificação você mesmo, em primeiro plano, antes de aprovar.
- Nunca revise o que você mesmo produziu.

## Leia só isto
- /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/05-revisor-diff-parecer.md — seção "Achados".
- `git diff d4e5f6a b7c8d9e -- src/pedidos/`

## Comandos
- `sh agentic/mecanismos/scripts/verify.sh 2>&1 | tail -20`, em primeiro plano: a verificação é sua.
- Proibido: alterar qualquer arquivo além do parecer, git commit, git push, ler código de dependência.

## Teto
~25 requisições. Ao atingir: grave o parecer com o que conferiu e marque o que não conferiu.

## Entrega
- Commits: nenhum.
- Parecer: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/07-revisor-diff-parecer.md, pelo template, com "Rodada anterior".
- Retorno, uma linha: `07-revisor-diff: <APROVADO|DEVOLVIDO> | C n I n M n | 07-revisor-diff-parecer.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.

## Desde a rodada anterior
- Brief anterior: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/05-revisor-diff-brief.md.
- Parecer anterior: 05-revisor-diff-parecer.md (DEVOLVIDO: I1, M1). Correção: 06-dev, commits b1a2c3d e b7c8d9e.
- Mudou: "O que fazer", "Leia só isto", o intervalo e o teto.
