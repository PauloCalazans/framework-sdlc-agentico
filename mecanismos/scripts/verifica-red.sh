#!/bin/sh
# verifica-red.sh [base] — prova que cada commit test(red):
#   (1) não tocou código de produção: só DIRS_TESTE; documentação sob docs/ e agentic/projeto/ é isenta (o
#       documento da task pode ser atualizado no mesmo commit);
#   (2) falhava de fato, num worktree isolado no commit RED: com CMD_TESTE_ARQUIVO configurado, roda o
#       comando para CADA arquivo de teste tocado pelo RED (arquivo sob DIRS_TESTE com asserção) e exige
#       que cada um falhe; sem ele, roda CMD_TESTE (suíte inteira) e exige falha — modo degradado;
#   (3) não teve asserções removidas depois, POR ARQUIVO: para cada arquivo de teste tocado pelo RED, o
#       número de linhas que casam MARCADOR_ASSERCAO em HEAD não pode ser menor que no RED (arquivo
#       removido em HEAD conta zero). Arquivos não tocados pelo RED não entram na comparação.
#       Exceção: remoção autorizada, quando uma Ruling, decisão ou emenda de spec tirou o comportamento que as
#       asserções provavam. Um commit da branch declara, num trailer,
#         Assercoes-removidas: <arquivo> <n> [em <sha>] (<R-n | D<n> | Emenda n>)
#       as n asserções removidas no commit X (<sha>, ou o próprio commit do trailer). O trailer só conta se:
#       X vem depois do RED e não depois do commit do trailer; a referência foi acrescentada sob agentic/projeto/
#       entre a base e o pai de X (registrada antes da remoção). O crédito de X é no máximo a queda de asserções
#       do arquivo em X, mesmo com várias declarações; o limite passa a ser (asserções no RED - créditos).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
base=${1:-$(agentic_base)}
[ -n "$base" ] || agentic_falha "sem base de comparação (a branch principal '$BRANCH_PRINCIPAL' existe?)"
git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"

reds=$(git log --format=%H --grep='^test(red):' "$base..HEAD") || agentic_falha "falha ao listar commits"
if [ -z "$reds" ]; then
  echo "verifica-red: nenhum commit test(red): na branch"
  exit 0
fi
[ -n "$CMD_TESTE" ] || agentic_falha "CMD_TESTE não configurado em agentic/config"
[ -n "$MARCADOR_ASSERCAO" ] || agentic_falha "MARCADOR_ASSERCAO vazio em agentic/config — não há como comparar asserções"
[ -n "$(printf '%s' "$DIRS_TESTE" | tr -d '[:space:]')" ] || agentic_falha "DIRS_TESTE vazio em agentic/config"
if [ -z "$CMD_TESTE_ARQUIVO" ]; then
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

# ref_registrada <rev> <ref>: a referência aparece numa linha acrescentada sob agentic/projeto/ entre a base e <rev>.
ref_registrada() {
  git -c core.quotepath=off diff "$base" "$1" -- agentic/projeto/ 2>/dev/null | sed -n 's/^+//p' | grep -v '^++ ' \
    | grep -qE "(^|[^[:alnum:]])$2([^[:alnum:]]|$)"
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
    esac
    case "$ra_num" in *[!0-9]*) ignora_trailer "$ra_portador" "referência não é R-n, D<n> nem Emenda n" "$ra_l"; continue ;; esac
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

# comando_arquivo <arquivo>: CMD_TESTE_ARQUIVO com cada {} trocado pelo caminho entre aspas simples.
comando_arquivo() {
  cf_q="'$(printf '%s' "$1" | sed "s/'/'\\\\''/g")'"
  cf_resto=$CMD_TESTE_ARQUIVO
  cf_saida=""
  while :; do
    case "$cf_resto" in
      *"{}"*)
        cf_saida="$cf_saida${cf_resto%%\{\}*}$cf_q"
        cf_resto=${cf_resto#*\{\}} ;;
      *) break ;;
    esac
  done
  printf '%s%s' "$cf_saida" "$cf_resto"
}

