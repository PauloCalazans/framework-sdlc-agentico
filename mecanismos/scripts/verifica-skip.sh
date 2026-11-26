#!/bin/sh
# verifica-skip.sh [base] — falha se a branch desabilita testes ou se o relatório real mostra skips novos.
# Lê o relatório JUnit real (não confia no exit code). Sem configuração, declara-se degradado.
# A varredura de marcador considera só arquivos de teste, porque documentação e scripts podem citar o padrão: sem
# executor, os sob DIRS_TESTE (pathspec, como antes); com executores, os do agentic_e_teste (prefixo de DIRS_TESTE
# ou padrão de TESTE_<n>_PADROES; docs/ e agentic/projeto/ isentos).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
if [ -n "${1:-}" ]; then
  base=$(git merge-base HEAD "$1") || agentic_falha "base inválida: $1"
else
  base=$(agentic_base)
fi
status=0

if [ -n "$MARCADOR_DESABILITADO" ]; then
  [ -n "$base" ] || agentic_falha "marcador de teste desabilitado configurado, mas sem base de comparação (branch $BRANCH_PRINCIPAL ausente?)"
  git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"
  agentic_executores >/dev/null # avisa bloco TESTE_<n> ignorado
  executores=$(agentic_executores 2>/dev/null)
  [ -n "$(printf '%s' "$DIRS_TESTE" | tr -d '[:space:]')" ] || [ -n "$executores" ] || \
    agentic_falha "MARCADOR_DESABILITADO configurado, mas DIRS_TESTE vazio em agentic/config"
  # Filtro em lote (um único awk): classifica arquivos alterados e não rastreados sem abrir processo por arquivo.
  awk_filtra='
    function glob2ere(g,    i, c, out, in_cls) {
      out = "^"; in_cls = 0
      for (i = 1; i <= length(g); i++) {
        c = substr(g, i, 1)
        if (in_cls) {
          if (c == "]") { out = out "]"; in_cls = 0 }
          else if (c == "\\") { i++; out = out "\\" substr(g, i, 1) }
          else out = out c
        } else if (c == "\\") {
          i++; if (i <= length(g)) out = out "\\" substr(g, i, 1)
        } else if (c == "*") {
          out = out ".*"
        } else if (c == "?") {
          out = out "."
        } else if (c == "[") {
          in_cls = 1; out = out "["
          if (substr(g, i + 1, 1) == "!") { out = out "^"; i++ }
        } else if (index(".+(){}^$|", c) > 0) {
          out = out "\\" c
        } else {
          out = out c
        }
      }
      return out "$"
    }
    BEGIN {
      nd = split(ENVIRON["VS_DIRS"], dirs, /[[:space:]]+/)
      np = split(ENVIRON["VS_PADS"], raw_pads, /[[:space:]]+/)
      kp = 0
      for (i = 1; i <= np; i++) {
        if (raw_pads[i] != "") { kp++; pads[kp] = glob2ere(raw_pads[i]) }
      }
      isenta = ENVIRON["VS_ISENTA"] + 0
      modo = ENVIRON["VS_MODO"]
    }
    {
      f = $0
      if (f == "") next
      if (isenta && (index(f, "docs/") == 1 || index(f, "agentic/projeto/") == 1)) next
      ok = 0
      for (i = 1; i <= nd; i++) {
        if (dirs[i] != "" && index(f, dirs[i]) == 1) { ok = 1; break }
      }
      if (!ok) {
        for (i = 1; i <= kp; i++) {
          if (f ~ pads[i]) { ok = 1; break }
        }
      }
      if (!ok) next
      if (modo == "pathspec") {
        print ":(literal)" f
      } else {
        while ((getline l < f) > 0) print l
        close(f)
      }
    }
  '
  if [ -z "$executores" ]; then
    set -f # DIRS_TESTE é pathspec/prefixo, não glob contra o disco
    # Linhas adicionadas em arquivos rastreados sob DIRS_TESTE (commits + working tree).
    # shellcheck disable=SC2086
    saida=$(git -c core.quotepath=off diff "$base" -U0 --no-color -- $DIRS_TESTE) || agentic_falha "git diff falhou contra a base $base"
    n_diff=$(printf '%s\n' "$saida" | grep '^+' | grep -v '^+++' | grep -cE -- "$MARCADOR_DESABILITADO")
    # Conteúdo de arquivos novos não rastreados sob DIRS_TESTE.
    n_novos=$(git -c core.quotepath=off ls-files --others --exclude-standard -z | tr '\0' '\n' \
      | VS_DIRS="$DIRS_TESTE" VS_PADS="" VS_ISENTA=0 VS_MODO=conteudo awk "$awk_filtra" \
      | grep -cE -- "$MARCADOR_DESABILITADO")
    set +f
  else
    # Com executores, a classificação é a do agentic_e_teste (prefixo de DIRS_TESTE ou padrão de TESTE_<n>_PADROES;
    # docs/ e agentic/projeto/ isentos). Os nomes vêm com -z (sem aspas do git); o diff é pedido só para os arquivos
    # de teste, com pathspec literal via xargs (evita limite de linha de comando).
    todos_padroes=""
    for n in $executores; do
      todos_padroes="$todos_padroes $(agentic_executor_campo "$n" PADROES)"
    done
    lista_tmp=$(mktemp) || agentic_falha "mktemp falhou"
    git -c core.quotepath=off diff --name-only -z "$base" | tr '\0' '\n' \
      | VS_DIRS="$DIRS_TESTE" VS_PADS="$todos_padroes" VS_ISENTA=1 VS_MODO=pathspec awk "$awk_filtra" > "$lista_tmp" \
      || { rm -f "$lista_tmp"; agentic_falha "git diff falhou contra a base $base"; }
    n_diff=0
    if [ -s "$lista_tmp" ]; then
      n_diff=$(tr '\n' '\0' < "$lista_tmp" | xargs -0 git -c core.quotepath=off diff "$base" -U0 --no-color -- \
        | grep '^+' | grep -v '^+++' | grep -cE -- "$MARCADOR_DESABILITADO")
    fi
    rm -f "$lista_tmp"
    n_novos=$(git -c core.quotepath=off ls-files --others --exclude-standard -z | tr '\0' '\n' \
      | VS_DIRS="$DIRS_TESTE" VS_PADS="$todos_padroes" VS_ISENTA=1 VS_MODO=conteudo awk "$awk_filtra" \
      | grep -cE -- "$MARCADOR_DESABILITADO")
  fi
  n=$((n_diff + n_novos))
  if [ "$n" -gt 0 ]; then
    echo "agentic: BLOQUEADO — $n linha(s) adicionada(s) marcam teste como desabilitado (padrão: $MARCADOR_DESABILITADO)."
    status=1
  fi
