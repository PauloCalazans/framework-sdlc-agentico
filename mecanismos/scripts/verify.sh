#!/bin/sh
# verify.sh [--rapido] [--task <task.md>] — ponto único de verificação do projeto. Só reporta; nunca conserta.
# Task com **Base:** <branch> (branch empilhada): enquanto essa branch não estiver na principal, as etapas
# comparam com ela; depois, com a principal.
# Etapas (as baratas primeiro): hooks → escopo → decisões → red → stack → skip (skip lê os JUnit que a stack produz).
# --rapido (o laço): troca a stack por CMD_VERIFY_RAPIDO (vazio = CMD_VERIFY_STACK, com aviso), não roda skip e fecha com
# "VERIFY RÁPIDO: …". O completo roda antes do PR e no revisor diff.
# Cada etapa fecha com a duração em segundos. A saída inteira vai também para agentic/.estado/verify.log
# (rápido: verify-rapido.log); a etapa que falhou é repetida no fim (últimas linhas), logo antes da linha VERIFY.
# Prova do completo: um VERIFY: OK numa árvore limpa é guardado em <git-common-dir>/agentic/verify-provados
# (árvore do HEAD + base + assinatura da config), e o completo seguinte com a mesma chave não roda de novo;
# AGENTIC_VERIFY_SEM_CACHE=1 ignora a leitura. O rápido nunca usa a prova.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/lib-agentic.sh"
cd "$agentic_raiz" || exit 1

task=""; modo=completo
while [ $# -gt 0 ]; do
  case $1 in
    --rapido) modo=rapido; shift ;;
    --task) task=${2:-}; shift; [ $# -gt 0 ] && shift ;;
    *) echo "uso: verify.sh [--rapido] [--task <task.md>]" >&2; exit 2 ;;
  esac
done
[ -n "$CMD_VERIFY_STACK" ] || agentic_falha "CMD_VERIFY_STACK não configurado em agentic/config (rode /bootstrap)"
case "$CMD_VERIFY_RAPIDO" in "{{"*) CMD_VERIFY_RAPIDO="" ;; esac

mkdir -p agentic/.estado
lock="agentic/.estado/verify.lock"
if ! mkdir "$lock" 2>/dev/null; then
  pid=$(cat "$lock/pid" 2>/dev/null)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "verify já em execução (pid $pid)"
    exit 3
  fi
  rm -rf "$lock"
  mkdir "$lock" || exit 3
fi
echo $$ > "$lock/pid"
trap 'rm -rf "$lock"; rm -f "$etapa_saida"' EXIT
etapa_saida=$(mktemp)
log="agentic/.estado/verify.log"; [ "$modo" = rapido ] && log="agentic/.estado/verify-rapido.log"
: > "$log"
# diz <texto>: imprime e grava no log.
diz() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$log"; }
# INT/TERM: o sh só atende o sinal quando a etapa em primeiro plano volta; até lá o lock fica preso. Depois disso
# nenhuma etapa seguinte roda e a saída é 128 + sinal (o trap de EXIT solta o lock). Um trap que só apagasse o lock
# deixaria o verify seguir sem ele até o fim.
interrompido() {
  i_rotulo="VERIFY"; [ "$modo" = rapido ] && i_rotulo="VERIFY RÁPIDO"
  diz ""; diz "$i_rotulo: INTERROMPIDO ($1) — as etapas seguintes não rodaram"
  exit "$2"
}
trap 'interrompido INT 130' INT
trap 'interrompido TERM 143' TERM

falhas=""; trechos=""
# etapa <nome> <comando...>: roda o comando com a saída no terminal e no log, e fecha com o resultado e a duração.
# A saída de cada etapa que falha fica guardada para o fim (trechos).
etapa() {
  nome=$1; shift
  diz ""; diz "== $nome"
  e_t0=$(date +%s)
  rm -f "$lock/rc"
  { "$@"; echo $? > "$lock/rc"; } 2>&1 | tee "$etapa_saida"
  e_rc=$(cat "$lock/rc" 2>/dev/null); e_rc=${e_rc:-1}
  cat "$etapa_saida" >> "$log"
  e_dt=$(( $(date +%s) - e_t0 ))
  if [ "$e_rc" -eq 0 ]; then
    diz "-- $nome: OK ($e_dt s)"
  else
    diz "-- $nome: FALHOU ($e_dt s)"; falhas="$falhas $nome"
    e_trecho=$(mktemp); tail -n 40 "$etapa_saida" > "$e_trecho"; trechos="$trechos $nome:$e_trecho"
  fi
}

