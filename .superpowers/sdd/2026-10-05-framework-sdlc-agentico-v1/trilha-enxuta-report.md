# Relatório — Trilha enxuta
Implementado conforme trilha-enxuta-brief.md: core/templates/mudanca.md, comando /mudanca, seção "Trilha enxuta" e remoção de worktree em ciclo.md, "Modo enxuto" no arquiteto, elegibilidade no revisor (modo diff), nova-task passo 6, Git Bash no README e AGENTS.md, instalar.Tests.sh (mudanca.md + commands/mudanca.md), origem.md, validacao-v1.md seção 5/7.
TDD: RED `sh mecanismos/scripts/verify.Tests.sh` -> "17 testes, 3 falhas" (template ausente). GREEN após criar o template -> "17 testes, 0 falhas". `sh scripts/verify.sh` -> verify: OK.
Teste novo (verify.Tests.sh): copia o template real (sed nos campos <...>) para docs/specs/desc/tasks/001-desc.md; verify acha pela **Branch:**, escopo OK; arquivo fora de ## Arquivos -> exit 1.
Notas: não existe seção "Trilha rápida" em ciclo.md (só bullet), então a seção enxuta fica após "Trilha padrão"/antes de "Escalonamento N3". Trailer usado: o do system-reminder (Sonnet 5.5), não o das instruções genéricas.
Preocupação: /mudanca não marca Status aprovado (vocabulário de task não tem); a aprovação do Gate 1 fica na conversa.

## Fix round 1
- /mudanca: após Gate 1, branch+worktree, documento commitado como 1o commit `docs(mudanca): <nome> aprovada (Gate 1)`; ciclo.md ganhou "Registro do Gate 1"; nova-task passo 1 confere esse commit para trilha enxuta.
- `integrada` deixa de ser Status escrito (task.md, mudanca.md, ciclo.md isolamento e :60, nova-task passo 6; -d recusando -> atualizar principal local, nunca -D).
- revisor.md cita gatilhos da stack; validacao-v1.md seção 5/7 com rótulos relatado/medido.
- Teste: verify.Tests.sh, branch sem task correspondente -> aviso "nenhuma task com **Branch:**" (tl_contem). Nota: o teste usa uma branch cuja **Branch:** não casa (o doc existe mas não pertence à branch), equivalente para o verify.
- Saída: `sh mecanismos/scripts/verify.Tests.sh` -> 19 testes, 0 falhas (ver abaixo); `sh scripts/verify.sh` -> verify: OK.
