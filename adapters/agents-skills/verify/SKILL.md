---
name: verify
description: "Roda a verificação completa do projeto e reporta. Nunca conserta."
---
Siga `.claude/commands/verify.md` como orquestrador. Nele, `$ARGUMENTS` é o texto que o humano escreveu junto com o pedido, e despachar um papel é invocar o subagente de mesmo nome (Codex: `.codex/agents/<papel>.toml`; Antigravity: `.agents/agents/<papel>.md`).
No Windows, fora do Git Bash, rode os scripts do kit com `git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/<script>.sh` em vez de `sh agentic/mecanismos/scripts/<script>.sh`.
