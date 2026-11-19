#!/bin/sh
# Testes do verifica-artefato.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

S=agentic/projeto/specs/pedidos
M=agentic/projeto/specs/ajuste/tasks/001-ajuste.md

# prepara_spec: spec mínima válida num repositório novo; imprime o caminho.
prepara_spec() {
  r=$(tl_repo)
  mkdir -p "$r/$S/tasks" "$r/src/pedidos"
  cat > "$r/$S/spec.md" <<'EOT'
# Spec: pedidos

**Intent:** agentic/projeto/intent/001-pedidos.md
**Status:** draft

## Regras
| # | Regra | Fonte | Estado |
|---|---|---|---|
| R1 | Pedido nasce aberto | humano:2026-11-15 | confirmada |
| R2 | Pedido tem dono | humano:2026-11-15 | confirmada |

## Critérios de aceite
- CA1 (R1): dado um pedido novo, quando criado, então está aberto
- CA2 (R2): dado um pedido, quando criado, então tem dono

## Questionário de decisão
<!-- Resposta (Gate 1 delegado, D1): a — motivo -->
EOT
  cat > "$r/$S/design.md" <<'EOT'
# Design: pedidos

**Spec:** agentic/projeto/specs/pedidos/spec.md
**Status:** draft

## Decisões
1. Um módulo — **Por quê:** simples — **Verificado por:** por revisão

## Contrato executável
- O que é: criar_pedido
- Como se valida: `true`

## Tasks
| Task | Objetivo | Branch |
|---|---|---|
| tasks/001-criar.md | criar | pedidos/001-criar |

## Itens N3 (aprovação no Gate 1)
<!-- comentário -->
| # | Item | Gatilho | Decisão do humano |
|---|---|---|---|
| N3-1 | contrato público | contrato público | <aprovado em AAAA-MM-DD, ou recusado> |

## Impacto
- `src/pedidos/criar.py:3` ganha a função

## Como isso se prova
- CA1: teste de criação
- CA2: teste de dono

## O que não muda
- nada
EOT
  cat > "$r/$S/tasks/001-criar.md" <<'EOT'
# Task 001: criar

**Spec:** agentic/projeto/specs/pedidos/spec.md
**Status:** pendente
**Branch:** pedidos/001-criar

## Objetivo
criar pedido

## Arquivos
- `src/pedidos/*`

## Interfaces
- Produz: `criar_pedido(dados)`
- Consome: nada

## N3 aprovados no Gate 1
- Nenhum.

## Critérios de pronto
- CA1 e CA2
- `sh agentic/mecanismos/scripts/verify.sh` verde
EOT
  printf 'def criar_pedido(dados):\n    pass\n' > "$r/src/pedidos/criar.py"
  printf '%s\n' "$r"
}

# prepara_mudanca: documento enxuto mínimo e válido, na branch ajuste/001-ajuste.
prepara_mudanca() {
  r=$(tl_repo)
  git -C "$r" checkout -q -b ajuste/001-ajuste
  mkdir -p "$r/agentic/projeto/specs/ajuste/tasks" "$r/src"
  cat > "$r/$M" <<'EOT'
# Mudança: ajuste

**Status:** pendente
**Branch:** ajuste/001-ajuste
**Trilha:** enxuta
<!-- autoria -->

## Problema e resultado
algo

## Regras
| # | Regra | Fonte |
|---|---|---|
| R1 | regra | humano:2026-11-15 |

## Critérios de aceite
- CA1 (R1): dado x, quando y, então z

## Arquivos
- `src/ajuste.py`

## Contrato executável
- Não há.

## Itens N3 (aprovação no Gate 1)
| # | Item | Por que é só acréscimo | Decisão do humano |
|---|---|---|---|

## Decisões novas
- Nenhuma.

## Questionário
- Nenhuma.

## Questões em aberto
- Nenhuma.

## Rulings
- Nenhuma.
EOT
  printf '%s\n' "$r"
}

roda() { sh -c "cd '$r' && sh '$dir/verifica-artefato.sh' $*"; }
cfg() { printf '%s\n' "$1" >> "$r/agentic/config"; }
sub() { sed -i "$1" "$r/$2"; }  # sub <expressão sed> <arquivo relativo>

