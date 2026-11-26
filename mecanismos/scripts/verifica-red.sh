#!/bin/sh
# verifica-red.sh [base] — prova que cada commit test(red):
#   (1) não tocou código de produção: só arquivos de teste — prefixo de DIRS_TESTE ou padrão de algum
#       TESTE_<n>_PADROES (teste colocalizado, ex.: src/*.spec.ts); documentação sob docs/ e agentic/projeto/ é
#       isenta (o documento da task pode ser atualizado no mesmo commit);
#   (2) falhava de fato, num worktree isolado no commit RED. Cada arquivo de teste tocado pelo RED (com asserção)
#       é provado pelo caminho dele e precisa falhar: o executor TESTE_<n>_COMANDO cujo padrão casa com o arquivo;
#       sem executor, o CMD_TESTE_ARQUIVO; sem os dois, a suíte inteira (CMD_TESTE), uma vez por RED, com
#       "degradado: <arquivo> sem executor". Sem executor nenhum nem CMD_TESTE_ARQUIVO, o RED inteiro vai pela
#       suíte (modo degradado). O preparo é o TESTE_<n>_PREPARO de cada executor usado (sem repetir) mais o
#       CMD_PREPARAR_TESTE quando há prova por CMD_TESTE_ARQUIVO ou pela suíte. Com TESTE_<n>_RC_RED, só esse
#       código é RED (ajuda: red-junit.sh); sem ele, qualquer código fora de 0, 126 e 127;
#   (3) não teve asserções removidas depois, POR ARQUIVO: para cada arquivo de teste tocado pelo RED, o
#       número de linhas que casam MARCADOR_ASSERCAO em HEAD não pode ser menor que no RED (arquivo
#       removido em HEAD conta zero). Arquivos não tocados pelo RED não entram na comparação.
#       Exceção: remoção autorizada, quando uma Ruling, decisão ou emenda de spec tirou o comportamento que as
#       asserções provavam. Um commit da branch declara, num trailer,
#         Assercoes-removidas: <arquivo> <n> [em <sha>] (<R-n | D<n> | D:<slug> | Emenda n>)
#       as n asserções removidas no commit X (<sha>, ou o próprio commit do trailer). O trailer só conta se:
#       X vem depois do RED e não depois do commit do trailer; a referência foi acrescentada sob agentic/projeto/
#       entre a base e o pai de X (registrada antes da remoção). O crédito de X é no máximo a queda de asserções
#       do arquivo em X, mesmo com várias declarações; o limite passa a ser (asserções no RED - créditos).
#   (4) cache: a prova de (2) é guardada por SHA do RED e assinatura do caminho de prova, e reaproveitada (ver
#       "Cache (4)" mais abaixo); ligar executores num projeto em andamento não refaz o RED já provado pela suíte
#       ("provado antes pela suíte (assinatura anterior)"). AGENTIC_RED_SEM_CACHE=1 ignora a leitura. (1) e (3)
#       rodam sempre.
#   (5) vínculo CA → teste: cada CA da task (AGENTIC_TASK, exportada pelo verify.sh, inclusive com --task; ou a
#       task de **Branch:** igual à branch atual) tem "→ test: <arquivo>::<nome>" e o arquivo é tocado por commit
#       RED; task sem nenhuma anotação só avisa; sem task (trilha rápida), não checa. Task com CA e nenhum commit
#       RED bloqueia quando a branch tem código além de docs só de documentação, chore e test: só de teste (GREEN sem RED), salvo
#       task de remoção de comportamento (trailer Assercoes-removidas:).
#   (6) log: a saída do preparo e de cada execução fica em agentic/.estado/verifica-red.log (reescrito a cada
#       execução); no bloqueio, as últimas 40 linhas daquela execução são repetidas.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
if [ -n "${1:-}" ]; then
  base=$(git merge-base HEAD "$1") || agentic_falha "base inválida: $1"
else
  base=$(agentic_base)
fi
[ -n "$base" ] || agentic_falha "sem base de comparação (a branch principal '$BRANCH_PRINCIPAL' existe?)"
git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"

reds=$(git log --format=%H --grep='^test(red):' "$base..HEAD") || agentic_falha "falha ao listar commits"
# Task da branch: AGENTIC_TASK (exportada pelo verify.sh, inclusive com --task) ou **Branch:** igual ao HEAD.
vinc_task=""
if [ -n "${AGENTIC_TASK:-}" ] && [ -f "$AGENTIC_TASK" ]; then
  vinc_task=$AGENTIC_TASK
