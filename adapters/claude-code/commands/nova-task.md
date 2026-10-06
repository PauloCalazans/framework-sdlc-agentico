---
description: Inicia a execução de uma task aprovada no Gate 1 (RED → GREEN → revisão → PR).
---
Task: $ARGUMENTS

1. Confira que a spec e o design da task estão com `**Status:** aprovado`. Se não, pare e diga o que falta.
2. Leia o `**Branch:**` da task e crie o worktree dentro do repositório: `git worktree add .agentic/worktrees/<nome> -b <branch>`, com `<nome>` = branch com `/` trocado por `-`.
3. Crie `.agentic/execucao/<AAAA-MM-DD>-<nome>/progress.md` com a task, o SHA base e o próximo passo.
4. Conduza as fases 3 a 6 de `docs/agentic/ciclo.md` como orquestrador: despache `testes`, depois `dev`, depois `revisor` (modo `diff`), sempre com caminhos absolutos do worktree no brief. Registre brief, relatório e Rulings no diretório de execução.
5. Se `.agentic/auto-mode` contém `enabled: true`, publique o PR sem pedir confirmação; caso contrário, pergunte antes do push. Nunca faça merge.
