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
# sem_nomes_proibidos <caminhos...>: nenhum caminho cita um nome da lista local .nomes-proibidos (uma ERE por linha,
# fora do git: a lista não pode publicar os nomes que proíbe). Sem a lista, avisa e passa.
sem_nomes_proibidos() {
  [ -f "$raiz/.nomes-proibidos" ] || { echo "aviso: .nomes-proibidos ausente — nomes não conferidos"; return 0; }
  tr -d '' < "$raiz/.nomes-proibidos" | while IFS= read -r tl_n; do
    [ -n "$tl_n" ] || continue
    nenhum "$tl_n" "$@" || return 1
  done
}
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
tl_espera 0 "brief: cabeçalho ## Impacto" linha $b '^## Impacto$'
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
  tl_espera 0 "$e: cabeçalho ## Impacto" linha $e '^## Impacto$'
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

# --- Impacto no brief e rodada por artefato (avaliação dos templates, 2026-11-15)
# cab <arquivo> <cabeçalho>: número da primeira linha igual ao cabeçalho (linha inteira, sem \r).
cab() { tr -d '\r' < "$raiz/$1" | grep -nxF -- "$2" | head -n 1 | cut -d: -f1; }
# cab_entre <arquivo> <A> <B> <C>: os três cabeçalhos existem, nesta ordem.
cab_entre() {
  ce_a=$(cab "$1" "$2"); ce_b=$(cab "$1" "$3"); ce_c=$(cab "$1" "$4")
  [ -n "$ce_a" ] && [ -n "$ce_b" ] && [ -n "$ce_c" ] && [ "$ce_a" -lt "$ce_b" ] && [ "$ce_b" -lt "$ce_c" ]
}
tl_espera 0 "brief: cabeçalho ## Impacto entre Leia só isto e Comandos" cab_entre core/templates/brief.md '## Leia só isto' '## Impacto' '## Comandos'
for papel in dominio arquiteto testes dev revisor; do
  tl_espera 0 "$papel: consome o Impacto do brief" tem core/papeis/$papel.md '`## Impacto` do brief'
done
tl_espera 0 "parecer: rodada conta por artefato e nunca recomeça" tem core/templates/parecer.md 'nunca recomeça'
tl_espera 0 "ciclo: 3ª devolução contada em todos os pareceres do artefato" tem core/processo/ciclo.md 'a contagem nunca recomeça'
tl_espera 0 "ciclo: 3ª devolução é o 3º DEVOLVIDO" tem core/processo/ciclo.md 'o 3º parecer `DEVOLVIDO`'
tl_espera 0 "brief: revisor recebe rodada e parecer anterior em O que fazer" tem core/templates/brief.md 'No `revisor`, antes das entregas, uma linha a mais: `Rodada <k>'
for e in docs/exemplos-brief/05-revisor-diff-brief.md docs/exemplos-brief/07-revisor-diff-brief.md; do
  tl_espera 0 "$e: rodada e parecer anterior em O que fazer" linha $e '^- Rodada [0-9]+ do .*; parecer anterior: (não há|/)'
done
tl_espera 0 "ciclo: teste existente afetado sai depois do RED, por Emenda ou Ruling" tem core/processo/ciclo.md 'a asserção antiga sai depois dele'
tl_espera 0 "ciclo: verifica-red só confere arquivos tocados pelo RED" tem core/processo/ciclo.md 'só nos arquivos de teste tocados pelo RED'

# --- README acompanha o kit (conferência de 2026-11-15)
tl_espera 0 "README: padrão de stack repetido vira checagem, como no template de perfil" tem README.md 'sai do perfil e vira checagem no `CMD_VERIFY_STACK`'
tl_espera 1 "README: sem atualizar o perfil por devolução repetida" tem README.md 'Atualize o perfil quando o revisor devolver duas vezes'
tl_espera 0 "README: trilha padrão com revisão de spec e de design" tem README.md 'spec → revisão da spec → design → revisão do design → Gate 1'
tl_espera 0 "README: limite do verifica-red (arquivos tocados pelo RED)" tem README.md 'num arquivo de teste que o RED tocou'
tl_espera 0 "README: Impacto do dominio só com specs" tem README.md 'para o `arquiteto`, também quem usa o que muda'
tl_espera 1 "README: a Ruling (feminino)" tem README.md 'o Ruling'

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

