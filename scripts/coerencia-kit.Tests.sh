#!/bin/sh
# Coerência do kit: o texto de core/, adapters/ e docs/ não se contradiz (Princípio 2 aplicado ao próprio kit).
# Confere só estrutura, termos que não podem voltar, ferramentas dos adaptadores e formato dos exemplos;
# frases de conteúdo ficam para a revisão. Design: docs/specs/2026-11-06-brief-e-parecer-design.md.
dir=$(cd "$(dirname "$0")" && pwd)
raiz=$(cd "$dir/.." && pwd)
. "$raiz/mecanismos/scripts/testlib.sh"

# tem <arquivo relativo à raiz> <texto fixo>: o arquivo, sem \r, contém o texto.
tem() { [ -f "$raiz/$1" ] && tr -d '\r' < "$raiz/$1" | grep -qF -- "$2"; }
# linha <arquivo> <ERE>: alguma linha do arquivo, sem \r, casa a ERE.
linha() { [ -f "$raiz/$1" ] && tr -d '\r' < "$raiz/$1" | grep -qE -- "$2"; }
# nenhum <ERE> <caminhos...>: nenhum arquivo dos caminhos casa a ERE (sem distinção de maiúsculas); imprime as ocorrências.
nenhum() { tl_p=$1; shift; ! ( cd "$raiz" && grep -rniE -- "$tl_p" "$@" ); }
# ordem <arquivo> <texto A> <texto B>: a primeira linha com A vem antes da primeira linha com B.
ordem() {
  [ -f "$raiz/$1" ] || return 1
  tl_a=$(tr -d '\r' < "$raiz/$1" | grep -nF -- "$2" | head -n 1 | cut -d: -f1)
  tl_b=$(tr -d '\r' < "$raiz/$1" | grep -nF -- "$3" | head -n 1 | cut -d: -f1)
  [ -n "$tl_a" ] && [ -n "$tl_b" ] && [ "$tl_a" -lt "$tl_b" ]
}

# --- Task 1: template de brief; o kit não cita o projeto de referência nem comandos de stack no core/
b=core/templates/brief.md
for l in '^Papel: ' '^Contrato: ' '^Perfil: ' '^Task: '; do
  tl_espera 0 "brief: cabeçalho tem a linha $l" linha $b "$l"
done
for s in '## Escopo' '## O que fazer' '## Já decidido' '## Nunca faz' '## Leia só isto' \
         '## Comandos' '## Teto' '## Entrega' '## Desde a rodada anterior' '## Assinaturas' '## API externa'; do
  tl_espera 0 "brief: seção $s" tem $b "$s"
done
tl_espera 0 "brief: obrigatórias antes das condicionais" ordem $b '## Entrega' '## Desde a rodada anterior'
tl_espera 0 "brief: lista Antes de enviar" tem $b 'Antes de enviar'
tl_espera 0 "brief: lista Ao receber" tem $b 'Ao receber'
tl_espera 1 "brief: sem placeholder {{" tem $b '{{'
tl_espera 0 "kit sem nome do projeto de referência nem de ferramenta de orquestração" nenhum \
  'avitech|forja|lupa|esquadro|mocktail|worker_done|maestri|\borca\b' \
  core adapters bootstrap mecanismos README.md docs/portabilidade.md
tl_espera 0 "core/ sem comando de stack" nenhum 'select-object|maven|\bmvn\b|flutter' core

# --- Task 2: template de parecer, na escala do kit
p=core/templates/parecer.md
for s in '## Rodada anterior' '## Critérios de aceite' '## Achados' '## Verificação'; do
  tl_espera 0 "parecer: seção $s" tem $p "$s"
done
tl_espera 0 "parecer: ordem das seções" ordem $p '## Rodada anterior' '## Verificação'
tl_espera 1 "parecer: sem linha **Status:** (status-projeto não o lista)" linha $p '^\*\*Status:\*\*'
tl_espera 0 "kit sem escala alheia" nenhum 'REPROVADO|bloqueante' core adapters README.md

tl_fim
