Papel: revisor — modo diff
Contrato: /home/dev/loja/agentic/processo/papeis/revisor.md
Perfil: /home/dev/loja/agentic/projeto/papeis/revisor.md
Task: /home/dev/loja/agentic/projeto/specs/pedidos/tasks/001-criar.md — fase 5 (revisão)

## Escopo
Worktree: /home/dev/loja/agentic/.estado/worktrees/pedidos-001-criar (branch pedidos/001-criar). Você só lê, e só
escreve o parecer, fora do worktree. Não corrige e não comita.

## O que fazer
- Revise o intervalo 9f8e7d6..d4e5f6a: RED a1b2c3d, GREEN d4e5f6a.
- Critério de aceite a critério de aceite: o teste prova o CA? Aderência ao design (D1 a D3), segurança, escopo.

## Já decidido
- Q1: desconto não acumula (humano:2026-11-06). R-1: o erro é código, não mensagem.

## Nunca faz
- Escreva só o parecer, no caminho do brief, fora do worktree; não corrija nada.
- Abra cada citação e rode a verificação você mesmo, em primeiro plano, antes de aprovar.
- Nunca revise o que você mesmo produziu.

## Leia só isto
- `git diff --stat 9f8e7d6 d4e5f6a`, depois `git diff 9f8e7d6 d4e5f6a -- <caminho>` arquivo a arquivo.
- agentic/projeto/specs/pedidos/spec.md:40-70 — CA-1 e CA-2.

## Comandos
- `sh agentic/mecanismos/scripts/verify.sh 2>&1 | tail -20`, em primeiro plano: a verificação é sua.
- Busca com saída limitada: `grep -n "<termo>" src/pedidos/* | head -20`.
- Proibido: alterar qualquer arquivo além do parecer, git commit, git push, ler código de dependência.

## Teto
~40 requisições. Ao atingir: grave o parecer com o que conferiu e marque o que não conferiu.

## Entrega
- Commits: nenhum.
- Parecer: /home/dev/loja/agentic/.estado/execucao/2026-11-06-pedidos/05-revisor-diff-parecer.md, pelo template agentic/processo/templates/parecer.md.
- Retorno, uma linha: `05-revisor-diff: <APROVADO|DEVOLVIDO> | C n I n M n | 05-revisor-diff-parecer.md`
- Dúvida que trava: pergunte ao orquestrador e espere a resposta.