# --- Revisão que converge, Task 1
tl_espera 0 "brief: lista Ao receber cita verifica-artefato.sh" tem core/templates/brief.md 'verifica-artefato.sh'
tl_espera 0 "ciclo: cita verifica-artefato.sh" tem core/processo/ciclo.md 'verifica-artefato.sh'
tl_espera 0 "config.padrao: CAMINHOS_N3" tem bootstrap/config.padrao 'CAMINHOS_N3='

# --- Revisão que converge, Task 2: impacto é entrega do arquiteto
for t in core/templates/design.md core/templates/mudanca.md; do
  tl_espera 0 "$t: seção ## Impacto" tem $t '## Impacto'
  tl_espera 0 "$t: colunas do Impacto" tem $t '| Alterado (símbolo, rota, schema, regra) | Quem usa hoje (arquivo:linha, medido) |'
done
tl_espera 0 "design: Impacto depois do contrato" ordem core/templates/design.md '## Contrato executável' '## Impacto'
tl_espera 0 "mudança: Impacto depois de Arquivos" ordem core/templates/mudanca.md '## Arquivos' '## Impacto'
tl_espera 0 "design: decisões sem prefixo D" tem core/templates/design.md 'sem o prefixo `D`'
tl_espera 0 "arquiteto consome o código e as specs afetadas, pelas buscas do brief" tem core/papeis/arquiteto.md 'as specs aprovadas que citam a regra'
tl_espera 0 "arquiteto produz o Impacto" tem core/papeis/arquiteto.md '## Impacto'
tl_espera 0 "dominio: estado atual com fonte" tem core/papeis/dominio.md 'estado atual'
tl_espera 0 "ciclo: emenda a outra spec" tem core/processo/ciclo.md 'Emenda a outra spec'
tl_espera 1 "arquiteto: Produz sem item com mais de 400 caracteres" sh -c \
  "tr -d '\r' < '$raiz/core/papeis/arquiteto.md' | sed -n '/^## Produz/,/^## /p' | awk 'length > 400' | grep -q ."

# --- Revisão que converge, Task 3: lista Pronto para revisão
for papel in dominio arquiteto testes dev; do
  c=core/papeis/$papel.md
  tl_espera 0 "$papel: tem Pronto para revisão" tem $c '## Pronto para revisão'
  tl_espera 0 "$papel: depois de No brief" ordem $c '## No brief' '## Pronto para revisão'
  tl_espera 0 "$papel: antes de Ao terminar" ordem $c '## Pronto para revisão' '## Ao terminar'
  tl_espera 0 "$papel: autoconferência no relatório" tem $c 'autoconferência'
done
tl_espera 0 "revisor: modos usam a lista do autor" tem core/papeis/revisor.md '"Pronto para revisão"'
tl_espera 0 "perfil: padrão do revisor espelhado no autor" tem core/templates/perfil-papel.md 'Pronto para revisão'

tl_espera 1 "revisor: modo mudanca não repete a lista do autor" tem core/papeis/revisor.md '"Questões em aberto", "Rulings" e a coluna "Decisão do humano" estão vazias'
tl_espera 1 "revisor: modo design não repete a lista do autor" tem core/papeis/revisor.md 'está em "Itens N3 (aprovação no Gate 1)", e cada task cita'
tl_espera 0 "revisor: mudanca mantém a classificação errada como Importante" tem core/papeis/revisor.md 'mais de uma task) é achado **Importante**'

tl_espera 0 "arquiteto: Pronto cobre acréscimo só acréscimo" tem core/papeis/arquiteto.md 'nada removido, renomeado ou com tipo ou semântica alterados'
tl_espera 0 "arquiteto: Pronto cobre decisões novas da mudança" tem core/papeis/arquiteto.md 'listadas em "Decisões novas"'