r=$(prepara_spec)
tl_espera 0 "spec válida passa" roda spec $S
tl_contem "verifica-artefato: OK (spec" "linha final de sucesso"

r=$(prepara_spec)
sub 's/^| R2 | .*/&\n| R3 | sem CA | humano:2026-11-15 | confirmada |/' $S/spec.md
tl_espera 1 "spec: regra sem CA bloqueia" roda spec $S
tl_contem "R3 sem critério de aceite" "nomeia a regra"

r=$(prepara_spec)
sub 's/^- CA2 (R2).*/&\n- CA9 (R9): dado, quando, então/' $S/spec.md
tl_espera 1 "spec: CA cita regra inexistente" roda spec $S
tl_contem "CA9 cita R9" "nomeia o CA"

r=$(prepara_spec)
sub 's/^| R1 | Pedido nasce aberto | humano:2026-11-15 |/| R1 | Pedido nasce aberto | Q2 |/' $S/spec.md
tl_espera 1 "spec: confirmada com fonte Q<n> bloqueia" roda spec $S
tl_contem "R1 confirmada com fonte Q2" "nomeia a regra"
r=$(prepara_spec)
sub 's/^## Questionário de decisão$/&\n1. Q1: pergunta? (a) (b)\n   Resposta (humano:2026-11-19): a — ok/' $S/spec.md
tl_espera 1 "spec: resposta no Questionário escrita fora de comentário" roda spec $S
tl_contem "corpo do commit do Gate 1" "diz onde a resposta fica"
r=$(prepara_spec)
tl_espera 0 "spec: resposta em comentário não conta" roda spec $S

r=$(prepara_spec)
tl_espera 0 "design válido passa" roda design $S
tl_contem "verifica-artefato: OK (design" "linha final de sucesso"

# checagem 1
r=$(prepara_spec)
sub 's/^- CA1 e CA2$/- CA1/' $S/tasks/001-criar.md
tl_espera 1 "design: CA sem task bloqueia" roda design $S
tl_contem "CA2 sem task" "nomeia o CA"
r=$(prepara_spec)
sub '/^- CA2: teste de dono$/d' $S/design.md
tl_espera 1 "design: CA fora de Como isso se prova" roda design $S
tl_contem "CA2 fora de 'Como isso se prova'" "nomeia o CA"

# checagem 2
r=$(prepara_spec)
sub 's|^- `src/pedidos/criar.py:3` ganha a função|&\n- `docs/inexistente.md` muda|' $S/design.md
tl_espera 1 "design: caminho citado inexistente" roda design $S
tl_contem "docs/inexistente.md" "nomeia o caminho"
r=$(prepara_spec)
sub 's|^- `src/pedidos/criar.py:3` ganha a função|&\n- `src/pedidos/novo.py` nasce|' $S/design.md
tl_espera 0 "design: caminho a criar dentro de ## Arquivos passa" roda design $S
r=$(prepara_spec)
sub 's|criar.py:3`|criar.py:12-30`|' $S/design.md
tl_espera 0 "sufixo :12-30 é ignorado na existência" roda design $S

# checagem 3
r=$(prepara_spec)
sub 's|^\*\*Branch:\*\* .*|**Branch:** feature/criar|' $S/tasks/001-criar.md
tl_espera 1 "design: branch fora do formato <spec>/NNN-" roda design $S
tl_contem "**Branch:**" "nomeia o campo"
r=$(prepara_spec)
cp "$r/$S/tasks/001-criar.md" "$r/$S/tasks/002-outra.md"
tl_espera 1 "design: duas tasks com a mesma branch" roda design $S
r=$(prepara_spec)
git -C "$r" checkout -q -b pedidos/001-x
tl_espera 1 "design: worktree pedidos/001-x e task 001 com outra branch" roda design $S

