# lib-guarda.sh — funções dos hooks do Codex e do Antigravity (carregue com ".").
# As listas (comandos-negados.txt, caminhos-protegidos.txt) espelham o deny de .claude/settings.json;
# o coerencia-kit do kit confere. Lista ausente bloqueia: proteção que some não pode virar liberação.

# guarda_norm <caminho>: forma canônica para comparar. Barras "/", tudo em minúsculas (o Windows não distingue),
# drive "/c/" vira "c:/", "//" vira "/", "." e "x/.." se resolvem, e o ponto ou espaço no fim de um nome some
# (o Windows grava "config." como "config").
guarda_norm() {
  printf '%s\n' "$1" | tr '\\' '/' | tr '[:upper:]' '[:lower:]' | sed -E \
    -e 's#^/([a-z])/#\1:/#' -e 's#/+#/#g' \
    -e ':p' -e 's#/\./#/#g' -e 'tp' -e 's#^(\./)+##' -e 's#/\.$##' \
    -e ':q' -e 's#(^|/)([^/.][^/]*|\.[^/.][^/]*)/\.\.(/|$)#\1#' -e 'tq' \
    -e 's#([^/.])[. ]+(/|$)#\1\2#g' -e 's#(.)/$#\1#'
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
# Escapes: \\ \" \/ \n \t (vira espaço), \r \b \f (somem) e o escape unicode de 00 a 7F (há codificador que escreve
# "&" assim); fora dessa faixa o escape fica como está.
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
  printf '%s\n' "$gt_v" | awk '
    function hx(c) { return index("0123456789abcdef", tolower(c)) - 1 }
    {
      gsub(/\\\\/, "\001")
      out = ""
      while (match($0, /[\\]u00[0-7][0-9a-fA-F]/)) {
        n = hx(substr($0, RSTART + 4, 1)) * 16 + hx(substr($0, RSTART + 5, 1))
        if (n == 10) ch = "\n"; else if (n == 9) ch = " "; else if (n == 92) ch = "\001"
        else if (n < 32 || n == 127) ch = ""; else ch = sprintf("%c", n)
        out = out substr($0, 1, RSTART - 1) ch
        $0 = substr($0, RSTART + 6)
      }
      $0 = out $0
      gsub(/\\n/, "\n"); gsub(/\\t/, " "); gsub(/\\[rbf]/, ""); gsub(/\\\//, "/"); gsub(/\\"/, "\"")
      gsub(/\001/, "\\"); print
    }'
}

# guarda_negado <comando> <lista>: 0 se algum trecho começa por um prefixo da lista seguido de espaço ou fim.
# Compara em minúsculas, com espaços e tabs reduzidos a um espaço. Trechos: separados por ; & | ( ) { } crase e
# quebra de linha. Em cada trecho, tira (repetindo) aspas, $ e ! iniciais, palavras-chave (then, do, if…), env,
# command, exec, atribuições VAR=x e os embrulhos de shell (bash/sh [opções] -c, powershell/pwsh [opções]
# -Command/-c, cmd /c). Depois reduz o lançador do Windows (git -c alias.agentic-sh=!sh agentic-sh), bash e sh.exe
# a "sh", e tira as opções globais do git (-C x, -c k=v, --no-pager…). Bloquear demais é aceito; deixar passar não.
guarda_negado() {
  gn_lista=$(guarda_lista "$2") || return 0
  gn_lista=$(printf '%s\n' "$gn_lista" | tr '[:upper:]' '[:lower:]' | tr -s ' \t' '  ')
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr ';&|(){}`' '\n\n\n\n\n\n\n\n' | tr -s ' \t' '  ' | sed -E \
    -e ':a' \
    -e 's/^[[:space:]]+//' \
    -e "s/^[\"'\$!]+//" \
    -e 's/^(then|do|else|elif|if|while|until|env|command|exec|nohup|time|sudo|[a-z_][a-z0-9_]*=[^ ]*) +//' \
    -e 's/^(bash|sh)(\.exe)?( +-[-a-z]+)* +-[a-z]*c +//' \
    -e 's/^(powershell|pwsh)(\.exe)?( +-(executionpolicy|ep|windowstyle|w|workingdirectory|wd|outputformat|of|inputformat|if|configurationname) +[^ ]+| +-[a-z]+)* +-c(ommand)? +//' \
    -e 's#^cmd(\.exe)?( +/[a-z]+)+ +##' \
    -e 'ta' \
    -e "s/[\"'[:space:]]+\$//" \
    -e 's/^git -c alias\.agentic-sh=!sh agentic-sh /sh /' \
    -e 's/^(bash|bash\.exe|sh\.exe) /sh /' \
    -e ':g' \
    -e 's/^git +(-c +[^ ]+|-c[^ ]+|--(git-dir|work-tree|namespace|exec-path|super-prefix|config-env)(=| +)[^ ]+|--[a-z-]+) +/git /' \
    -e 'tg' | {
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