# --- Revisão que converge, Task 4: brief sem desenho, parecer sem prescrição, causa medida
tl_espera 0 "pr: resumo por rodada" tem core/templates/pr.md 'r<k> <modo>: <veredito> · C n I n M n · causas:'
b=core/templates/brief.md
tl_espera 0 "brief: seção Casos a cobrir" tem $b '## Casos a cobrir'
tl_espera 0 "brief: Casos a cobrir é condicional (depois de Entrega)" ordem $b '## Entrega' '## Casos a cobrir'
tl_espera 0 "brief: Já decidido só com origem citável" tem $b 'origem citável'
tl_espera 0 "brief: Antes de enviar confere decisão sem origem" tem $b 'nenhuma linha decide algo sem origem citável'
p=core/templates/parecer.md
tl_espera 0 "parecer: coluna Causa" tem $p '| ID | Classe | Causa | Onde | Problema | Evidência |'
tl_espera 0 "parecer: valores de Causa" tem $p 'defeito | contrato | não conferido | sem contrato | forma'
tl_espera 0 "parecer: marca já na rodada 1" tem $p 'já na rodada 1'
tl_espera 1 "parecer: não prescreve correção" tem $p 'o que outro papel deve fazer'
tl_espera 0 "revisor: rodada de correção" tem core/papeis/revisor.md '## Rodada de correção'
tl_espera 0 "ciclo: 3ª devolução vai ao humano" tem core/processo/ciclo.md '3ª devolução'
tl_espera 0 "kit: Menor não abre rodada" tem core/processo/ciclo.md 'Menor não abre rodada'
tl_espera 0 "kit sem Menor só na revisão final" nenhum 'Menor.{0,60}revisão final da branch' core adapters

# --- Revisão que converge, Task 7: verify em dois níveis
tl_espera 0 "coerência: Ao receber pede o rápido no laço" tem core/templates/brief.md 'verify.sh --rapido'
tl_espera 0 "coerência: Ao receber pede o completo uma vez antes do PR" tem core/templates/brief.md 'verify.sh` completo, uma vez'
tl_espera 1 "coerência: Ao receber não pede o completo antes de despachar o revisor diff" tem core/templates/brief.md 'antes de despachar o revisor `diff`'
tl_espera 0 "coerência: Ao receber manda verifica-red depois do RED" tem core/templates/brief.md 'depois do RED: `sh agentic/mecanismos/scripts/verifica-red.sh`'
tl_espera 0 "coerência: ciclo descreve os níveis (completo só no revisor diff e antes do PR)" tem core/processo/ciclo.md 'o completo roda só no revisor `diff` (ele mesmo, nunca `--rapido`) e uma vez, pelo orquestrador, antes do PR'
tl_espera 0 "coerência: revisor roda o verify completo, nunca --rapido" tem core/papeis/revisor.md 'Rode o `verify.sh` completo você mesmo — nunca `--rapido`'
tl_espera 1 "coerência: dev não exige o completo antes de devolver" tem core/papeis/dev.md 'antes de devolver'
tl_espera 0 "coerência: testes prova o RED com verifica-red, sem verify completo" tem core/papeis/testes.md 'verifica-red.sh` verde; o verify completo não é exigido de você'
tl_espera 0 "coerência: verifica-artefato na árvore do autor (brief)" tem core/templates/brief.md '`cd <árvore> && sh agentic/mecanismos/scripts/verifica-artefato.sh'
tl_espera 0 "coerência: verifica-artefato na árvore do autor (ciclo)" tem core/processo/ciclo.md '`cd <árvore> && sh agentic/mecanismos/scripts/verifica-artefato.sh'
tl_espera 0 "coerência: /mudanca roda verifica-artefato no worktree do autor" tem adapters/claude-code/commands/mudanca.md 'cd <worktree> && sh agentic/mecanismos/scripts/verifica-artefato.sh mudanca'
tl_espera 0 "coerência: README esclarece Impacto só em artefatos novos" tem README.md 'exigida dos designs e documentos de mudança escritos depois da atualização'
tl_espera 0 "coerência: README põe Pronto para revisão no contrato, não no artefato" tem README.md '`## Pronto para revisão` é seção dos contratos dos papéis'
tl_espera 1 "coerência: verifica-red sem sed 's/; /\n/' (GNU-only)" tem mecanismos/scripts/verifica-red.sh "sed 's/; /\n/g'"
tl_espera 0 "coerência: config.padrao tem CMD_VERIFY_RAPIDO" tem bootstrap/config.padrao 'CMD_VERIFY_RAPIDO='
tl_espera 0 "coerência: entrevista pergunta o comando rápido" tem bootstrap/entrevista.md 'CMD_VERIFY_RAPIDO'
tl_espera 0 "coerência: dev usa o rápido no laço" tem core/papeis/dev.md 'verify.sh --rapido'
tl_espera 0 "coerência: /verify do claude aceita --rapido" tem adapters/claude-code/commands/verify.md '--rapido'
tl_espera 0 "coerência: /verify do copilot aceita --rapido" tem adapters/copilot/prompts/verify.prompt.md '--rapido'