else
  vinc_br=$(git symbolic-ref --short -q HEAD)
  if [ -n "$vinc_br" ]; then
    for vinc_f in agentic/projeto/specs/*/tasks/*.md; do
      [ -f "$vinc_f" ] || continue
      vinc_b=$(sed -n 's/^\*\*Branch:\*\*[[:space:]]*//p' "$vinc_f" | head -n 1 | tr -d '\r`' | sed 's/[[:space:]]*$//')
      [ "$vinc_b" = "$vinc_br" ] && { vinc_task=$vinc_f; break; }
    done
  fi
fi
# ref_registrada <rev> <ref>: a referência aparece numa linha acrescentada sob agentic/projeto/ entre a base e <rev>.
ref_registrada() {
  git -c core.quotepath=off diff "$base" "$1" -- agentic/projeto/ 2>/dev/null | sed -n 's/^+//p' | grep -v '^++ ' \
  case "$2" in
    D:*) # arquivo de decisão acrescentado entre a base e <rev>, ou a referência numa linha acrescentada
      rr_slug=${2#D:}
      [ -n "$(git -c core.quotepath=off diff --name-only --diff-filter=A "$base" "$1" -- "agentic/projeto/decisoes/$rr_slug.md" 2>/dev/null)" ] && return 0
      git -c core.quotepath=off diff "$base" "$1" -- agentic/projeto/ 2>/dev/null | sed -n 's/^+//p' | grep -v '^++ ' \
        | grep -qE "(^|[^[:alnum:]])$2([^[:alnum:]-]|$)"
      return ;;
  esac
    | grep -qE "(^|[^[:alnum:]])$2([^[:alnum:]]|$)"
}

# CAs da task (mesma definição para "GREEN sem RED" e para o vínculo).
vinc_ca=""
if [ -n "$vinc_task" ]; then
  # Seção "Critérios de pronto" (task) ou, sem ela, "Critérios de aceite" (mudança); sem \r, backticks e comentários HTML.
  vinc_secao=""
  for vinc_t in 'Critérios de pronto' 'Critérios de aceite'; do
    vinc_secao=$(tr -d '\r`' < "$vinc_task" | awk -v t="## $vinc_t" '
      BEGIN { achou = 0 }
      /^## / { if (dentro) exit; dentro = ($0 == t); if (dentro) achou = 1; next }
      dentro {
        l = $0
        while (1) {
          if (com) { i = index(l, "-->"); if (!i) { l = ""; break } l = substr(l, i + 3); com = 0 }
          i = index(l, "<!--"); if (!i) break
          j = index(substr(l, i + 4), "-->")
          if (j) l = substr(l, 1, i - 1) substr(l, i + 4 + j + 2); else { l = substr(l, 1, i - 1); com = 1 }
        }
        print l
      }')
    [ -z "$(printf '%s' "$vinc_secao" | grep -E 'CA[0-9]+')" ] || break
  done
  vinc_ca=$(printf '%s\n' "$vinc_secao" | grep -E '^[[:space:]]*[-*]?[[:space:]]*(\[[ xX]\][[:space:]]*)?CA[0-9]+')