# avalia_rc <rc> <rotulo> <comando>: interpreta o código de saída de uma execução de teste no RED.
avalia_rc() {
  case $1 in
    0)
      echo "agentic: BLOQUEADO — os testes PASSAVAM no RED $curto ($2): não é evidência de RED."
      status=1 ;;
    126|127)
      echo "agentic: BLOQUEADO — comando de teste não encontrado/não executável no RED $curto (código $1): $3"
      status=1 ;;
    *)
      echo "RED $curto: falhava ($2) (ok)" ;;
  esac
}

status=0
lista=$(mktemp) || agentic_falha "mktemp falhou"
for c in $reds; do
  curto=$(git rev-parse --short "$c")

  arquivos=$(git -c core.quotepath=off diff-tree --no-commit-id --name-only -r "$c") \
    || { rm -f "$lista"; agentic_falha "falha ao listar arquivos do RED $curto"; }
  : > "$lista" # arquivos de teste tocados pelo RED que têm asserção no RED, um por linha
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    dentro=1
    teste=1
    # Documentação não é código de produção: os scripts só leem agentic/projeto/specs/*/tasks/*.md e agentic/projeto/intent/.
    case "$f" in docs/*|agentic/projeto/*) dentro=0 ;; esac
    set -f
    for d in $DIRS_TESTE; do
      case "$f" in "$d"*) dentro=0; teste=0 ;; esac
    done
    set +f
    if [ "$dentro" -ne 0 ]; then
      echo "agentic: BLOQUEADO — RED $curto toca arquivo fora dos diretórios de teste (código de produção): $f"
      status=1
    elif [ "$teste" -eq 0 ]; then
      n=$(conta_assercoes "$c" "$f") || { rm -f "$lista"; agentic_falha "falha ao contar asserções no RED $curto (git grep com erro; MARCADOR_ASSERCAO='$MARCADOR_ASSERCAO')"; }
      [ "$n" -gt 0 ] && printf '%s\n' "$f" >> "$lista"
    fi
  done <<EOT
$arquivos
EOT

  if [ -n "$CMD_TESTE_ARQUIVO" ] && [ ! -s "$lista" ]; then
    echo "agentic: BLOQUEADO — RED $curto não toca nenhum arquivo de teste com asserção ('$MARCADOR_ASSERCAO'): não há o que provar por arquivo."
    status=1
  fi

  wt=$(mktemp -d)
  rmdir "$wt"
  git worktree add -q --detach "$wt" "$c" || { rm -f "$lista"; agentic_falha "não foi possível criar worktree para $curto"; }
  # Entre worktree add e remove não há saída via agentic_falha: o worktree é sempre removido.
  if [ -n "$CMD_PREPARAR_TESTE" ] && ! ( cd "$wt" && eval "$CMD_PREPARAR_TESTE" ) >/dev/null 2>&1; then
    echo "agentic: BLOQUEADO — CMD_PREPARAR_TESTE falhou no RED $curto; não há evidência."
    status=1
  elif [ -n "$CMD_TESTE_ARQUIVO" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      cmd=$(comando_arquivo "$f")
      ( cd "$wt" && eval "$cmd" ) >/dev/null 2>&1
      avalia_rc $? "$f" "$cmd"
    done < "$lista"
  else
    ( cd "$wt" && eval "$CMD_TESTE" ) >/dev/null 2>&1
    avalia_rc $? "suíte inteira" "$CMD_TESTE"
  fi
  git worktree remove --force "$wt"

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    a_red=$(conta_assercoes "$c" "$f") || { rm -f "$lista"; agentic_falha "falha ao contar asserções no RED $curto (git grep com erro; MARCADOR_ASSERCAO='$MARCADOR_ASSERCAO')"; }
    a_head=$(conta_assercoes HEAD "$f") || { rm -f "$lista"; agentic_falha "falha ao contar asserções em HEAD (git grep com erro; MARCADOR_ASSERCAO='$MARCADOR_ASSERCAO')"; }
    [ "$a_head" -lt "$a_red" ] || continue
    rem=$(removidas_autorizadas "$c" "$f") || { rm -f "$lista"; agentic_falha "mktemp falhou"; }
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
rm -f "$lista"
exit $status