# checagem 4
r=$(prepara_spec)
sub 's/| <aprovado em AAAA-MM-DD, ou recusado> |/| aprovado em 2026-11-15 |/' $S/design.md
tl_espera 1 "design: Decisão do humano preenchida" roda design $S
tl_contem "Decisão do humano" "nomeia a coluna"
r=$(prepara_spec)
sub 's/^\*\*Status:\*\* draft/**Status:** aprovado/' $S/design.md
tl_espera 1 "design: Status diferente de draft" roda design $S

# checagem 5
r=$(prepara_spec)
mkdir -p "$r/agentic"; cfg 'CAMINHOS_N3="src/pedidos/*"'
tl_espera 1 "design: arquivo em CAMINHOS_N3 sem item N3 na task" roda design $S
tl_contem "CAMINHOS_N3" "explica a origem"
r=$(prepara_spec)
tl_espera 0 "design: sem CAMINHOS_N3 pula com aviso" roda design $S
tl_contem "aviso: CAMINHOS_N3" "avisa"
r=$(prepara_spec)
mkdir -p "$r/agentic"; cfg 'CAMINHOS_N3="src/pedidos/*"'
sub 's/^- Nenhum\.$/- N3-1 (design): contrato público/' $S/tasks/001-criar.md
tl_espera 0 "design: arquivo em CAMINHOS_N3 com item N3 passa" roda design $S

# checagem 6
r=$(prepara_spec)
printf 'def outra():\n    pass\n' > "$r/src/pedidos/criar.py"
tl_espera 1 "design: símbolo de Produz ausente do contrato" roda design $S
tl_contem "criar_pedido" "nomeia o símbolo"

# checagem 7
r=$(prepara_spec)
mkdir -p "$r/agentic"; cfg 'CMD_VALIDA_CONTRATO="echo quebrou; false"'
tl_espera 1 "design: CMD_VALIDA_CONTRATO falha" roda design $S
tl_contem "CMD_VALIDA_CONTRATO" "nomeia o comando"
tl_contem "quebrou" "mostra a saída do comando"
r=$(prepara_spec)
tl_espera 0 "design: sem CMD_VALIDA_CONTRATO pula com aviso" roda design $S
tl_contem "aviso: CMD_VALIDA_CONTRATO" "avisa"
r=$(prepara_spec)
mkdir -p "$r/agentic"; cfg 'CMD_VALIDA_CONTRATO="true"'
tl_espera 0 "design: CMD_VALIDA_CONTRATO verde passa" roda design $S

r=$(prepara_spec)
mkdir -p "$r/agentic"; cfg 'CMD_VALIDA_CONTRATO="ls src/pedidos/*.py >/dev/null"'
tl_espera 0 "design: CMD_VALIDA_CONTRATO com glob roda com globbing" roda design $S
r=$(prepara_spec)
mkdir -p "$r/agentic"; cfg 'CMD_VALIDA_CONTRATO="{{CMD_VALIDA_CONTRATO}}"'
tl_espera 0 "design: placeholder não preenchido conta como vazio" roda design $S
tl_contem "aviso: CMD_VALIDA_CONTRATO" "avisa"

# modo mudanca
r=$(prepara_mudanca)
tl_espera 0 "mudança válida passa" roda mudanca $M
tl_contem "verifica-artefato: OK (mudanca" "linha final de sucesso"
r=$(prepara_mudanca)
sub 's|^\*\*Branch:\*\* .*|**Branch:** outra/001-x|' $M
tl_espera 1 "mudança: Branch diferente da branch atual" roda mudanca $M
r=$(prepara_mudanca)
sub '/^## Rulings/,$ s/^- Nenhuma\./- R-1 (design): algo — por quê: x — descartado: y/' $M
tl_espera 1 "mudança: Rulings não vazia antes do Gate 1" roda mudanca $M
r=$(prepara_mudanca)
sub 's/^## Questionário$/&\n1. Q1: pergunta? opções (a) (b)\n   Resposta (humano:2026-11-15): a — ok/' $M
tl_espera 1 "mudança: resposta no Questionário escrita fora de comentário" roda mudanca $M
tl_contem "corpo do commit do Gate 1" "diz onde a resposta fica"
r=$(prepara_mudanca)
sub 's|`src/ajuste.py`|`src/api/novo.py`|' $M
mkdir -p "$r/agentic"; cfg 'CAMINHOS_N3="src/api/*"'
tl_espera 1 "mudança: arquivo em CAMINHOS_N3 com tabela N3 sem linha" roda mudanca $M
tl_contem "CAMINHOS_N3" "explica a origem"
r=$(prepara_mudanca)
sub 's/^- CA1 (R1).*/&\n- CA2 (R7): dado, quando, então/' $M
tl_espera 1 "mudança: CA cita regra inexistente" roda mudanca $M