# --- Revisão que converge, Task 8: Ruling e em-andamento sem commit próprio; caracterização antes do RED
tl_espera 1 "nova-task não escreve em-andamento" tem adapters/claude-code/commands/nova-task.md 'Marque a task `**Status:** em-andamento`'
tl_espera 0 "ciclo: Ruling vai no próximo commit do papel seguinte, antes do revisor diff" tem core/processo/ciclo.md 'o brief do próximo papel manda incluir essa mudança no próximo commit dele'
tl_espera 0 "brief: Ruling vai no próximo commit do papel" tem core/templates/brief.md 'o brief do próximo papel manda incluir essa mudança no próximo commit dele'
tl_espera 0 "settings do claude nega Edit no cache da prova RED" tem adapters/claude-code/settings.json.tmpl '"Edit(**/.git/agentic/**)"'
tl_espera 1 "enxuta: sem commit de em-andamento" tem core/processo/ciclo.md '`docs(task): … em-andamento`'
tl_espera 0 "testes: caracterização antes do RED" tem core/papeis/testes.md 'caracterização'
tl_espera 1 "mudanca: sem em-andamento na lista do passo 6" tem adapters/claude-code/commands/mudanca.md '`em-andamento`, fases RED'

tl_espera 1 "README: sem commit docs(task) de em-andamento" tem README.md 'docs(task): ... em-andamento'


# --- Revisão que converge, Task 9: vínculo CA → teste no commit RED
tl_espera 0 "testes: CA anotado com → test: no RED" tem core/papeis/testes.md '→ test: <arquivo>::<nome>'
tl_espera 0 "template task: formato da anotação" tem core/templates/task.md '→ test: <arquivo>::<nome>'
tl_espera 0 "template mudanca: formato da anotação" tem core/templates/mudanca.md '→ test: <arquivo>::<nome>'
tl_espera 0 "verifica-red: mensagem de CA sem anotação" tem mecanismos/scripts/verifica-red.sh 'sem → test: na task'

# --- Revisão que converge, Task 10: nota de atualização
tl_espera 0 "README: nota de atualização" tem README.md '## O que muda ao atualizar o kit'

