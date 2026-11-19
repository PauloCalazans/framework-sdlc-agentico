---
name: intent
description: "Inicia a Fase 0 — captura uma ideia, ticket ou incidente como intent.md."
---
Siga `.claude/commands/intent.md` como orquestrador. Nele, `$ARGUMENTS` é o texto que o humano escreveu junto com o pedido, e despachar um papel é invocar o subagente de mesmo nome (Codex: `.codex/agents/<papel>.toml`; Antigravity: `.agents/agents/<papel>.md`).
No Windows, fora do Git Bash, rode os scripts do kit com `git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/<script>.sh` em vez de `sh agentic/mecanismos/scripts/<script>.sh`.
