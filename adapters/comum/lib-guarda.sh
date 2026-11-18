# lib-guarda.sh — funções dos hooks do Codex e do Antigravity (carregue com ".").
# As listas (comandos-negados.txt, caminhos-protegidos.txt) espelham o deny de .claude/settings.json;
# o coerencia-kit do kit confere. Lista ausente bloqueia: proteção que some não pode virar liberação.

# guarda_norm <caminho>: barras "/", drive "/c/" vira "c:/", tudo em minúsculas (o Windows não distingue).
guarda_norm() {
  printf '%s\n' "$1" | tr '\' '/' | sed -E 's#^/([A-Za-z])/#\1:/#' | tr '[:upper:]' '[:lower:]'
}

# guarda_raiz: raiz do repositório com barras "/" (GUARDA_RAIZ, se definida, vence o git).
guarda_raiz() {
  if [ -n "${GUARDA_RAIZ:-}" ]; then printf '%s\n' "$GUARDA_RAIZ"; else git rev-parse --show-toplevel 2>/dev/null; fi
}

# guarda_lista <arquivo>: imprime as linhas úteis da lista; ausente → mensagem e retorno 1.
guarda_lista() {
  [ -f "$1" ] || { echo "agentic: lista de proteção ausente: $1" >&2; return 1; }
  tr -d '\r' < "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v -e '^#' -e '^$'
}

# guarda_protegido <caminho> <lista>: 0 se o caminho casa um padrão (X casa X e …/X; X/** casa X/… e …/X/…).
guarda_protegido() {
  gp_lista=$(guarda_lista "$2") || return 0
  gp_p=$(guarda_norm "$1")
  gp_r=$(guarda_norm "$(guarda_raiz)")
  [ -n "$gp_r" ] && case "$gp_p" in "$gp_r"/*) gp_p=${gp_p#"$gp_r"/} ;; esac
  while :; do case "$gp_p" in ./*) gp_p=${gp_p#./} ;; *) break ;; esac; done
  printf '%s\n' "$gp_lista" | {
    while IFS= read -r gp_pad; do
      gp_pad=$(guarda_norm "$gp_pad")
      case "$gp_pad" in
        */\*\*) gp_b=${gp_pad%/\*\*}
                case "$gp_p" in "$gp_b"/*|*/"$gp_b"/*) exit 0 ;; esac ;;
        *)      case "$gp_p" in "$gp_pad"|*/"$gp_pad") exit 0 ;; esac ;;
      esac
    done
    exit 1
  }
}

# guarda_texto <json> <campo>: imprime o valor do campo — texto com os escapes JSON desfeitos, ou lista de textos
# juntada com espaço (o Codex pode mandar o comando como lista). Campo ausente: retorno 1.
guarda_texto() {
  gt_j=$(printf '%s' "$1" | tr -d '\r' | tr '\n' ' ')
  if printf '%s' "$gt_j" | grep -qE "\"$2\"[[:space:]]*:[[:space:]]*\""; then
    gt_v=$(printf '%s' "$gt_j" | sed -nE "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"(([^\"\\\\]|\\\\.)*)\".*/\1/p" | head -n 1)
  elif printf '%s' "$gt_j" | grep -qE "\"$2\"[[:space:]]*:[[:space:]]*\["; then
    gt_v=$(printf '%s' "$gt_j" | sed -nE "s/.*\"$2\"[[:space:]]*:[[:space:]]*\[([^]]*)\].*/\1/p" | head -n 1 \
      | grep -oE '"([^"\\]|\\.)*"' | sed -e 's/^"//' -e 's/"$//' | tr '\n' ' ' | sed 's/ $//')
  else
    return 1
  fi
  printf '%s\n' "$gt_v" | awk '{ gsub(/\\\\/, "\001"); gsub(/\\n/, "\n"); gsub(/\\t/, " "); gsub(/\\"/, "\""); gsub(/\001/, "\\"); print }'
}

# guarda_negado <comando> <lista>: 0 se algum trecho (separado por ; & | ou quebra de linha) começa por um
# prefixo da lista seguido de espaço ou fim. Antes, tira o embrulho de shell (bash -lc, powershell -Command, cmd /c)
# e reduz o lançador do Windows (git -c alias.agentic-sh=!sh agentic-sh) a "sh".
guarda_negado() {
  gn_lista=$(guarda_lista "$2") || return 0
  printf '%s\n' "$1" | tr ';&|' '\n\n\n' | sed -E \
    -e 's/^[[:space:]]+//' \
    -e 's/^(bash|sh)(\.exe)?( -[a-z]+)* -[a-z]*c[[:space:]]+//' \
    -e 's/^(powershell|pwsh)(\.exe)?( -[A-Za-z]+)* -[Cc]ommand[[:space:]]+//' \
    -e 's#^cmd(\.exe)? /[cC][[:space:]]+##' \
    -e "s/^[\"'[:space:]]+//" -e "s/[\"'[:space:]]+\$//" \
    -e 's/^git -c alias\.agentic-sh=!sh agentic-sh /sh /' | {
    while IFS= read -r gn_t; do
      [ -n "$gn_t" ] || continue
      printf '%s\n' "$gn_lista" | {
        while IFS= read -r gn_pre; do
          case "$gn_t" in "$gn_pre"|"$gn_pre "*) exit 0 ;; esac
        done
        exit 1
      } && exit 0
    done
    exit 1
  }
}
