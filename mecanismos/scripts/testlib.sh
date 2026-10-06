# testlib.sh — mini framework de testes dos mecanismos do framework.
# Uso: . "$(dirname "$0")/testlib.sh" ; tl_espera ... ; tl_contem ... ; tl_fim
TL_TOTAL=0
TL_FALHAS=0
TL_SAIDA=$(mktemp)

# tl_repo: cria um repositório git temporário com commit inicial em main e imprime o caminho.
tl_repo() {
  tl_d=$(mktemp -d)
  git -C "$tl_d" init -q -b main
  git -C "$tl_d" config user.email teste@exemplo.invalid
  git -C "$tl_d" config user.name teste
  git -C "$tl_d" config commit.gpgsign false
  git -C "$tl_d" config core.autocrlf false
  git -C "$tl_d" commit -q --allow-empty -m "inicial"
  printf '%s\n' "$tl_d"
}

# tl_espera <codigo> <descricao> <comando...>: roda o comando e confere o código de saída.
tl_espera() {
  tl_esperado=$1
  tl_desc=$2
  shift 2
  TL_TOTAL=$((TL_TOTAL + 1))
  "$@" >"$TL_SAIDA" 2>&1
  tl_obtido=$?
  if [ "$tl_obtido" -eq "$tl_esperado" ]; then
    printf 'ok    %s\n' "$tl_desc"
  else
    TL_FALHAS=$((TL_FALHAS + 1))
    printf 'FALHA %s (esperado %s, obtido %s)\n' "$tl_desc" "$tl_esperado" "$tl_obtido"
    sed 's/^/      | /' "$TL_SAIDA"
  fi
}

# tl_contem <texto> <descricao>: confere que a saída do último tl_espera contém o texto.
tl_contem() {
  TL_TOTAL=$((TL_TOTAL + 1))
  if grep -qF -- "$1" "$TL_SAIDA"; then
    printf 'ok    %s\n' "$2"
  else
    TL_FALHAS=$((TL_FALHAS + 1))
    printf 'FALHA %s (saída não contém: %s)\n' "$2" "$1"
    sed 's/^/      | /' "$TL_SAIDA"
  fi
}

# tl_fim: imprime o resumo e retorna 1 se houve alguma falha.
tl_fim() {
  rm -f "$TL_SAIDA"
  printf '%s testes, %s falhas\n' "$TL_TOTAL" "$TL_FALHAS"
  [ "$TL_FALHAS" -eq 0 ]
}
