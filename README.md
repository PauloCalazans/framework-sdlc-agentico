# Framework de SDLC Agêntico

Referência reutilizável de SDLC agêntico: papéis de agentes, artefatos, gates e mecanismos de controle para desenvolver **qualquer tipo de software** com IA. Contém apenas a estrutura agêntica — nunca código de produto.

## Início rápido

1. `sh bootstrap/instalar.sh <caminho-do-projeto>` — copia o kit (não pergunta nada, não sobrescreve edição do projeto; arquivo do kit intacto é atualizado pelo manifesto). Com `--copilot`, acrescenta o adaptador do GitHub Copilot em `.github/` (veja `docs/portabilidade.md`).
2. No projeto, abra o Claude Code e rode `/bootstrap` — entrevista sobre contexto e stack; preenche os perfis dos papéis e instancia os controles.
3. Ative as proteções (ação humana): `sh agentic/mecanismos/scripts/ativar-protecoes.sh`.
4. Comece pelo primeiro intent: `/intent` (ou `/mudanca <descrição>` para uma mudança pequena).

No Windows, rode os comandos `sh ...` no Git Bash (o PowerShell não tem `sh`); dentro do Claude Code isso já é tratado.

## Enriqueça os perfis dos papéis

O contrato diz o que o papel faz e nunca faz; o perfil (`agentic/projeto/papeis/<papel>.md`) diz como fazer neste projeto. Sem perfil preenchido, o papel é genérico. O `/bootstrap` cria a primeira versão; o kit nunca a sobrescreve.

- **Especialização concreta:** "dev full-stack CAP TypeScript e Fiori elements", não "desenvolvedor".
- **Fatos conferidos no código:** caminhos, entidades, papéis de segurança, comandos e decisões (`D<n>`) que o papel aplica. Fato errado é pior que fato ausente.
- **Proibições do projeto:** só acréscimos ao "Nunca faz" do contrato.
- **Curto:** 30 a 40 linhas; texto longo vai para um documento do projeto, citado em "Leia sob demanda".
- **Erro repetido vira checagem** no `CMD_VERIFY_STACK` (princípio 2).

Atualize o perfil quando o revisor devolver duas vezes pelo mesmo motivo de stack ou quando uma decisão nova mudar o trabalho do papel.

## O que é instalado no projeto

Na raiz entra só o que as ferramentas exigem lá; todo o resto fica em `agentic/`:

```
AGENTS.md              mapa e regras para qualquer agente
CLAUDE.md              ponte mínima para o Claude Code
.claude/               agentes, comandos, hooks e settings.json (proteções)
agentic/
  config, auto-mode    política da instância (só o humano edita)
  processo/            do kit: princípios, ciclo, entrevista, contratos dos papéis, templates, .kit-manifesto
  mecanismos/          do kit: githooks/ (core.hooksPath) e scripts/
  projeto/             do projeto: papeis/ (perfis), bootstrap.md, decisoes.md, intent/, specs/
  .estado/             efêmero, ignorado pelo git: execução, worktrees, conflitos
```

Mais uma linha em `.gitignore` (`agentic/.estado/`) e em `.gitattributes` (LF nos scripts).

## Estrutura do framework

| Pasta | Conteúdo |
|---|---|
| `core/` | Neutro: princípios, ciclo, contratos de papéis, templates de artefatos |
| `mecanismos/` | Controle determinístico: githooks e scripts `sh`, cada um com testes |
| `adapters/claude-code/` | Adaptador fino para Claude Code: agentes, comandos, hooks, settings |
| `adapters/copilot/` | Adaptador fino para GitHub Copilot (opcional, `--copilot`): instruções, agentes, prompts, setup do agente de nuvem |
| `bootstrap/` | Instalador, entrevista, checagem estrutural |
| `exemplos/` | Projetos usados para validar o agnosticismo |
| `docs/` | Spec, plano, validação, portabilidade entre ferramentas |

## Verificação do framework

`sh scripts/verify.sh` — roda todas as suítes de teste dos mecanismos.

Design completo: `docs/specs/2026-10-05-framework-sdlc-agentico-design.md`.
