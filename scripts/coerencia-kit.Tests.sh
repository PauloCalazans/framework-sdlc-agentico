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
  'mocktail|worker_done|maestri|\borca\b' \
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

# --- Task 3: seção "No brief" em cada contrato de papel
for papel in dominio arquiteto testes dev revisor; do
  c=core/papeis/$papel.md
  tl_espera 0 "$papel: tem ## No brief" tem $c '## No brief'
  tl_espera 0 "$papel: No brief antes de Ao terminar" ordem $c '## No brief' '## Ao terminar'
  tl_espera 0 "$papel: No brief com 3 a 5 itens" sh -c \
    "n=\$(tr -d '\r' < '$raiz/$c' | sed -n '/^## No brief/,/^## /p' | grep -c '^- '); [ \$n -ge 3 ] && [ \$n -le 5 ]"
  tl_espera 1 "$papel: sem placeholder {{ no contrato" sh -c "grep -q '{{' '$raiz/$c'"
done
for papel in dominio arquiteto testes dev; do
  tl_espera 0 "$papel: No brief depois de Independência" ordem core/papeis/$papel.md '## Independência' '## No brief'
done
tl_espera 0 "revisor: No brief depois de Nunca faz" ordem core/papeis/revisor.md '## Nunca faz' '## No brief'
tl_espera 1 "oráculo não ganha No brief" tem core/papeis/_oraculo.md '## No brief'

# --- Task 4: o revisor escreve só o parecer, em todo o kit
k='core adapters bootstrap mecanismos README.md docs/portabilidade.md'
# shellcheck disable=SC2086 # $k é lista de caminhos
tl_espera 0 "kit não descreve o revisor como sem escrita" nenhum \
  'sem ferramenta de escrita|não tem write/edit|omite write/edit|omite `edit`|negue escrita|editar arquivos\.|edita arquivo ou revisa|revisor. vem sem .edit' $k
tl_espera 0 "adapter Claude Code: revisor com Write" linha adapters/claude-code/agents/revisor.md '^tools: .*\bWrite\b'
tl_espera 1 "adapter Claude Code: revisor sem Edit" linha adapters/claude-code/agents/revisor.md '^tools: .*\bEdit\b'
tl_espera 0 "adapter Copilot: revisor com edit" linha adapters/copilot/agents/revisor.agent.md "^tools: .*'edit'"

# --- Task 5: a orquestração monta o brief pelo template
# shellcheck disable=SC2086 # $k é lista de caminhos
tl_espera 0 "kit sem task-N-brief/relatorio" nenhum 'task-N-(brief|relatorio)' $k

# --- Task 6: formato dos briefs e do parecer de exemplo
for f in "$raiz"/docs/exemplos-brief/*-brief.md; do
  [ -f "$f" ] || continue
  e=docs/exemplos-brief/$(basename "$f")
  tl_espera 0 "$e: primeira linha é Papel de um contrato do kit" sh -c \
    "p=\$(head -n1 '$f' | tr -d '\r' | sed -n 's/^Papel: \([a-z]*\).*/\1/p'); [ -n \"\$p\" ] && [ -f '$raiz/core/papeis/'\$p.md ]"
  tl_espera 0 "$e: contrato com caminho absoluto" linha $e '^Contrato: (/|[A-Za-z]:/)'
  tl_espera 0 "$e: perfil com caminho absoluto" linha $e '^Perfil: (/|[A-Za-z]:/)'
  for s in '## Escopo' '## O que fazer' '## Já decidido' '## Nunca faz' '## Leia só isto' '## Comandos' '## Teto' '## Entrega'; do
    tl_espera 0 "$e: seção $s" tem $e "$s"
  done
  tl_espera 0 "$e: teto com número" sh -c "tr -d '\r' < '$f' | sed -n '/^## Teto/,/^## /p' | grep -q '[0-9]'"
done
for e in docs/exemplos-brief/06-dev-brief.md docs/exemplos-brief/07-revisor-diff-brief.md; do
  tl_espera 0 "$e: correção traz Desde a rodada anterior" tem $e '## Desde a rodada anterior'
done
tl_espera 0 "parecer de confirmação: Rodada anterior" tem docs/exemplos-brief/07-revisor-diff-parecer.md '## Rodada anterior'
tl_espera 0 "exemplos sem nome de stack, de projeto de referência ou de ferramenta de orquestração" nenhum \
  'mocktail|worker_done|maestri|\borca\b|select-object|maven|\bmvn\b|flutter' docs/exemplos-brief

# --- Revisão final da branch (correções)
# Revisor: ao receber, HEAD igual ao SHA do brief no modo diff; estado igual ao anotado nos modos sem commit.
tl_espera 0 "brief: ao receber confere HEAD do revisor" tem core/templates/brief.md 'git rev-parse HEAD'
tl_espera 0 "brief: ao receber confere também os arquivos novos nos modos sem commit" tem core/templates/brief.md 'git ls-files -o --exclude-standard'
tl_espera 0 "revisor: Verificado por cita o HEAD" tem core/papeis/revisor.md 'git rev-parse HEAD'
tl_espera 0 "ciclo e modelos só apontam para a lista Ao receber do template" nenhum 'porcelain' core/processo
# Termos que não podem entrar no repositório versionado, mas que também não podem ser versionados
# (nomes do projeto de referência): lista local opcional, uma ERE por linha, em .superpowers/ (ignorado pelo git).
termos="$raiz/.superpowers/termos-locais.txt"
if [ -f "$termos" ]; then
  # git grep sai 1 quando não acha e >1 em erro: só o 1 passa (um erro não pode virar "sem ocorrências").
  tl_espera 1 "repositório versionado sem os termos locais" git -C "$raiz" grep -n -i -I -E -f "$termos"
fi
# Parecer copiado tem nome fixo por task, para não sobrescrever o de outra task da mesma spec.
tl_espera 0 "ciclo: nome fixo do parecer copiado" tem core/processo/ciclo.md 'pareceres/<NNN>-diff.md'
tl_espera 0 "nova-task: nome fixo do parecer copiado" tem adapters/claude-code/commands/nova-task.md 'pareceres/<NNN>-diff.md'
# Regras novas da Orquestração declaram Verificado por: (Princípio 1).
tl_espera 0 "ciclo: Verificado por depois das regras do brief" ordem core/processo/ciclo.md '- **parecer** —' '`Verificado por:` revisão (lista "Antes de enviar"'
tl_espera 0 "ciclo: Verificado por antes do item 3" ordem core/processo/ciclo.md '`Verificado por:` revisão (lista "Antes de enviar"' '3. despacha cada papel'
# No brief do testes mantém a ressalva do contrato (nenhuma regra nova).
tl_espera 0 "testes: No brief mantém a ressalva do símbolo ausente" sh -c \
  "tr -d '\r' < '$raiz/core/papeis/testes.md' | sed -n '/^## No brief/,/^## /p' | grep -q 'salvo quando a ausência do símbolo'"
# Exemplo de correção: o escopo cobre o arquivo que o parecer de confirmação aprova.
tl_espera 0 "06-dev: escopo inclui erros.*" sh -c \
  "tr -d '\r' < '$raiz/docs/exemplos-brief/06-dev-brief.md' | sed -n '/^## Escopo/,/^## /p' | grep -q 'src/pedidos/erros'"

tl_fim