r=$(prepara_mudanca)
sub 's|^## Contrato executável|## Impacto\n- `docs/inexistente.md` muda\n\n&|' $M
tl_espera 1 "mudança: Impacto cita caminho inexistente fora de Arquivos" roda mudanca $M
tl_contem "docs/inexistente.md" "nomeia o caminho"
r=$(prepara_mudanca)
sub 's|^## Contrato executável|## Impacto\n- `src/ajuste.py:4-9` muda\n\n&|' $M
tl_espera 0 "mudança: Impacto cita caminho dentro de Arquivos passa" roda mudanca $M

# citações com ::teste, #âncora, rota e {chave} não são caminhos do repositório
r=$(prepara_mudanca)
mkdir -p "$r/tests"; : > "$r/tests/test_criar.py"
sub 's|^## Contrato executável|## Impacto\n- `tests/test_criar.py::test_aberto` e `src/ajuste.py#L4` mudam; rota `/api/pedidos/{id}` e `src/{a,b}/x.py` são só texto\n\n\&|' $M
tl_espera 0 "mudança: ::teste, #âncora, rota e {chave} em Impacto não são caminhos faltando" roda mudanca $M
r=$(prepara_mudanca)
sub 's|^## Contrato executável|## Impacto\n- `tests/test_nao_existe.py::test_x` muda\n\n\&|' $M
tl_espera 1 "mudança: ::teste de arquivo inexistente continua bloqueando" roda mudanca $M
tl_contem "tests/test_nao_existe.py" "nomeia o arquivo sem o ::teste"

# mudança montada com Questões/Rulings do texto REAL do template passa a verificação 4
r=$(prepara_mudanca)
sed '/^## Questões em aberto/,$d' "$r/$M" > "$r/novo.md"
sed -n '/^## Questões em aberto/,$p' "$dir/../../core/templates/mudanca.md" >> "$r/novo.md"
mv "$r/novo.md" "$r/$M"
tl_espera 0 "mudança com Questões/Rulings do template real passa" roda mudanca $M
# cópia antiga do template: linha só de <placeholders> conta como vazia
r=$(prepara_mudanca)
sub '/^## Rulings/,$ s/^- Nenhuma\./- R-1 (<fase>): <o quê> — por quê: <…> — descartado: <alternativa>/' $M
tl_espera 0 "mudança: linha só de <placeholders> em Rulings conta como vazia" roda mudanca $M
# Review Focus 1–3
r=$(prepara_spec)
for f in spec.md design.md tasks/001-criar.md; do sed 's/$/\r/' "$r/$S/$f" > "$r/$S/$f.crlf" && mv "$r/$S/$f.crlf" "$r/$S/$f"; done
tl_espera 0 "artefatos com CRLF passam igual" roda design $S
r=$(prepara_spec)
sub 's|^## O que não muda|<!-- CA7 (R7) `docs/x/y.md` -->\n<!--\nCA8 (R8) `docs/z/w.md`\n-->\n&|' $S/design.md
tl_espera 0 "comentários do template não contam" roda design $S
r=$(prepara_spec)
tl_espera 2 "modo desconhecido é erro de uso" roda outro x
r=$(prepara_spec)
sub 's/^- CA2 (R2).*/&\n- CA9 (R9): dado, quando, então/' $S/spec.md
sub 's/^| R2 | .*/&\n| R3 | sem CA | humano:2026-11-15 | confirmada |/' $S/spec.md
tl_espera 1 "acumula as falhas antes de sair" roda spec $S
tl_contem "BLOQUEADO (2 falha(s))" "conta as falhas"

tl_fim
