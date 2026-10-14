# lib-kit.sh — funções do instalador e da checagem de instância (ficam no kit; não vão para o projeto).
# kit_hash <arquivo>: sha256 do conteúdo sem \r, para um checkout com CRLF (Windows) não parecer edição.
kit_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    tr -d '\r' < "$1" | sha256sum | cut -d' ' -f1
  else
    tr -d '\r' < "$1" | shasum -a 256 | cut -d' ' -f1
  fi
}
# kit_hash_manifesto <manifesto> <caminho relativo>: hash registrado para o caminho (vazio se ausente).
kit_hash_manifesto() {
  [ -f "$1" ] || return 0
  awk -v c="$2" 'substr($0, 67) == c { print substr($0, 1, 64); exit }' "$1"
}