fi
if [ -z "$reds" ]; then
  # GREEN sem RED: task com CA e algum commit desta branch que ainda não está na principal (sem merges; o que um
  # merge da principal trouxe não conta, o que um merge de sub-branch trouxe conta) e que não é registro (docs),
  # contrato executável (chore) nem teste (test: só com arquivos de teste ou documentação). Task de remoção de
  # comportamento (trailer Assercoes-removidas:) não tem RED por construção ("Remoção de comportamento" no ciclo).
  if [ -n "$vinc_ca" ]; then
    gr_nao=""
    for gr_p in "$BRANCH_PRINCIPAL" "origin/$BRANCH_PRINCIPAL"; do
      git rev-parse --verify -q "$gr_p^{commit}" >/dev/null 2>&1 && gr_nao="$gr_nao $gr_p"
    done
    gr_commits=$(git log --no-merges --format=%H "$base..HEAD" ${gr_nao:+--not $gr_nao})
    gr_remocao=""; gr_green=""
    for c in $gr_commits; do
      # Remoção só vale com a referência registrada sob agentic/projeto/ antes do commit (ciclo, "Remoção de comportamento").
      for gr_ref in $(git log -1 --format='%(trailers:key=Assercoes-removidas,valueonly)' "$c" | sed -n 's/.*(\([^)]*\)).*/\1/p'); do
        ref_registrada "$c^" "$gr_ref" && gr_remocao=1
      done
      gr_s=$(git log -1 --format=%s "$c")
      case "$gr_s" in
        chore:*|chore\(*) continue ;; # contrato executável: o esqueleto é conferido pelo revisor (limite declarado)
        docs:*|docs\(*|test:*|test\(*)
          # docs só com documentação (*.md, docs/, agentic/projeto/); test: também com arquivos de teste.
          gr_tipo=${gr_s%%[(:]*}
          gr_prod=$(git -c core.quotepath=off diff-tree --no-commit-id --name-only -r "$c" | while IFS= read -r f; do
            case "$f" in docs/*|agentic/projeto/*|*.md) continue ;; esac
            [ "$gr_tipo" = test ] && agentic_e_teste "$f" && continue
            echo "$f"
          done)
          [ -n "$gr_prod" ] && gr_green="$gr_green ${c%"${c#???????}"}" ;;
        *) gr_green="$gr_green ${c%"${c#???????}"}" ;;
      esac
    done
    if [ -n "$gr_green" ] && [ -z "$gr_remocao" ]; then
      echo "agentic: BLOQUEADO — a task $vinc_task tem CA e a branch tem código sem nenhum test(red): (commits:$gr_green)"
      exit 1
    fi
  fi
  echo "verifica-red: nenhum commit test(red): na branch"
  exit 0
fi
[ -n "$CMD_TESTE" ] || agentic_falha "CMD_TESTE não configurado em agentic/config"
[ -n "$MARCADOR_ASSERCAO" ] || agentic_falha "MARCADOR_ASSERCAO vazio em agentic/config — não há como comparar asserções"
agentic_executores >/dev/null # avisa bloco TESTE_<n> ignorado (buraco na numeração)
executores=$(agentic_executores 2>/dev/null)
[ -n "$(printf '%s' "$DIRS_TESTE" | tr -d '[:space:]')" ] || [ -n "$executores" ] || agentic_falha "DIRS_TESTE vazio em agentic/config"
for n in $executores; do
  [ -n "$(agentic_executor_campo "$n" COMANDO)" ] || agentic_falha "TESTE_${n}_COMANDO vazio em agentic/config"
  v=$(agentic_executor_campo "$n" RC_RED)
  case $v in *[!0-9]*) agentic_falha "TESTE_${n}_RC_RED não numérico em agentic/config: $v" ;; esac
done
# Prova por arquivo: há executor ou CMD_TESTE_ARQUIVO. Sem nenhum dos dois, o RED inteiro vai pela suíte (degradado).
por_arquivo=""
[ -n "$executores" ] || [ -n "$CMD_TESTE_ARQUIVO" ] && por_arquivo=1
if [ -z "$por_arquivo" ]; then
  echo "degradado: CMD_TESTE_ARQUIVO não configurado — RED provado pela suíte inteira"
fi

# conta_assercoes <rev> <arquivo>: imprime o número de linhas com asserção no arquivo naquela revisão
# (0 se o arquivo não existe nela); retorna 1 se o git grep falhar.
conta_assercoes() {
  ca_saida=$(git -c core.quotepath=off grep -c -E -e "$MARCADOR_ASSERCAO" "$1" -- ":(literal)$2" 2>/dev/null)
  ca_rc=$?
  [ "$ca_rc" -le 1 ] || return 1 # 1 = nenhuma ocorrência (ou arquivo ausente); > 1 = erro
  printf '%s\n' "$ca_saida" | awk -F: 'NF { s += $NF } END { print s + 0 }'
}

# ignora_trailer <portador> <motivo> <linha>: explica por que uma declaração não conta (em stderr).
ignora_trailer() {
  echo "verifica-red: trailer Assercoes-removidas ignorado em $(git rev-parse --short "$1") ($2): $3" >&2
}

# removidas_autorizadas <rev-red> <arquivo>: créditos de remoção autorizada do arquivo para esse RED, a partir
# dos trailers "Assercoes-removidas:" dos commits <rev-red>..HEAD (regras no cabeçalho, etapa 3).
removidas_autorizadas() {
  ra_tmp=$(mktemp) || return 1
  git -c core.quotepath=off log --format='@@%H%n%(trailers:key=Assercoes-removidas,valueonly,unfold)' "$1..HEAD" 2>/dev/null \
    | tr -d '\r' | while IFS= read -r ra_l; do
    case "$ra_l" in
      @@*) ra_portador=${ra_l#@@}; continue ;;
      "$2 "*) ;;
      *) continue ;;
    esac
    ra_l=$(printf '%s' "$ra_l" | sed 's/[[:space:]]*$//')
    case "$ra_l" in *"("*")") ;; *) ignora_trailer "$ra_portador" "sem (<ref>) no fim" "$ra_l"; continue ;; esac
    ra_ref=${ra_l##*\(}; ra_ref=${ra_ref%\)}
    ra_resto=$(printf '%s' "${ra_l%\(*}" | sed 's/[[:space:]]*$//')
    ra_x=$ra_portador
    ra_ant=${ra_resto% *}
    if [ "${ra_ant##* }" = em ]; then
      ra_x=${ra_resto##* }
      ra_resto=${ra_ant% *}
    fi
    ra_n=${ra_resto##* }
    [ "${ra_resto% *}" = "$2" ] || continue # outro arquivo com o mesmo prefixo
    case "$ra_n" in ""|*[!0-9]*) ignora_trailer "$ra_portador" "número inválido" "$ra_l"; continue ;; esac
    case "$ra_ref" in
      R-[0-9]*) ra_num=${ra_ref#R-} ;;
      D[0-9]*) ra_num=${ra_ref#D} ;;
      "Emenda "[0-9]*) ra_num=${ra_ref#Emenda } ;;
      *) ra_num=x ;;
      D:*) if printf '%s' "${ra_ref#D:}" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then ra_num=0; else ra_num=x; fi ;;
    esac
    case "$ra_num" in *[!0-9]*) ignora_trailer "$ra_portador" "referência não é R-n, D<n>, D:<slug> nem Emenda n" "$ra_l"; continue ;; esac
    if ! ra_xc=$(git rev-parse --verify -q "$ra_x^{commit}"); then
      ignora_trailer "$ra_portador" "commit $ra_x inexistente" "$ra_l"; continue
    fi
    if [ "$ra_xc" = "$(git rev-parse "$1")" ] || ! git merge-base --is-ancestor "$1" "$ra_xc" \
      || ! git merge-base --is-ancestor "$ra_xc" "$ra_portador"; then
      ignora_trailer "$ra_portador" "a remoção não está entre o RED $curto e o commit do trailer" "$ra_l"; continue
    fi
    if ! ref_registrada "$ra_xc^" "$ra_ref"; then
      ignora_trailer "$ra_portador" "$ra_ref não foi registrada sob agentic/projeto/ antes da remoção" "$ra_l"; continue
    fi
    printf '%s %s\n' "$ra_xc" "$ra_n" >> "$ra_tmp"
  done
  ra_total=0
  for ra_xc in $(cut -d' ' -f1 "$ra_tmp" | sort -u); do
    ra_decl=$(awk -v x="$ra_xc" '$1 == x { s += $2 } END { print s + 0 }' "$ra_tmp")
    ra_antes=$(conta_assercoes "$ra_xc^" "$2") && ra_depois=$(conta_assercoes "$ra_xc" "$2") || ra_antes=0 ra_depois=0
    ra_queda=$((ra_antes - ra_depois))
    [ "$ra_decl" -gt "$ra_queda" ] && ra_decl=$ra_queda
    [ "$ra_decl" -gt 0 ] && ra_total=$((ra_total + ra_decl))
  done
  rm -f "$ra_tmp"
  echo "$ra_total"
}

# Cache (4): uma prova legítima (o teste falhou no RED) é guardada em <git-common-dir>/agentic/red-provados, uma
# linha "<sha do RED> <assinatura> <arquivo>" (prova pela suíte: arquivo = *suite*). A assinatura depende do caminho
# de prova: pelo executor n, o hash de TESTE_<n>_PADROES, _PREPARO, _COMANDO e _RC_RED (mudar um executor não
# invalida a prova dos outros); por CMD_TESTE_ARQUIVO ou pela suíte, o hash de CMD_PREPARAR_TESTE, CMD_TESTE_ARQUIVO
# e CMD_TESTE. Migração: com executores configurados, um RED que tem prova *suite* guardada, de qualquer assinatura,
# conta como provado ("provado antes pela suíte (assinatura anterior)"). O diretório comum é compartilhado entre
# worktrees. Nunca se guarda RED que passava, comando não encontrado, código fora do RC_RED nem preparo com falha.
# A recusa de produção e a contagem de asserções rodam sempre. AGENTIC_RED_SEM_CACHE=1 ignora a leitura.
cache_dir=$(git rev-parse --git-common-dir 2>/dev/null | tr -d '\r')
case "$cache_dir" in
  "") cache_arq="" ;; # sem diretório comum: cache desligado (nem leitura nem gravação)
  /*|?:*) cache_arq="$cache_dir/agentic/red-provados" ;;
  *) cache_dir="$agentic_raiz/$cache_dir"; cache_arq="$cache_dir/agentic/red-provados" ;;
esac
# assinatura_de <tipo>: n (executor) → hash dos quatro campos do bloco; a (CMD_TESTE_ARQUIVO) ou s (suíte) → hash
# de CMD_PREPARAR_TESTE, CMD_TESTE_ARQUIVO e CMD_TESTE.
assinatura_de() {
  case $1 in
    a|s) printf '%s\n%s\n%s\n' "$CMD_PREPARAR_TESTE" "$CMD_TESTE_ARQUIVO" "$CMD_TESTE" ;;
    *) for as_k in PADROES PREPARO COMANDO RC_RED; do agentic_executor_campo "$1" "$as_k"; done ;;
  esac | git hash-object --stdin
}
assinatura_de s >/dev/null || cache_arq=""

# red_provado <sha> <arquivo> <assinatura>: 0 se há prova guardada com essa assinatura (e o cache não está desligado).
red_provado() {
  [ "${AGENTIC_RED_SEM_CACHE:-}" = 1 ] && return 1
  [ -n "$cache_arq" ] && [ -f "$cache_arq" ] && [ -n "$3" ] || return 1
  RP_SHA=$1 RP_SIG=$3 RP_ARQ=$2 awk '
    BEGIN { sha = ENVIRON["RP_SHA"]; sig = ENVIRON["RP_SIG"]; arq = ENVIRON["RP_ARQ"] }
    { sub(/\r$/, "") }
    $1 == sha && $2 == sig && substr($0, length(sha) + length(sig) + 3) == arq { ok = 1 }
    END { exit ok ? 0 : 1 }' "$cache_arq"
}

# red_provado_suite <sha>: 0 se há prova *suite* guardada para o RED, com qualquer assinatura (migração).
red_provado_suite() {
  [ "${AGENTIC_RED_SEM_CACHE:-}" = 1 ] && return 1
  [ -n "$cache_arq" ] && [ -f "$cache_arq" ] || return 1
  RP_SHA=$1 awk '
    BEGIN { sha = ENVIRON["RP_SHA"] }
    { sub(/\r$/, "") }
    $1 == sha && NF == 3 && $3 == "*suite*" { ok = 1 }
    END { exit ok ? 0 : 1 }' "$cache_arq"
}

# guarda_prova <sha> <arquivo> <assinatura>: acrescenta a prova ao cache (falha de gravação não derruba a verificação).
guarda_prova() {
  [ -n "$cache_arq" ] && [ -n "$3" ] || return 0
  mkdir -p "$cache_dir/agentic" 2>/dev/null || return 0
  printf '%s %s %s\n' "$1" "$3" "$2" >> "$cache_arq" 2>/dev/null
  return 0
}

# aspas <texto>: o texto entre aspas simples, pronto para eval.
aspas() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

# troca <texto> <marca> <valor>: cada ocorrência literal da marca trocada pelo valor (o valor não é relido).
troca() {
  tr_resto=$1; tr_saida=""
  while :; do
    case "$tr_resto" in
      *"$2"*) tr_saida="$tr_saida${tr_resto%%"$2"*}$3"; tr_resto=${tr_resto#*"$2"} ;;
      *) break ;;
    esac
  done
  printf '%s%s' "$tr_saida" "$tr_resto"
}

# classe_jvm <caminho no disco> <arquivo>: nome qualificado JVM — linha "package" do arquivo + nome sem extensão;
# arquivo sem "package" dá só o nome.
classe_jvm() {
  cj_nome=${2##*/}; cj_nome=${cj_nome%.*}
  cj_pac=$(tr -d '\r' < "$1" 2>/dev/null | sed -n 's/^[[:space:]]*package[[:space:]][[:space:]]*\([A-Za-z0-9_.]*\).*/\1/p' | head -n 1)
  printf '%s\n' "${cj_pac:+$cj_pac.}$cj_nome"
}

# comando_arquivo <modelo> <arquivo> [worktree]: o modelo com cada {} trocado pelo caminho entre aspas simples; com
# o worktree (executor), também cada {classe} pela classe JVM do arquivo, entre aspas simples.
comando_arquivo() {
  cf_saida=$1
  if [ -n "${3:-}" ]; then
    case "$cf_saida" in *"{classe}"*) cf_saida=$(troca "$cf_saida" '{classe}' "$(aspas "$(classe_jvm "$3/$2" "$2")")") ;; esac
  fi
  troca "$cf_saida" '{}' "$(aspas "$2")"
}