# Os githooks valem para qualquer autor, mas core.hooksPath é configuração local: um clone novo
# (outra máquina, agente de nuvem) roda sem eles e nada avisa.
verifica_hooks() {
  atual=$(git config core.hooksPath)
  [ "$atual" = "agentic/mecanismos/githooks" ] && { echo "githooks ligados"; return 0; }
  echo "githooks desligados neste clone (core.hooksPath = '${atual:-<vazio>}')."
  echo "Ligue com: git config core.hooksPath agentic/mecanismos/githooks (ação humana; o agente não altera as próprias proteções)."
  return 1
}
# Base única: todas as etapas comparam com a mesma base (a **Base:** da task empilhada, ainda não integrada,
# ou a principal), calculada uma vez, antes das etapas.
if [ -z "$task" ]; then
  branch=$(git symbolic-ref --short -q HEAD)
  [ -n "$branch" ] && task=$(grep -l "^\*\*Branch:\*\*[[:space:]]*$branch[[:space:]]*$" agentic/projeto/specs/*/tasks/*.md 2>/dev/null | head -n 1)
fi
if [ -n "$task" ]; then
  base_task=$(sed -n 's/^\*\*Base:\*\*[[:space:]]*//p' "$task" | head -n 1 | tr -d '\r`' | sed 's/[[:space:]]*$//')
  if [ -n "$base_task" ]; then
    ref=$(agentic_base_task "$task")
    if [ -n "$ref" ]; then
      AGENTIC_BASE=$ref; export AGENTIC_BASE
      diz ""; diz "base: $ref (branch empilhada, **Base:** da task)"
    else
      diz ""; diz "base: principal (**Base:** $base_task já integrada ou ausente)"
    fi
  fi
fi

# A task chega ao verifica-red (vínculo CA → teste) também quando veio de --task.
[ -n "$task" ] && { AGENTIC_TASK=$task; export AGENTIC_TASK; }
# Prova do completo: chave = árvore do HEAD + base + assinatura (config efetiva, githooks, task). Só vale com a
# árvore limpa (agentic/.estado fora), antes e depois das etapas: a stack que suja a árvore não guarda prova.
prova_arq=""
if [ "$modo" = completo ]; then
  p_dir=$(git rev-parse --git-common-dir 2>/dev/null | tr -d '\r')
  case "$p_dir" in
    "") ;;
    /*|?:*) prova_arq="$p_dir/agentic/verify-provados" ;;
    *) prova_arq="$agentic_raiz/$p_dir/agentic/verify-provados" ;;
  esac
fi
arvore_suja() { git -c core.quotepath=off status --porcelain -- . ':(exclude)agentic/.estado' 2>/dev/null; }
if [ -n "$prova_arq" ]; then
  p_arvore=$(git rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null)
  p_base=$(agentic_base); p_base=${p_base:--}
  p_sig=$(printf '%s\n' "$CMD_PREPARAR_TESTE" "$CMD_TESTE" "$CMD_TESTE_ARQUIVO" "$CMD_VERIFY_STACK" \
    "$RELATORIO_TESTES" "$MARCADOR_DESABILITADO" "$MARCADOR_ASSERCAO" "$DIRS_TESTE" "$CAMINHOS_N3" \
    "$BRANCH_PRINCIPAL" "$(git config core.hooksPath)" "$task" | git hash-object --stdin)
  [ -n "$p_arvore" ] && [ -n "$p_sig" ] || prova_arq=""
fi
if [ -n "$prova_arq" ] && [ -n "$(arvore_suja)" ]; then
  diz ""; diz "prova do completo: árvore com alterações não commitadas — roda tudo e não guarda prova"
  prova_arq=""
fi
if [ -n "$prova_arq" ] && [ "${AGENTIC_VERIFY_SEM_CACHE:-}" != 1 ] && [ -f "$prova_arq" ]; then
  p_quando=$(awk -v a="$p_arvore" -v b="$p_base" -v s="$p_sig" '$1 == a && $2 == b && $3 == s { q = $4 } END { print q }' "$prova_arq")
  if [ -n "$p_quando" ]; then
    diz ""
    diz "prova do completo: esta árvore ($(printf '%.8s' "$p_arvore")), com esta base e esta config, já deu VERIFY: OK em $p_quando."
    diz "Nenhuma etapa rodou de novo. AGENTIC_VERIFY_SEM_CACHE=1 refaz tudo."
    diz "log: $log"
    diz "VERIFY: OK (já provado nesta árvore)"
    exit 0
  fi
fi

etapa hooks verifica_hooks
if [ -n "$task" ]; then
  etapa escopo sh "$dir/verifica-escopo.sh" "$task"
else
  if [ -n "$(ls agentic/projeto/specs/*/tasks/*.md 2>/dev/null | head -n 1)" ]; then
    diz ""; diz "aviso: nenhuma task com **Branch:** ${branch:-?} — escopo não verificado (trilha rápida?)"
  fi
  diz ""; diz "== escopo: nenhuma task associada à branch (trilha rápida) — pulado"
fi
etapa decisoes sh "$dir/verifica-decisoes.sh"
etapa red sh "$dir/verifica-red.sh"
if [ "$modo" = rapido ]; then
  if [ -z "$CMD_VERIFY_RAPIDO" ]; then
    diz ""; diz "aviso: CMD_VERIFY_RAPIDO não configurado — usando CMD_VERIFY_STACK"
    CMD_VERIFY_RAPIDO=$CMD_VERIFY_STACK
  fi
  etapa stack-rapido sh -c "$CMD_VERIFY_RAPIDO"
  rotulo="VERIFY RÁPIDO"
else
  etapa stack sh -c "$CMD_VERIFY_STACK"
  etapa skip sh "$dir/verifica-skip.sh"
  rotulo="VERIFY"
fi

if [ -z "$falhas" ] && [ -n "$prova_arq" ]; then
  p_suja=$(arvore_suja)
  if [ -n "$p_suja" ]; then
    diz ""; diz "prova do completo não guardada: as etapas deixaram a árvore com alterações:"
    printf '%s\n' "$p_suja" | sed 's/^/  /' | tee -a "$log"
  else
    mkdir -p "${prova_arq%/*}" 2>/dev/null
    printf '%s %s %s %s\n' "$p_arvore" "$p_base" "$p_sig" "$(date +%Y-%m-%dT%H:%M:%S)" >> "$prova_arq" 2>/dev/null
  fi
fi

for t in $trechos; do
  diz ""; diz "== ${t%%:*} (falhou; últimas 40 linhas da etapa)"
  cat "${t#*:}" | tee -a "$log"; rm -f "${t#*:}"
done
diz ""
diz "log: $log"
if [ -z "$falhas" ]; then
  diz "$rotulo: OK"
else
  diz "$rotulo: FALHOU em:$falhas"
  exit 1
fi
