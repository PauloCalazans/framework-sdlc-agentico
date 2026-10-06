# Origem de cada regra

Cada regra do núcleo aponta para a fonte que a justifica. Siglas do notebook (`c3b88221-73f7-46bf-b589-468ec5ecf249`): **[AG]** AGENTS.md · **[QG]** Continuous Quality Gates for Agentic PRs · **[BR]** Bridging AI Agents and CI/CD Quality Gates · **[CI]** Capture as intent.md (Claude Academy) · **[RG]** Repository Guardrails for AI-Generated Code · **[FC]** Framework Corporativo de SDLC com IA (gerado por IA — proposta, não prática validada) · **[RR]** Research report SDLC agêntico.

| Regra (onde vive) | Fonte |
|---|---|
| P1 Prompt orienta, mecanismo controla (`principios.md`) | [RG] "prompts são orientação"; avitech: subagente com `find /` órfão ~7h apesar da regra em prosa (`dfdb4e8`) |
| P2 Erro 2x vira mecanismo (`principios.md`) | avitech `docs/process/ciclo-do-agente.md`, commit `dfdb4e8` |
| P3 Estado derivado (`principios.md`, `status-projeto.sh`) | avitech `status-projeto.sh`, ADR 0009; abapmcp: contagens escritas à mão envelhecidas (`b531c45`, `1e5f217`) |
| P4 Medido × inferido (`principios.md`) | abapmcp `CLAUDE.md` (conhecimento de protocolo "medido"/"inferido") |
| P5 Agente não integra nem altera permissões (`principios.md`, `settings.json.tmpl`) | avitech ADR 0011 (classificador recusou ampliação de permissões); [QG] revisão humana final |
| P6 Memória enxuta (`principios.md`) | abapmcp: `CLAUDE.md` de 110 KB com estado duplicado; [FC]/[RR] context bloat |
| P7 Erros pequenos, visíveis e reversíveis (`principios.md`) | [RG] workspace isolado e princípio-síntese |
| intent.md e suas seções (`templates/intent.md`) | [CI]; [FC] §20.1 |
| AGENTS.md como README para agentes (`templates/AGENTS.md`) | [AG]; [FC] §20.2 |
| Spec com Fonte e estado por regra; questionário de decisão (`papeis/dominio.md`, `templates/spec.md`) | avitech `docs/agentes/dominio.md`, ADR 0009 |
| Contrato executável antes do RED (`papeis/arquiteto.md`) | avitech `docs/agentes/arquiteto.md` |
| Arquiteto dono único das tasks (`papeis/arquiteto.md`) | avitech `c34359f` |
| Revisor separado, contexto limpo, nunca corrige, 3 modos (`papeis/revisor.md`) | [RG] separação autor/revisor; avitech reestruturação `7098bd0`; abapmcp revisão por diff |
| Revisor sem Write/Edit (`agents/revisor.md`) | proposta nossa — reduz (não garante: o revisor tem Bash) a chance de corrigir; "nunca corrige" segue verificado por revisão |
| Achados Crítico/Importante/Menor; menores para revisão final (`ciclo.md`) | abapmcp SDD (findings parked, `0105617`) |
| Dois gates humanos (`ciclo.md`) | avitech ADR 0009 (espera humana dominava o ciclo); [CI] aprovação do intent |
| Escalonamento N3 (`ciclo.md`) | avitech N3; [FC] níveis de risco N1–N4; [QG] auth/pagamentos/cripto exigem humano |
| Trilha rápida (`ciclo.md`) | avitech `docs/process/ciclo-do-agente.md` |
| Escopo de arquivos declarado e verificado (`verifica-escopo.sh`) | [RG] expansão de escopo plausível; [RR] escopo delimitado; decisão desta spec (sem limite de linhas) |
| Commit `test(red):` provado em worktree; asserções comparadas (`verifica-red.sh`) | avitech `scripts/verifica-red.sh`; [FC]/[RR] test tampering |
| Skips lidos do relatório real (`verifica-skip.sh`) | avitech `verify-skip-check.sh` |
| `verify` ponto único, só reporta, com lock (`verify.sh`, `/verify`) | abapmcp `/verify` ("reportar é o trabalho"); avitech `verify.sh` com lock |
| Segredos em duas camadas, fail-closed, staged (`pre-commit`) | avitech `377d599` (gitleaks não pega senha genérica); [RG] varrer staged, fail-closed |
| Proteção de branch e force-push em hooks nativos (`.githooks`) | avitech task 008 (15→20 bypasses no parser de comandos) |
| PreToolUse mínimo, só varredura de disco (`pre-tool-use.sh`) | avitech `dfdb4e8`; reestruturação: parser redundante com `.githooks` |
| Registro de execução, Rulings, roteamento de modelo (`ciclo.md` — Orquestração) | abapmcp `.superpowers/sdd/` |
| Worktree por sessão (`ciclo.md`) | avitech `b69720c`, `c89aee0`; [RG] |
| Modo automático versionado, nunca mergeia (`auto-mode`) | avitech `.claude/auto-mode`, ADR 0011 |
| Merge sem squash (`ciclo.md`, `templates/pr.md`) | avitech (preserva evidência RED/GREEN) |
| Registro de decisões com Verificado por e revogadas (`templates/decisoes.md`) | avitech `docs/arquitetura.md` (D1–D10); ADR 0008 (controle afirmado e inexistente) |
| CI só depois de provado verde (`entrevista.md`) | avitech ADR 0008 |
| Plugin de processo desligado (`settings.json.tmpl`, `CLAUDE.md`) | avitech `a55db55`/`c7ca73a` (superpowers sobrescrevendo convenções) |
| Contratos portáveis + adaptador fino (`core/papeis/`, `adapters/`) | avitech `docs/agentes/` + `.claude/agents/`; [AG] |
| Oráculo somente leitura com `arquivo:linha` (`papeis/_oraculo.md`) | abapmcp `adt-reference`; avitech `legado-sisdan` |
| Settings ativado pelo humano (`ativar-protecoes.sh`) | proposta nossa — decorre de P5 |
| Questionário de bootstrap (`entrevista.md`) | proposta nossa — nenhuma fonte propõe; derivado de [AG], [CI], [RG] |
| Baseline de legado (`entrevista.md`, `.agentic/baseline-skips`) | [RG] baseline do legado, bloquear só violações novas |
| Interfaces incidente→intent e release (`ciclo.md`) | [CI] Maintain; [FC] G5 |