# avalia_rc <rc> <rotulo> <comando> <chave-do-cache> [rc_red]: interpreta o código de saída de uma execução de teste no
# RED (com rc_red, só esse código é RED); só a falha legítima é guardada no cache, com a assinatura em $sig.
# Retorna 1 quando a execução bloqueia.
avalia_rc() {
  case $1 in
    0)
      echo "agentic: BLOQUEADO — os testes PASSAVAM no RED $curto ($2): não é evidência de RED."
      status=1; return 1 ;;
    126|127)
      echo "agentic: BLOQUEADO — comando de teste não encontrado/não executável no RED $curto (código $1): $3"
      status=1; return 1 ;;
  esac
  if [ -n "${5:-}" ] && [ "$1" -ne "$5" ]; then
    echo "agentic: BLOQUEADO — $2 não é evidência no RED $curto (código $1, esperado $5)"
    status=1; return 1
  fi
  echo "RED $curto: falhava ($2) (ok)"
  # rc >= 124 é timeout (124) ou sinal (>= 128): execução interrompida não é prova permanente.
  [ "$1" -ge 124 ] || guarda_prova "$c" "$4" "$sig"
  return 0
}

# Log (6): a saída do preparo e de cada execução vai para agentic/.estado/verifica-red.log, reescrito a cada
# execução do script: "== RED <sha> <arquivo|*suite*|preparo> (<executor n|CMD_TESTE_ARQUIVO|CMD_TESTE|
# CMD_PREPARAR_TESTE>)", a saída e "-- <código> em <s> s". Em bloqueio, as últimas 40 linhas daquela execução
# são repetidas na saída.
log_red=agentic/.estado/verifica-red.log
{ mkdir -p agentic/.estado && : > "$log_red"; } 2>/dev/null || log_red=/dev/null
# executa <rotulo> <origem> <comando>: roda o comando na raiz do worktree, com </dev/null (um comando que lê stdin
# não pode consumir a lista de arquivos); anexa a seção ao log e deixa o código em ex_rc.
executa() {
  ex_ini=$(date +%s)
  ( cd "$wt" && eval "$3" ) >"$saida_ex" 2>&1 </dev/null
  ex_rc=$?
  { echo "== RED $curto $1 ($2)"; cat "$saida_ex"; echo "-- $ex_rc em $(( $(date +%s) - ex_ini )) s"; } >> "$log_red" 2>/dev/null
  return 0
}
trecho() { echo "== (falhou; últimas 40 linhas)"; tail -n 40 "$saida_ex"; }