else
  echo "degradado: MARCADOR_DESABILITADO não configurado — marcadores novos não são verificados."
fi

if [ -n "$RELATORIO_TESTES" ]; then
  encontrados=0
  pulados=0
  set +f
  # O padrão é expandido como glob; os nomes resultantes (mesmo com espaço) não são re-divididos.
  # Contagem em uma única passada de awk (evita abrir processos por XML e limite de linha de comando).
  # shellcheck disable=SC2086
  set --
  for a in $RELATORIO_TESTES; do
    [ -f "$a" ] || continue
    set -- "$@" "$a"
  done
  encontrados=$#
  if [ "$encontrados" -eq 0 ]; then
    echo "agentic: BLOQUEADO — relatório de testes não encontrado ($RELATORIO_TESTES). Rode os testes antes."
    status=1
  else
    pulados=$(printf '%s\n' "$@" | awk '
      {
        f = $0
        while ((getline l < f) > 0) c += gsub(/<skipped/, "&", l)
        close(f)
      }
      END { print c + 0 }
    ')
    case $pulados in ''|*[!0-9]*) agentic_falha "contagem de skips inválida: '$pulados'";; esac
    if [ -f agentic/baseline-skips ]; then
      limite=$(tr -d '\r[:space:]' < agentic/baseline-skips)
    else
      limite=0
    fi
    case $limite in ''|*[!0-9]*) agentic_falha "baseline-skips inválido: '$limite'";; esac
    if [ "$pulados" -gt "$limite" ]; then
      echo "agentic: BLOQUEADO — $pulados teste(s) pulado(s) no relatório; baseline é $limite."
      status=1
    else
      echo "skip: $pulados pulado(s), baseline $limite — OK"
    fi
  fi
else
  echo "degradado: RELATORIO_TESTES não configurado — skips em tempo de execução não são verificados."
fi
exit $status