# --- Varredura de coerência (2026-11-15): cada contradição corrigida ganha uma checagem que impede a volta.
# Enumerações que precisam casar com os arquivos.
for c in "$raiz"/adapters/claude-code/commands/*.md; do
  n=$(basename "$c" .md)
  tl_espera 0 "CLAUDE.md lista o comando /$n" tem adapters/claude-code/CLAUDE.md "\`/$n\`"
done
for c in "$raiz"/adapters/copilot/prompts/*.prompt.md; do
  n=$(basename "$c" .prompt.md)
  tl_espera 0 "copilot-instructions lista o prompt $n" tem adapters/copilot/copilot-instructions.md "\`$n\`"
done
for a in "$raiz"/adapters/claude-code/agents/*.md; do
  n=$(basename "$a" .md)
  tl_espera 0 "agente $n existe nos dois adaptadores" test -f "$raiz/adapters/copilot/agents/$n.agent.md"
done
tl_espera 0 "oráculo: template de agente nos dois adaptadores" test -f "$raiz/adapters/copilot/agente-oraculo.tmpl.md"
tl_espera 0 "oráculo: instalado com o Copilot" tem bootstrap/instalar.sh 'adapters/copilot/agente-oraculo.tmpl.md'
tl_espera 0 "oráculo: consulta pelo orquestrador (ciclo)" tem core/processo/ciclo.md '**Oráculo:** um papel não consulta oráculo direto'
tl_espera 0 "oráculo: responde ao orquestrador" tem core/papeis/_oraculo.md 'Entregue a resposta ao orquestrador'
# Formatos e termos que não podem voltar.
tl_espera 0 "ID de critério é CA<n>, nunca CA-n" nenhum '<CA-|CA-[0-9n]' core adapters README.md
tl_espera 0 "sem referência a glossário inexistente" nenhum 'glossário' core adapters README.md bootstrap
tl_espera 0 "sem 'worktree do autor' (na trilha padrão não há worktree antes do Gate 1)" nenhum 'worktree do autor' core adapters README.md
tl_espera 0 "commits: test: e docs(mudanca): na lista do ciclo" linha core/processo/ciclo.md '^- \*\*Commits:\*\* .*`test:`.*`docs\(mudanca\):`'
# Níveis de verify: ninguém exige o completo de testes/dev.
tl_espera 0 "ciclo: fase 4 do dev é verify --rapido" linha core/processo/ciclo.md '^\| 4 \| GREEN.*`verify\.sh --rapido`'
tl_espera 1 "ciclo: enxuta sem verify completo entre GREEN e revisão" tem core/processo/ciclo.md 'GREEN/REFACTOR → `verify` →'
tl_espera 0 "copilot: verificação por nível" tem adapters/copilot/copilot-instructions.md 'VERIFY RÁPIDO: OK'
tl_espera 0 "brief: verify completo só no revisor diff" tem core/templates/brief.md 'nunca tira do `revisor` modo `diff`'
tl_espera 0 "AGENTS: verificação do passo, não só verify.sh" tem core/templates/AGENTS.md 'Nunca afirme sucesso sem ter visto a saída da verificação do seu passo'
# Regras com exceção declarada nos dois lados.
tl_espera 0 "AGENTS: exceção da remoção autorizada" tem core/templates/AGENTS.md 'Única exceção: a remoção autorizada de asserções'
tl_espera 0 "dev: dependência aprovada no Gate 1 não para" tem core/papeis/dev.md 'Dependência nova fora de "N3 aprovados no Gate 1"'
tl_espera 0 "dev: escopo ampliado pelo orquestrador" tem core/processo/ciclo.md 'Ampliar o escopo é decisão do orquestrador, nunca do papel'
tl_espera 0 "divergência spec × código vai em Divergências" tem core/processo/ciclo.md 'registre em "Divergências" da spec'
tl_espera 0 "empilhamento só com plataforma de PR" tem core/processo/ciclo.md '**Branches empilhadas:** só com plataforma de PR'
tl_espera 0 "README: delegação com enabled: true" tem README.md 'grava `enabled: true` e `gate1: D<n>`'
tl_espera 0 "spec: delegado coberto pelo plano usa plano:" tem core/templates/spec.md 'Fonte plano:<arquivo>:<linha>'
tl_espera 0 "/intent: dominio não conversa com o humano" tem adapters/claude-code/commands/intent.md 'o `dominio` nunca conversa direto com o humano'
tl_espera 0 "/nova-task: primeira task usa a branch do Gate 1" tem adapters/claude-code/commands/nova-task.md 'crie-o sem `-b`'
tl_espera 0 "copilot: status no início da sessão" tem adapters/copilot/copilot-instructions.md 'status-projeto.sh` antes de escolher a task'
tl_espera 0 "hook: barra o desvio dos githooks" tem adapters/claude-code/hooks/pre-tool-use.sh '--no-v|hookspath|config-env|GIT_CONFIG_'

tl_espera 0 "empilhamento só com plataforma de PR (README)" tem README.md 'Com plataforma de PR, quando a task anterior'
tl_espera 0 "empilhamento só com plataforma de PR (task)" tem core/templates/task.md 'só com plataforma de PR'
tl_espera 0 "ampliação de escopo nunca é do papel (verifica-escopo)" tem mecanismos/scripts/verifica-escopo.sh 'decisão do orquestrador'
tl_espera 0 "Ruling depois do último commit de papel vai ao Gate 2" tem core/processo/ciclo.md 'quem a confere é o humano, no Gate 2'
tl_espera 0 "dominio não entrevista o humano" nenhum 'a partir da entrevista|conduz.{0,4} a entrevista' core adapters

# --- Site de divulgação (docs/specs/2026-11-16-site-divulgacao-design.md)
tl_espera 0 "LICENSE: MIT" tem LICENSE 'MIT License'
tl_espera 0 "LICENSE: titular" tem LICENSE 'Copyright (c) 2026 Paulo Ricardo Calazans'
tl_espera 0 "README: seção Licença" linha README.md '^## Licença$'
tl_espera 0 "sem nome de projeto de origem" sem_nomes_proibidos README.md LICENSE docs core adapters bootstrap mecanismos scripts

e=docs/evidencias.md
for a in e1 e2 e3 e4 e5 e6 e7 e8 e9 e10; do
  tl_espera 0 "evidências: âncora $a" tem $e "<a id=\"$a\"></a>"
done
tl_espera 0 "evidências: seção Limites" linha $e '^## Limites$'
tl_espera 0 "evidências: data de corte" tem $e '2026-11-15'
tl_espera 0 "evidências sem nome de projeto de origem" sem_nomes_proibidos $e
tl_espera 0 "README cita as evidências" tem README.md 'docs/evidencias.md'

s=site/index.html
tl_espera 0 "site: página existe" tem $s '<html lang="pt-BR"'
tl_espera 0 "site: og:image" tem $s 'property="og:image"'
tl_espera 0 "site: data de corte" tem $s '2026-11-15'
tl_espera 0 "site: licença no rodapé" tem $s 'MIT'
tl_espera 0 "site sem nome de projeto de origem" sem_nomes_proibidos site
sem_package() { ! [ -e "$raiz/package.json" ]; }
tl_espera 0 "site: sem build (sem package.json)" sem_package
# cada número marcado tem par, como palavra inteira, dentro da seção da sua âncora em docs/evidencias.md
secao_evid() { tr -d '\r' < "$raiz/docs/evidencias.md" | awk -v a="<a id=\"$1\"></a>" 'index($0,a){d=1;next} d&&(/^<a id="/||/^## Limites/){exit} d'; }
site_nums_ok() {
  [ -f "$raiz/$s" ] || return 1
  tl_n=$(tr -d '\r' < "$raiz/$s" | grep -o 'data-e="e[0-9]*">[^<]*<' | sed 's/data-e="\(e[0-9]*\)">\([^<]*\)</\1 \2/')
  [ -n "$tl_n" ] || { echo "nenhum número marcado"; return 1; }
  echo "$tl_n" | while read -r tl_a tl_v; do
    tem docs/evidencias.md "<a id=\"$tl_a\"></a>" || { echo "sem âncora $tl_a"; return 1; }
    secao_evid "$tl_a" | grep -qFw -- "$tl_v" || { echo "valor sem par na seção: $tl_a $tl_v"; return 1; }
  done
}
tl_espera 0 "site: todo número tem par em evidencias.md" site_nums_ok
# cada frase de mecanismo existe no README
site_mec_ok() {
  [ -f "$raiz/$s" ] || return 1
  tl_f=$(tr -d '\r' < "$raiz/$s" | grep -o '<p class="mecanismo">[^<]*</p>' | sed 's/<[^>]*>//g')
  [ -n "$tl_f" ] || { echo "nenhuma frase de mecanismo"; return 1; }
  echo "$tl_f" | while IFS= read -r tl_l; do tem README.md "$tl_l" || { echo "frase fora do README: $tl_l"; return 1; }; done
}
tl_espera 0 "site: frases de mecanismo iguais ao README" site_mec_ok

w=.github/workflows/pages.yml
tl_espera 0 "pages: publica só site/" linha $w 'path: *site$'
tl_espera 0 "pages: deploy oficial" tem $w 'actions/deploy-pages@v4'
tl_espera 0 "README: link do site" tem README.md 'paulocalazans.github.io/framework-sdlc-agentico'

# base teórica: cada citação da página existe literalmente no parecer normativo
site_cit_ok() {
  [ -f "$raiz/$s" ] || return 1
  tl_c=$(tr -d '\r' < "$raiz/$s" | grep -o '<blockquote class="citacao"><p>[^<]*</p>' | sed 's/<[^>]*>//g')
  [ -n "$tl_c" ] || { echo "nenhuma citação"; return 1; }
  echo "$tl_c" | while IFS= read -r tl_l; do tem docs/avaliacao-normativa-swebok-iso.md "$tl_l" || { echo "citação sem fonte: $tl_l"; return 1; }; done
}
tl_espera 0 "site: citações da base teórica existem no parecer normativo" site_cit_ok
tl_espera 0 "site: seção base teórica" tem $s 'id="base"'
tl_espera 0 "site: link para o parecer normativo" tem $s 'docs/avaliacao-normativa-swebok-iso.md'

# revisão final da branch (correções)
tl_espera 0 "evidências: soma por papel explicada" tem docs/evidencias.md 'A soma por papel dá 704'
tl_espera 0 "site: 36 execuções marcado" tem $s 'data-e="e1">36<'
tl_espera 0 "site: menos de 5% marcado" tem $s 'data-e="e4">5%<'
tl_espera 0 "site: 5 execuções de B marcado" tem $s 'data-e="e1">5<'
tl_espera 0 "site: verify garantido por regra + script, como no README" tem $s '<code>regra + verify.sh</code>'
tl_espera 0 "site: hook PreToolUse só no Claude Code" tem $s 'hook PreToolUse (só Claude Code)'
tl_espera 0 "site: ressalva do merge fast-forward" tem $s 'merge fast-forward local não dispara hook'
tl_espera 0 "site: pre-merge-commit e deny de gh pr merge" tem $s 'pre-merge-commit · deny de gh pr merge'
tl_espera 1 "site: sem 'cada regra nasceu de medição' (contradiz a base teórica)" tem $s 'Cada regra do kit nasceu de uma medição'
tl_espera 1 "site: meta sem 'cada regra sustentada por medições'" tem $s 'Cada regra sustentada por medições'

# base teórica: pesquisa sobre agentes (notebook AI-native SDLC), registrada no parecer §2.5
tl_espera 0 "parecer: seção 2.5 de pesquisa sobre agentes" linha docs/avaliacao-normativa-swebok-iso.md '^### 2\.5 '
tl_espera 0 "site: bloco de pesquisa sobre agentes" tem $s 'id="pesquisa"'
site_cit_n() { [ "$(tr -d '\r' < "$raiz/$s" | grep -o '<blockquote class="citacao">' | wc -l)" -ge 10 ]; }
tl_espera 0 "site: ao menos 10 citações (normas + pesquisa)" site_cit_n

# --- Portabilidade Codex/Antigravity (docs/specs/2026-11-16-portabilidade-codex-antigravity-design.md)
st=adapters/claude-code/settings.json.tmpl
# util_lista <arquivo>: linhas úteis de uma lista de adapters/comum (sem #, sem vazias, sem \r).
util_lista() { tr -d '\r' < "$raiz/$1" | grep -v -e '^#' -e '^[[:space:]]*$'; }
deny_bash() { tr -d '\r' < "$raiz/$st" | grep -o '"Bash([^"]*:\*)"' | sed -n '/gh pr merge/,$p' | sed -E 's/^"Bash\((.*):\*\)"$/\1/'; }
deny_edit() { tr -d '\r' < "$raiz/$st" | grep -o '"Edit([^"]*)"' | sed -E 's/^"Edit\((.*)\)"$/\1/' | grep -v '^\*\*/'; }
# mesmas <A> <B>: as duas saídas (comandos) têm as mesmas linhas, em qualquer ordem; imprime a diferença.
mesmas() { tl_a=$(mktemp); tl_b=$(mktemp); $1 | sort > "$tl_a"; $2 | sort > "$tl_b"; diff "$tl_a" "$tl_b"; tl_r=$?; rm -f "$tl_a" "$tl_b"; return $tl_r; }
negados_txt() { util_lista adapters/comum/comandos-negados.txt; }
caminhos_txt() { util_lista adapters/comum/caminhos-protegidos.txt; }
tl_espera 0 "comandos-negados.txt = Bash(...) do deny do settings" mesmas deny_bash negados_txt
tl_espera 0 "caminhos-protegidos.txt = Edit(...) do deny do settings (sem **/)" mesmas deny_edit caminhos_txt
for x in '.codex/hooks.json' '.codex/hooks/**' '.codex/rules/**' '.codex/config.toml' '.agents/hooks.json' '.agents/hooks/**'; do
  tl_espera 0 "settings: deny de Edit(**/$x)" tem $st "\"Edit(**/$x)\""