status=0
tab=$(printf '\t')
nl='
'
lista=$(mktemp) || agentic_falha "mktemp falhou"
pend=$(mktemp) || { rm -f "$lista"; agentic_falha "mktemp falhou"; }
saida_ex=$(mktemp) || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "mktemp falhou"; }
for c in $reds; do
  curto=$(git rev-parse --short "$c")

  arquivos=$(git -c core.quotepath=off diff-tree --no-commit-id --name-only -r "$c") \
    || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "falha ao listar arquivos do RED $curto"; }
  : > "$lista" # arquivos de teste tocados pelo RED que têm asserção no RED, um por linha
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    dentro=1
    teste=1
    # Documentação não é código de produção: os scripts só leem agentic/projeto/specs/*/tasks/*.md e agentic/projeto/intent/.
    case "$f" in docs/*|agentic/projeto/*) dentro=0 ;; esac
    if agentic_e_teste "$f"; then dentro=0; teste=0; fi
    if [ "$dentro" -ne 0 ]; then
      echo "agentic: BLOQUEADO — RED $curto toca arquivo fora dos diretórios de teste (código de produção): $f"
      status=1
    elif [ "$teste" -eq 0 ]; then
      n=$(conta_assercoes "$c" "$f") || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "falha ao contar asserções no RED $curto (git grep com erro; MARCADOR_ASSERCAO='$MARCADOR_ASSERCAO')"; }
      [ "$n" -gt 0 ] && printf '%s\n' "$f" >> "$lista"
    fi
  done <<EOT
$arquivos
EOT

  if [ -n "$por_arquivo" ] && [ ! -s "$lista" ]; then
    echo "agentic: BLOQUEADO — RED $curto não toca nenhum arquivo de teste com asserção ('$MARCADOR_ASSERCAO'): não há o que provar por arquivo."
    status=1
  fi

  # Caminho de prova de cada arquivo ($pend: "<tipo>\t<arquivo>"; tipo = n do executor, a = CMD_TESTE_ARQUIVO,
  # s = suíte, no máximo uma por RED). O que já foi provado neste SHA com a assinatura do caminho sai da lista.
  : > "$pend"
  if [ -z "$por_arquivo" ]; then
    if red_provado "$c" '*suite*' "$(assinatura_de s)"; then
      echo "RED $curto: já provado (*suite*) (ok)"
    else
      printf 's\t*suite*\n' > "$pend"
    fi
  else
    antiga=""; migrado=""; suite=""
    [ -n "$executores" ] && red_provado_suite "$c" && antiga=1
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if tipo=$(agentic_executor "$f"); then
        chave=$f
      elif [ -n "$CMD_TESTE_ARQUIVO" ]; then
        tipo=a; chave=$f
      else
        echo "degradado: $f sem executor — RED provado pela suíte inteira"
        [ -z "$suite" ] || continue
        suite=1; tipo=s; chave='*suite*'
      fi
      if red_provado "$c" "$chave" "$(assinatura_de "$tipo")"; then
        echo "RED $curto: já provado ($chave) (ok)"
      elif [ -n "$antiga" ]; then
        migrado=1
      else
        printf '%s\t%s\n' "$tipo" "$chave" >> "$pend"
      fi
    done < "$lista"
    if [ -n "$migrado" ]; then
      echo "RED $curto: provado antes pela suíte (assinatura anterior) (ok)"
      : > "$pend"
    fi
  fi

  if [ -s "$pend" ]; then
    wt=$(mktemp -d)
    rmdir "$wt"
    git worktree add -q --detach "$wt" "$c" || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "não foi possível criar worktree para $curto"; }
    # Entre worktree add e remove não há saída via agentic_falha: o worktree é sempre removido.
    # Preparo: o TESTE_<n>_PREPARO de cada executor usado (distintos, na ordem de n) e o CMD_PREPARAR_TESTE quando há
    # prova por CMD_TESTE_ARQUIVO ou pela suíte. Qualquer falha bloqueia o RED sem rodar os testes.
    prep_ok=1; vistos=$nl
    for tipo in $(cut -f1 "$pend" | grep -E '^[0-9]+$' | sort -n -u); do
      p=$(agentic_executor_campo "$tipo" PREPARO)
      [ -n "$p" ] || continue
      case "$vistos" in *"$nl$p$nl"*) continue ;; esac
      vistos="$vistos$p$nl"
      executa preparo "executor $tipo" "$p"
      if [ "$ex_rc" -ne 0 ]; then
        echo "agentic: BLOQUEADO — TESTE_${tipo}_PREPARO falhou no RED $curto; não há evidência."
        trecho; status=1; prep_ok=""; break
      fi
    done
    if [ -n "$prep_ok" ] && [ -n "$CMD_PREPARAR_TESTE" ] && grep -q "^[as]$tab" "$pend"; then
      executa preparo CMD_PREPARAR_TESTE "$CMD_PREPARAR_TESTE"
      if [ "$ex_rc" -ne 0 ]; then
        echo "agentic: BLOQUEADO — CMD_PREPARAR_TESTE falhou no RED $curto; não há evidência."
        trecho; status=1; prep_ok=""
      fi
    fi
    if [ -n "$prep_ok" ]; then
      while IFS="$tab" read -r tipo f; do
        [ -n "$tipo" ] || continue
        rcr=""
        case $tipo in
          s) cmd=$CMD_TESTE; rot="suíte inteira"; origem=CMD_TESTE ;;
          a) cmd=$(comando_arquivo "$CMD_TESTE_ARQUIVO" "$f"); rot=$f; origem=CMD_TESTE_ARQUIVO ;;
          *) cmd=$(comando_arquivo "$(agentic_executor_campo "$tipo" COMANDO)" "$f" "$wt"); rot=$f; origem="executor $tipo"
             rcr=$(agentic_executor_campo "$tipo" RC_RED) ;;
        esac
        sig=$(assinatura_de "$tipo")
        executa "$f" "$origem" "$cmd"
        avalia_rc "$ex_rc" "$rot" "$cmd" "$f" "$rcr" || trecho
      done < "$pend"
    fi
    git worktree remove --force "$wt"
  fi

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    a_red=$(conta_assercoes "$c" "$f") || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "falha ao contar asserções no RED $curto (git grep com erro; MARCADOR_ASSERCAO='$MARCADOR_ASSERCAO')"; }
    a_head=$(conta_assercoes HEAD "$f") || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "falha ao contar asserções em HEAD (git grep com erro; MARCADOR_ASSERCAO='$MARCADOR_ASSERCAO')"; }
    [ "$a_head" -lt "$a_red" ] || continue
    rem=$(removidas_autorizadas "$c" "$f") || { rm -f "$lista" "$pend" "$saida_ex"; agentic_falha "mktemp falhou"; }
    if [ "$a_head" -lt $((a_red - rem)) ]; then
      sufixo=""
      [ "$rem" -gt 0 ] && sufixo=" (removidas autorizadas: $rem)"
      echo "agentic: BLOQUEADO — asserções diminuíram desde o RED $curto em $f: $a_red -> $a_head$sufixo"
      status=1
    else
      echo "verifica-red: $f: $a_red -> $a_head desde o RED $curto, com $rem removidas autorizadas por trailer (ok)"
    fi
  done < "$lista"
done

# --- Vínculo CA -> teste (task da branch): cada CA da seção precisa de "→ test: <arquivo>::<nome>", e o arquivo
# anotado precisa ter sido tocado por um commit RED. Task sem nenhuma anotação (anterior a esta versão do kit)
# só gera aviso; branch sem task (trilha rápida) não é checada.
# (vinc_task é resolvida antes da lista de commits RED.)
if [ -n "$vinc_task" ]; then
  if [ -n "$vinc_ca" ]; then
    vinc_ann=$(printf '%s\n' "$vinc_ca" | grep -c '→ test:')
    if [ "$vinc_ann" -eq 0 ]; then
      echo "aviso: task sem anotação → test: (anterior a esta versão do kit) — vínculo CA → teste não verificado"
    else
      vinc_tocados=$(for c in $reds; do git -c core.quotepath=off diff-tree --no-commit-id --name-only -r "$c"; done | sort -u)
      printf '%s\n' "$vinc_ca" | while IFS= read -r vinc_l; do
        vinc_id=$(printf '%s' "$vinc_l" | grep -oE 'CA[0-9]+' | head -n 1)
        case "$vinc_l" in
          *"→ test:"*) ;;
          *) echo "agentic: BLOQUEADO — $vinc_id sem → test: na task $vinc_task"; continue ;;
        esac
        vinc_resto=${vinc_l#*→ test:}
        printf '%s\n' "$vinc_resto" | awk '{gsub(/; /,"\n")}1' | while IFS= read -r vinc_i; do
          vinc_a=${vinc_i%%::*}
          vinc_a=$(printf '%s' "$vinc_a" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
          [ -n "$vinc_a" ] || { echo "agentic: BLOQUEADO — $vinc_id com → test: sem arquivo na task $vinc_task"; continue; }
          printf '%s\n' "$vinc_tocados" | grep -qxF -- "$vinc_a" \
            || echo "agentic: BLOQUEADO — $vinc_a anotado em $vinc_id não foi tocado por commit test(red):"
        done
      done > "$lista"
      if [ -s "$lista" ]; then cat "$lista"; status=1; fi
    fi
  fi
fi
rm -f "$lista" "$pend" "$saida_ex"
exit $status
