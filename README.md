# Framework de SDLC Agêntico

Referência reutilizável de SDLC agêntico: papéis de agentes, artefatos, gates e mecanismos de controle para desenvolver **qualquer tipo de software** com IA. Contém apenas a estrutura agêntica — nunca código de produto.

## Início rápido

1. `sh bootstrap/instalar.sh <caminho-do-projeto>` — copia o kit (não pergunta nada, não sobrescreve nada).
2. No projeto, abra o Claude Code e rode `/bootstrap` — entrevista sobre contexto e stack; instancia agentes e controles.
3. Ative as proteções (ação humana): `sh agentic/mecanismos/scripts/ativar-protecoes.sh`.
4. Comece pelo primeiro intent: `/intent` (ou `/mudanca <descrição>` para uma mudança pequena).

No Windows, rode os comandos `sh ...` no Git Bash (o PowerShell não tem `sh`); dentro do Claude Code isso já é tratado.

## O que é instalado no projeto

Na raiz entra só o que as ferramentas exigem lá; todo o resto fica em `agentic/`:

```
AGENTS.md              mapa e regras para qualquer agente
CLAUDE.md              ponte mínima para o Claude Code
.claude/               agentes, comandos, hooks e settings.json (proteções)
agentic/
  config, auto-mode    política da instância (só o humano edita)
  processo/            do kit: princípios, ciclo, entrevista, papéis, templates
  mecanismos/          do kit: githooks/ (core.hooksPath) e scripts/
  projeto/             do projeto: bootstrap.md, decisoes.md, intent/, specs/
  .estado/             efêmero, ignorado pelo git: execução, worktrees, conflitos
```

Mais uma linha em `.gitignore` (`agentic/.estado/`) e em `.gitattributes` (LF nos scripts).

## Estrutura do framework

| Pasta | Conteúdo |
|---|---|
| `core/` | Neutro: princípios, ciclo, contratos de papéis, templates de artefatos |
| `mecanismos/` | Controle determinístico: githooks e scripts `sh`, cada um com testes |
| `adapters/claude-code/` | Adaptador fino para Claude Code: agentes, comandos, hooks, settings |
| `bootstrap/` | Instalador, entrevista, checagem estrutural |
| `exemplos/` | Projetos usados para validar o agnosticismo |
| `docs/` | Spec, plano, origem de cada regra, validação |

## Verificação do framework

`sh scripts/verify.sh` — roda todas as suítes de teste dos mecanismos.

Design completo: `docs/specs/2026-10-05-framework-sdlc-agentico-design.md`.
