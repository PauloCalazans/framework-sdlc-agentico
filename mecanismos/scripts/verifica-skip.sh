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
  if [ -z "$executores" ]; then
    set -f # DIRS_TESTE é pathspec/prefixo, não glob contra o disco
    # Linhas adicionadas em arquivos rastreados sob DIRS_TESTE (commits + working tree).
    # shellcheck disable=SC2086
    saida=$(git -c core.quotepath=off diff "$base" -U0 --no-color -- $DIRS_TESTE) || agentic_falha "git diff falhou contra a base $base"
    n_diff=$(printf '%s\n' "$saida" | grep '^+' | grep -v '^+++' | grep -cE -- "$MARCADOR_DESABILITADO")
    # Conteúdo de arquivos novos não rastreados sob DIRS_TESTE.
    novos=$(git -c core.quotepath=off ls-files --others --exclude-standard) || agentic_falha "falha ao listar arquivos não rastreados"
    n_novos=$(printf '%s\n' "$novos" | while IFS= read -r f; do
        [ -n "$f" ] || continue
        for d in $DIRS_TESTE; do
          case "$f" in "$d"*) cat "$f"; break ;; esac
        done
      done | grep -cE -- "$MARCADOR_DESABILITADO")
    set +f
  else
    # Com executores, a classificação é a do agentic_e_teste (prefixo de DIRS_TESTE ou padrão de TESTE_<n>_PADROES;
    # docs/ e agentic/projeto/ isentos). Os nomes vêm com -z (sem aspas do git); o diff é pedido só para os arquivos
    # de teste, com pathspec literal.
    alterados=$(git -c core.quotepath=off diff --name-only -z "$base" | tr '\0' '\n') || agentic_falha "git diff falhou contra a base $base"
    set --
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in docs/*|agentic/projeto/*) continue ;; esac
      agentic_e_teste "$f" && set -- "$@" ":(literal)$f"
    done <<EOT
$alterados
EOT
    n_diff=0
    if [ $# -gt 0 ]; then
      saida=$(git -c core.quotepath=off diff "$base" -U0 --no-color -- "$@") || agentic_falha "git diff falhou contra a base $base"
      n_diff=$(printf '%s\n' "$saida" | grep '^+' | grep -v '^+++' | grep -cE -- "$MARCADOR_DESABILITADO")
    fi
    novos=$(git -c core.quotepath=off ls-files --others --exclude-standard -z | tr '\0' '\n') || agentic_falha "falha ao listar arquivos não rastreados"
    n_novos=$(printf '%s\n' "$novos" | while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in docs/*|agentic/projeto/*) continue ;; esac
        agentic_e_teste "$f" && cat "$f"
      done | grep -cE -- "$MARCADOR_DESABILITADO")
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
