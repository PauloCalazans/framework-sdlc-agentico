# Exemplos de brief e de parecer

Briefs preenchidos pelo template `core/templates/brief.md` para um projeto fictício (`/home/dev/loja`, spec `pedidos`, task `001-criar`), um por papel, na ordem de despacho. Mostram a forma, não a stack: os comandos são os do kit e o "comando de teste por arquivo" do `AGENTS.md`.

| Arquivo | Papel | O que mostra |
|---|---|---|
| `01-dominio-brief.md` | `dominio` | spec a partir do intent, com questionário |
| `02-arquiteto-brief.md` | `arquiteto` | design, contrato executável e tasks |
| `03-testes-brief.md` | `testes` | RED; o `verifica-red.sh` fica com o orquestrador |
| `04-dev-brief.md` | `dev` | GREEN dentro do escopo |
| `05-revisor-diff-brief.md` | `revisor` | revisão do diff; o `verify.sh` é do revisor |
| `06-dev-brief.md` | `dev` | rodada de correção: cópia do 04 com "Desde a rodada anterior" |
| `07-revisor-diff-brief.md` | `revisor` | confirmação, achado a achado |
| `07-revisor-diff-parecer.md` | `revisor` | parecer de confirmação pelo template `core/templates/parecer.md` |

A suíte `scripts/coerencia-kit.Tests.sh` confere o formato de cada um.