done

# Codex: regras geradas das listas, agentes dos 5 papéis, hooks pelo lançador do Windows
ru=adapters/codex/rules/agentic.rules
# padrao_starlark <prefixo>: o pattern que a regra do Codex usa para o prefixo ("a b" vira ["a", "b"]).
padrao_starlark() { printf '%s\n' "$1" | awk '{ s = "pattern = ["; for (i = 1; i <= NF; i++) s = s (i > 1 ? ", " : "") "\"" $i "\""; print s "]," }'; }
# regra <prefixo> <decisão>: a regra existe, com a decisão na linha seguinte ao pattern.
regra() { tr -d '\r' < "$raiz/$ru" | grep -A1 -F -- "$(padrao_starlark "$1")" | grep -qF "decision = \"$2\""; }
allow_bash() { tr -d '\r' < "$raiz/$st" | sed -n '/"allow"/,/\]/p' | grep -o '"Bash([^"]*:\*)"' | sed -E 's/^"Bash\((.*):\*\)"$/\1/'; }
negados_txt > "$TL_SAIDA.neg"
while IFS= read -r n; do
  tl_espera 0 "codex: regra forbidden para $n" regra "$n" forbidden
done < "$TL_SAIDA.neg"
allow_bash > "$TL_SAIDA.alw"
while IFS= read -r a; do
  tl_espera 0 "codex: regra allow para $a" regra "$a" allow
