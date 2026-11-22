#!/bin/sh
# verifica-skip.sh [base] — falha se a branch desabilita testes ou se o relatório real mostra skips novos.
# Lê o relatório JUnit real (não confia no exit code). Sem configuração, declara-se degradado.
# A varredura de marcador considera só arquivos de teste (agentic_e_teste: prefixo de DIRS_TESTE ou padrão de
# TESTE_<n>_PADROES; docs/ e agentic/projeto/ isentos), porque documentação e scripts podem citar o padrão.
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
  [ -n "$(printf '%s' "$DIRS_TESTE" | tr -d '[:space:]')" ] || [ -n "$(agentic_executores 2>/dev/null)" ] || \
    agentic_falha "MARCADOR_DESABILITADO configurado, mas DIRS_TESTE vazio em agentic/config"
  # Linhas adicionadas em arquivos de teste rastreados (commits + working tree), separadas por arquivo: o cabeçalho
  # "+++ b/<arquivo>" só é lido entre "diff --git" e o primeiro "@@" (linha adicionada que começa com "++" não conta).
  saida=$(git -c core.quotepath=off diff "$base" -U0 --no-color) || agentic_falha "git diff falhou contra a base $base"
  tab=$(printf '\t')
  n_diff=$(printf '%s\n' "$saida" | {
      cab=0; conta=""
      while IFS= read -r l; do
        case "$l" in
          "diff --git "*) cab=1; conta=""; continue ;;
          "@@"*) cab=0; continue ;;
        esac
        if [ "$cab" -eq 1 ]; then
          case "$l" in
            "+++ b/"*)
              f=${l#+++ b/}; f=${f%"$tab"}
              case "$f" in docs/*|agentic/projeto/*) conta="" ;; *) agentic_e_teste "$f" && conta=1 ;; esac ;;
          esac
          continue
        fi
        case "$l" in "+"*) [ -n "$conta" ] && printf '%s\n' "$l" ;; esac
      done; } | grep -cE -- "$MARCADOR_DESABILITADO")
  # Conteúdo de arquivos de teste novos não rastreados.
  novos=$(git -c core.quotepath=off ls-files --others --exclude-standard) || agentic_falha "falha ao listar arquivos não rastreados"
  n_novos=$(printf '%s\n' "$novos" | while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in docs/*|agentic/projeto/*) continue ;; esac
      agentic_e_teste "$f" && cat "$f"
    done | grep -cE -- "$MARCADOR_DESABILITADO")
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
  # shellcheck disable=SC2086
  for a in $RELATORIO_TESTES; do
    [ -f "$a" ] || continue
    encontrados=$((encontrados + 1))
    n=$(grep -o '<skipped' "$a" | wc -l | tr -d ' ')
    case $n in ''|*[!0-9]*) agentic_falha "contagem de skips inválida em '$a': '$n'";; esac
    pulados=$((pulados + n))
  done
  if [ "$encontrados" -eq 0 ]; then
    echo "agentic: BLOQUEADO — relatório de testes não encontrado ($RELATORIO_TESTES). Rode os testes antes."
    status=1
  else
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
