# Framework de SDLC Agêntico

Referência reutilizável de SDLC agêntico: papéis de agentes, artefatos, gates e mecanismos de controle para desenvolver **qualquer tipo de software** com IA. Contém apenas a estrutura agêntica — nunca código de produto.

## Início rápido

1. `sh bootstrap/instalar.sh <caminho-do-projeto>` — copia o kit (não pergunta nada, não sobrescreve edição do projeto; arquivo do kit intacto é atualizado pelo manifesto). Com `--copilot`, acrescenta o adaptador do GitHub Copilot em `.github/` (veja `docs/portabilidade.md`).
2. No projeto, abra o Claude Code e rode `/bootstrap` — entrevista sobre contexto e stack; preenche os perfis dos papéis e instancia os controles.
3. Ative as proteções (ação humana): `sh agentic/mecanismos/scripts/ativar-protecoes.sh`.
4. Comece pelo primeiro intent: `/intent` (ou `/mudanca <descrição>` para uma mudança pequena).

No Windows, rode os comandos `sh ...` no Git Bash (o PowerShell não tem `sh`); dentro do Claude Code isso já é tratado.

## Enriqueça os perfis dos papéis

Os contratos do kit dizem o que cada papel faz e nunca faz, mas são genéricos de propósito. Sem dados do projeto, o papel acerta o processo e erra a stack. Nas duas instâncias em que o kit foi usado, o que mais resolveu problema foi reforçar a persona de cada papel com a stack e os padrões do projeto.

Esse reforço vai em `agentic/projeto/papeis/<papel>.md`, um perfil por papel que o kit nunca sobrescreve. O `/bootstrap` cria a primeira versão. Depois, o perfil acompanha o projeto:
- **Especialização concreta:** "dev full-stack CAP TypeScript e Fiori elements", não "desenvolvedor".
- **Fatos do código, conferidos:** caminhos, nomes de entidade, papéis de segurança, comandos e decisões (`D<n>`) que o papel aplica. Persona com fato errado é pior que persona genérica. Na primeira migração, as personas citavam pastas, actions e papéis que não existiam no código.
- **Proibições do projeto:** só acréscimos ao "Nunca faz" do contrato.
- **Curto:** de 30 a 40 linhas. O perfil é lido a cada despacho. O texto longo fica num documento do projeto, citado em "Leia sob demanda".
- **Erro que se repete vira mecanismo:** padrão que já falhou duas vezes sai do perfil e vira checagem no `CMD_VERIFY_STACK` (princípio 2).

Atualize o perfil sempre que o revisor devolver duas vezes pelo mesmo motivo de stack. Atualize também quando uma decisão nova mudar o que o papel faz.

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
| `docs/` | Spec, plano, origem de cada regra, validação, portabilidade entre ferramentas |

## Verificação do framework

`sh scripts/verify.sh` — roda todas as suítes de teste dos mecanismos.

Design completo: `docs/specs/2026-10-05-framework-sdlc-agentico-design.md`.