done < "$TL_SAIDA.alw"
rm -f "$TL_SAIDA.neg" "$TL_SAIDA.alw"
tl_espera 0 "codex: allow do verify pelo lançador" regra 'git -c alias.agentic-sh=!sh agentic-sh agentic/mecanismos/scripts/verify.sh' allow
n_forb() { [ "$(tr -d '\r' < "$raiz/$ru" | grep -c 'decision = "forbidden"')" -eq "$(negados_txt | wc -l)" ]; }
tl_espera 0 "codex: nenhuma regra forbidden além da lista" n_forb
for pa in dominio arquiteto testes dev revisor; do
  tl_espera 0 "codex: agente $pa com name" linha adapters/codex/agents/$pa.toml "^name = \"$pa\"$"
  tl_espera 0 "codex: agente $pa aponta o contrato" tem adapters/codex/agents/$pa.toml "agentic/processo/papeis/$pa.md"
done
tl_espera 0 "codex: revisor declara o limite por revisão" tem adapters/codex/agents/revisor.toml 'por revisão'
tl_espera 0 "codex: hooks.json usa o lançador no PreToolUse" tem adapters/codex/hooks.json 'git -c alias.agentic-sh=!sh agentic-sh .codex/hooks/guarda.sh'
tl_espera 1 "codex: hooks.json sem \$( (não roda no PowerShell)" tem adapters/codex/hooks.json '$('

