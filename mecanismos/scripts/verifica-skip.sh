#!/bin/sh
# verifica-skip.sh [base] — falha se a branch desabilita testes ou se o relatório real mostra skips novos.
# Lê o relatório JUnit real (não confia no exit code). Sem configuração, declara-se degradado.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
base=${1:-$(agentic_base)}
status=0

if [ -n "$MARCADOR_DESABILITADO" ]; then
  [ -n "$base" ] || agentic_falha "marcador de teste desabilitado configurado, mas sem base de comparação (branch $BRANCH_PRINCIPAL ausente?)"
  git rev-parse --verify -q "$base^{commit}" >/dev/null || agentic_falha "base inválida: $base"
  # Linhas adicionadas em arquivos rastreados (commits + working tree) e conteúdo de arquivos novos não rastreados.
  saida=$(git diff "$base" -U0 --no-color) || agentic_falha "git diff falhou contra a base $base"
  n_diff=$(printf '%s\n' "$saida" | grep '^+' | grep -v '^+++' | grep -cE -- "$MARCADOR_DESABILITADO")
  n_novos=$(git ls-files --others --exclude-standard | while IFS= read -r f; do cat "$f"; done \
    | grep -cE -- "$MARCADOR_DESABILITADO")
  n=$((n_diff + n_novos))
  if [ "$n" -gt 0 ]; then
    echo "agentic: BLOQUEADO — $n linha(s) adicionada(s) marcam teste como desabilitado (padrão: $MARCADOR_DESABILITADO)."
    status=1
  fi
else
  echo "degradado: MARCADOR_DESABILITADO não configurado — marcadores novos não são verificados."
fi

if [ -n "$RELATORIO_TESTES" ]; then
  arquivos=$(ls $RELATORIO_TESTES 2>/dev/null)
  if [ -z "$arquivos" ]; then
    echo "agentic: BLOQUEADO — relatório de testes não encontrado ($RELATORIO_TESTES). Rode os testes antes."
    status=1
  else
    pulados=$(cat $arquivos | grep -o '<skipped' | wc -l | tr -d ' ')
    limite=$(cat .agentic/baseline-skips 2>/dev/null || echo 0)
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
