# Origem de cada regra

Cada regra do núcleo aponta para a fonte que a justifica. Siglas das referências teóricas: **[AG]** AGENTS.md · **[QG]** Continuous Quality Gates for Agentic PRs · **[BR]** Bridging AI Agents and CI/CD Quality Gates · **[CI]** Capture as intent.md (Claude Academy) · **[RG]** Repository Guardrails for AI-Generated Code · **[FC]** Framework Corporativo de SDLC com IA (gerado por IA — proposta, não prática validada) · **[RR]** Research report SDLC agêntico.

| Regra (onde vive) | Fonte |
|---|---|
| P1 Prompt orienta, mecanismo controla (`principios.md`) | [RG] "prompts são orientação"; prática: projeto de referência controlado (subagente executou varredura de disco por ~7h apesar da regra em prosa) |
| P2 Erro 2x vira mecanismo (`principios.md`) | prática: projeto de referência controlado (ciclo do agente; erro repetido virou mecanismo) |
| P3 Estado derivado (`principios.md`, `status-projeto.sh`) | prática: projeto de referência controlado (script de status derivado; decisão de espera humana); prática: projeto de referência enxuto: contagens escritas à mão envelheceram |
| P4 Medido × inferido (`principios.md`) | prática: projeto de referência enxuto (conhecimento de protocolo marcado "medido"/"inferido") |
| P5 Agente não integra nem altera permissões (`principios.md`, `settings.json.tmpl`) | prática: projeto de referência controlado (classificador recusou ampliação de permissões); [QG] revisão humana final |
| P6 Memória enxuta (`principios.md`) | prática: projeto de referência enxuto: arquivo de memória de 110 KB com estado duplicado; [FC]/[RR] context bloat |
| P7 Erros pequenos, visíveis e reversíveis (`principios.md`) | [RG] workspace isolado e princípio-síntese |
| intent.md e suas seções (`templates/intent.md`) | [CI]; [FC] §20.1 |
| AGENTS.md como README para agentes (`templates/AGENTS.md`) | [AG]; [FC] §20.2 |
| Spec com Fonte e estado por regra; questionário de decisão (`papeis/dominio.md`, `templates/spec.md`) | prática: projeto de referência controlado (papel de domínio; decisão de espera humana) |
| Contrato executável antes do RED (`papeis/arquiteto.md`) | prática: projeto de referência controlado (papel de arquiteto) |
| Arquiteto dono único das tasks (`papeis/arquiteto.md`) | prática: projeto de referência controlado |
| Revisor separado, contexto limpo, nunca corrige, 3 modos (`papeis/revisor.md`) | [RG] separação autor/revisor; prática: projeto de referência controlado (reestruturação); prática: projeto de referência enxuto (revisão por diff) |
| Revisor sem Write/Edit (`agents/revisor.md`) | proposta nossa — reduz (não garante: o revisor tem Bash) a chance de corrigir; "nunca corrige" segue verificado por revisão |
| Achados Crítico/Importante/Menor; menores para revisão final (`ciclo.md`) | prática: projeto de referência enxuto (findings parked para revisão final) |
| Dois gates humanos (`ciclo.md`) | prática: projeto de referência controlado (espera humana dominava o ciclo); [CI] aprovação do intent |
| Escalonamento N3 (`ciclo.md`) | prática: projeto de referência controlado (N3); [FC] níveis de risco N1–N4; [QG] auth/pagamentos/cripto exigem humano |
| Trilha rápida (`ciclo.md`) | prática: projeto de referência controlado (ciclo do agente) |
| Trilha enxuta (`ciclo.md`, `templates/mudanca.md`, `/mudanca`) | validação v1 (ciclo real: 326 linhas de docs para uma faixa de desconto); prática: projeto de referência controlado (reestruturação: cerimônia > código). Proposta nossa, validada parcialmente |
| Escopo de arquivos declarado e verificado (`verifica-escopo.sh`) | [RG] expansão de escopo plausível; [RR] escopo delimitado; decisão desta spec (sem limite de linhas) |
| Commit `test(red):` provado em worktree, por arquivo quando há `CMD_TESTE_ARQUIVO`; asserções comparadas por arquivo (`verifica-red.sh`) | prática: projeto de referência controlado (script de verificação do RED); [FC]/[RR] test tampering. Isenção de `docs/` e `agentic/projeto/intent/` no RED: projeto de referência controlado (32 dos últimos 40 commits RED também editam o documento da task). Prova e comparação por arquivo: parecer sobre o projeto de referência (suíte inteira aceitava qualquer falha; soma global de asserções escondia asserção movida entre arquivos e bloqueava refactor de teste antigo) |
| Skips lidos do relatório real (`verifica-skip.sh`) | prática: projeto de referência controlado (verificação de skips) |
| `verify` ponto único, só reporta, com lock (`verify.sh`, `/verify`) | prática: projeto de referência enxuto (`/verify`: "reportar é o trabalho"); prática: projeto de referência controlado (`verify.sh` com lock) |
| Segredos em duas camadas, fail-closed, staged (`pre-commit`) | prática: projeto de referência controlado (gitleaks não pega senha genérica); [RG] varrer staged, fail-closed. Camada 2 com valor sem aspas, chave hifenizada e placeholders: projeto de referência controlado (YAML, env e properties com senha literal sem aspas passavam; `${DB_PASSWORD}` era bloqueado) |
| Proteção de branch e force-push em hooks nativos (`agentic/mecanismos/githooks`) | prática: projeto de referência controlado (15→20 bypasses no parser de comandos) |
| PreToolUse mínimo, só varredura de disco (`pre-tool-use.sh`) | prática: projeto de referência controlado (varredura de disco); reestruturação: parser redundante com `agentic/mecanismos/githooks` |
| Registro de execução, Rulings, roteamento de modelo (`ciclo.md` — Orquestração) | prática: projeto de referência enxuto (registro de execução do ciclo SDD) |
| Worktree por sessão (`ciclo.md`) | prática: projeto de referência controlado; [RG] |
| Modo automático versionado, nunca mergeia (`auto-mode`) | prática: projeto de referência controlado (auto-mode versionado) |
| Merge sem squash (`ciclo.md`, `templates/pr.md`) | prática: projeto de referência controlado (preserva evidência RED/GREEN) |
| Registro de decisões com Verificado por e revogadas (`templates/decisoes.md`) | prática: projeto de referência controlado (registro de decisões D1–D10; controle afirmado e inexistente) |
| Integridade do registro de decisões (`verifica-decisoes.sh`) | prática: segundo projeto de referência (decisão D11 perdida na resolução de conflito de um merge; `verify` passava com as referências órfãs). Proposta nossa, validada na história desse projeto |
| CI só depois de provado verde (`entrevista.md`) | prática: projeto de referência controlado (CI declarado e nunca verde) |
| Plugin de processo desligado (`settings.json.tmpl`, `CLAUDE.md`) | prática: projeto de referência controlado (plugin de processo sobrescrevendo convenções) |
| Contratos portáveis + adaptador fino (`core/papeis/`, `adapters/`) | prática: projeto de referência controlado (contratos de papéis + adaptadores); [AG] |
| Oráculo somente leitura com `arquivo:linha` (`papeis/_oraculo.md`) | prática: projeto de referência enxuto e prática: projeto de referência controlado (oráculos de referência somente leitura) |
| Settings ativado pelo humano (`ativar-protecoes.sh`) | proposta nossa — decorre de P5 |
| Questionário de bootstrap (`entrevista.md`) | proposta nossa — nenhuma fonte propõe; derivado de [AG], [CI], [RG] |
| Baseline de legado (`entrevista.md`, `agentic/baseline-skips`) | [RG] baseline do legado, bloquear só violações novas |
| Interfaces incidente→intent e release (`ciclo.md`) | [CI] Maintain; [FC] G5 |
| Registro do Gate 1 como 1º commit da branch (`ciclo.md`) | validação v1 (ciclo real na trilha padrão; principal protegida) |
| Itens N3 pré-aprovados no Gate 1 (design.md, task.md, ciclo.md) | prática: projeto de referência controlado (D8: paradas N3 no meio da task vinham de itens visíveis no design) |