# Antigravity: agentes dos 5 papéis sem tools: (nome de ferramenta errado trava o subagente), hooks pelo lançador
for pa in dominio arquiteto testes dev revisor; do
  tl_espera 0 "antigravity: agente $pa com name" linha adapters/antigravity/agents/$pa.md "^name: $pa$"
  tl_espera 0 "antigravity: agente $pa aponta o contrato" tem adapters/antigravity/agents/$pa.md "agentic/processo/papeis/$pa.md"
done
tl_espera 0 "antigravity: nenhum agente com tools:" nenhum '^tools:' adapters/antigravity
tl_espera 0 "antigravity: revisor declara o limite por revisão" tem adapters/antigravity/agents/revisor.md 'por revisão'
tl_espera 0 "antigravity: hooks.json usa o lançador no guarda" tem adapters/antigravity/hooks.json 'git -c alias.agentic-sh=!sh agentic-sh .agents/hooks/guarda.sh'
tl_espera 0 "antigravity: hooks.json usa o lançador no início" tem adapters/antigravity/hooks.json 'git -c alias.agentic-sh=!sh agentic-sh .agents/hooks/inicio.sh'
tl_espera 1 "antigravity: hooks.json sem \$(" tem adapters/antigravity/hooks.json '$('

# Skills compartilhadas (.agents/skills): uma por comando do Claude, apontando para ele; instalador com as três opções
for c in "$raiz"/adapters/claude-code/commands/*.md; do
  c=$(basename "$c" .md)
  tl_espera 0 "skill $c com name" linha adapters/agents-skills/$c/SKILL.md "^name: $c$"
  tl_espera 0 "skill $c aponta para .claude/commands/$c.md" tem adapters/agents-skills/$c/SKILL.md ".claude/commands/$c.md"
done
n_skills() { [ "$(ls -d "$raiz"/adapters/agents-skills/*/ | wc -l)" -eq "$(ls "$raiz"/adapters/claude-code/commands/*.md | wc -l)" ]; }
tl_espera 0 "skills: nenhuma sem comando do Claude" n_skills
tl_espera 0 "instalar.sh: uso cita as três opções" tem bootstrap/instalar.sh 'uso: instalar.sh <projeto-alvo> [--copilot] [--codex] [--antigravity]'

tl_fim
