#!/bin/sh
# status-projeto.sh — estado do projeto DERIVADO do git e dos campos **Status:**.
# Nada aqui é escrito à mão. Executado no início de cada sessão (hook SessionStart).
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 0

echo "## Estado do projeto (derivado — não edite à mão)"
echo "Branch atual: $(git symbolic-ref --short -q HEAD || echo '(detached)')"

# Kit: o que mudou no ciclo.md no último commit que o tocou (ou na árvore, se a atualização ainda não foi
# commitada). Importar a atualização não entrega a regra nova: a sessão do orquestrador só relê o que este
# status, injetado no início dela, apontar.
ciclo=agentic/processo/ciclo.md
kit_commit=""
[ -f "$ciclo" ] && kit_commit=$(git log -1 --format='%h %cd' --date=short -- "$ciclo" 2>/dev/null)
# secoes <args do git diff>: seções "## " do ciclo.md atual tocadas pelo diff, na ordem do arquivo, cada uma com
# os itens "**Nome:**" alterados. Linha em branco acrescentada não conta; trecho removido conta na seção onde estava.
secoes() {
  faixas=$(git diff -U0 "$@" -- "$ciclo" 2>/dev/null \
    | sed -n 's/^@@ -[0-9,]* +\([0-9]*\),\{0,1\}\([0-9]*\) @@.*/\1:\2/p' | tr '\n' ' ')
  awk -v faixas="$faixas" '
    BEGIN {
      n = split(faixas, f, " ")
      for (i = 1; i <= n; i++) {
        split(f[i], p, ":"); ini = p[1] + 0; qtd = (p[2] == "") ? 1 : p[2] + 0
        if (qtd == 0) { removida[ini < 1 ? 1 : ini] = 1; continue }
        for (l = ini; l < ini + qtd; l++) mudou[l] = 1
      }
    }
    { sub(/\r$/, "") }
    /^## / { sec = substr($0, 4) }
    (FNR in removida) || ((FNR in mudou) && $0 !~ /^[ \t]*$/) {
      s = (sec == "") ? "início" : sec
      if (!(s in visto)) { visto[s] = 1; ordem[++ns] = s }
      if ((FNR in mudou) && $0 ~ /^[ \t]*([-*]|[0-9]+\.)?[ \t]*\*\*[^*]+\*\*/) {
        t = $0; sub(/^[ \t]*([-*]|[0-9]+\.)?[ \t]*\*\*/, "", t); t = substr(t, 1, index(t, "**") - 1); sub(/:$/, "", t)
        if (!((s, t) in tem)) { tem[s, t] = 1; itens[s] = (itens[s] == "") ? t : itens[s] ", " t }
      }
    }
    END {
      for (i = 1; i <= ns; i++) {
        s = ordem[i]
        saida = saida (i > 1 ? "; " : "") "\"" s "\"" (itens[s] == "" ? "" : " (" itens[s] ")")
      }
      print saida
    }' "$ciclo"
}
if [ -n "$kit_commit" ]; then
  kit_sha=${kit_commit%% *}; kit_dia=${kit_commit#* }
  echo
  echo "### Kit"
  if ! git diff --quiet HEAD -- "$ciclo" 2>/dev/null; then
    s=$(secoes HEAD)
    echo "- $ciclo tem mudança ainda sem commit.${s:+ Releia antes de orquestrar: $s.}"
  elif git diff-tree --root --no-commit-id --name-status -r "$kit_sha" -- "$ciclo" 2>/dev/null | grep -q '^A'; then
    echo "- $ciclo instalado em $kit_dia ($kit_sha): leia-o inteiro antes de orquestrar."
  else
    s=$(secoes "$kit_sha^" "$kit_sha")
    echo "- $ciclo mudou em $kit_dia ($kit_sha).${s:+ Releia antes de orquestrar: $s.}"
    outros=$(git -c core.quotepath=off diff-tree --no-commit-id --name-only -r "$kit_sha" -- agentic/processo 2>/dev/null \
      | awk -v ciclo="$ciclo" '
          $0 == ciclo || /\.kit-manifesto$/ { next }
          { sub(/^agentic\/processo\//, ""); n++; if (n <= 8) lista = lista (n > 1 ? ", " : "") $0 }
          END { if (n) print lista (n > 8 ? " e mais " (n - 8) : "") }')
    [ -n "$outros" ] && echo "- No mesmo commit, em agentic/processo/: $outros"
  fi
fi

echo
echo "### Worktrees"
git worktree list 2>/dev/null

echo
echo "### Branch principal (remota conforme o último fetch)"
remota="origin/$BRANCH_PRINCIPAL"
tem_remota=""; git rev-parse --verify -q "$remota^{commit}" >/dev/null 2>&1 && tem_remota=1
if ! git rev-parse --verify -q "$BRANCH_PRINCIPAL^{commit}" >/dev/null 2>&1; then
  echo "- (branch principal '$BRANCH_PRINCIPAL' ainda não existe)"
elif [ -z "$tem_remota" ]; then
  echo "- $BRANCH_PRINCIPAL: sem $remota"
else
  atras=$(git rev-list --count "$BRANCH_PRINCIPAL..$remota" 2>/dev/null || echo "?")
  frente=$(git rev-list --count "$remota..$BRANCH_PRINCIPAL" 2>/dev/null || echo "?")
  if [ "$atras" = "0" ] && [ "$frente" = "0" ]; then
    echo "- $BRANCH_PRINCIPAL: em dia com $remota"
  else
    [ "$atras" = "0" ] || echo "- $BRANCH_PRINCIPAL: $atras commit(s) atrás de $remota — atualize: git merge --ff-only $remota"
    [ "$frente" = "0" ] || echo "- $BRANCH_PRINCIPAL: $frente commit(s) à frente de $remota"
  fi
fi

echo
echo "### Branches à frente de $BRANCH_PRINCIPAL"
if git rev-parse --verify -q "$BRANCH_PRINCIPAL^{commit}" >/dev/null 2>&1; then
  # Conta o que não está nem na principal local nem na remota: branch integrada no remoto com a principal local
  # atrasada não aparece à frente. Upstream [gone] = remota apagada (em geral depois do merge do PR).
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | while read -r b trilha; do
    [ "$b" = "$BRANCH_PRINCIPAL" ] && continue
    n=$(git rev-list --count "$b" --not "$BRANCH_PRINCIPAL" ${tem_remota:+"$remota"} 2>/dev/null || echo "?")
    if [ "$n" = "0" ]; then
      if [ -n "$tem_remota" ] && [ "$(git rev-list --count "$BRANCH_PRINCIPAL..$b" 2>/dev/null)" != "0" ]; then
        echo "- $b: integrada em $remota — atualize a principal e apague com git branch -d $b"
      fi
    elif [ "$trilha" = "[gone]" ]; then
      echo "- $b: $n commit(s) — remota apagada"
    else
      echo "- $b: $n commit(s)"
    fi
  done
else
  echo "- (branch principal '$BRANCH_PRINCIPAL' ainda não existe)"
fi

echo
echo "### Artefatos"
# Os campos de todos os artefatos saem de uma leitura só, e as tasks publicadas na principal, de um git grep por
# ref: um processo por arquivo custava dezenas de segundos em projeto com centenas de artefatos.
sep=$(printf '\034') # separador de campos que não é espaço: o read preserva campo vazio
nl='
'
# publicadas_em <ref>: os artefatos cuja primeira linha **Status:** naquela ref é "publicada", um por linha.
publicadas_em() {
  git -c core.quotepath=off grep -n -e '^\*\*Status:\*\*' "$1" -- agentic/projeto/intent agentic/projeto/specs 2>/dev/null \
    | awk -v ref="$1:" '
        index($0, ref) == 1 {
          resto = substr($0, length(ref) + 1)
          i = index(resto, ":"); arquivo = substr(resto, 1, i - 1); resto = substr(resto, i + 1)
          i = index(resto, ":"); linha = substr(resto, i + 1)
          if (arquivo in visto) next
          visto[arquivo] = 1
          if (index(linha, "**Status:** publicada") == 1) print arquivo
        }'
}
publicadas="$nl$(publicadas_em "$BRANCH_PRINCIPAL")$nl$(publicadas_em "origin/$BRANCH_PRINCIPAL")$nl"

find agentic/projeto/intent agentic/projeto/specs -name '*.md' ! -name '_*' -exec awk -v sep="$sep" '
  function campo(texto, nome) { sub("^\\*\\*" nome ":\\*\\*[ \t\r\f\v]*", "", texto); return texto }
  function limpo(texto, nome) { gsub(/[\r`]/, "", texto); texto = campo(texto, nome); sub(/[ \t\f\v]*$/, "", texto); return texto }
  function sai() { if (arquivo != "" && status != "") print arquivo sep status sep branch sep base }
  FNR == 1 { sai(); arquivo = FILENAME; status = branch = base = ""; ts = tb = tx = 0 }
  !ts && /^\*\*Status:\*\*/ { ts = 1; status = campo($0, "Status") }
  !tb && /^\*\*Branch:\*\*/ { tb = 1; branch = limpo($0, "Branch") }
  !tx && /^\*\*Base:\*\*/ { tx = 1; base = limpo($0, "Base") }
  END { sai() }' {} + 2>/dev/null | sort -t "$sep" -k1,1 | while IFS=$sep read -r f s br base; do
  # integrada não é um Status escrito (ciclo.md, "Status dos artefatos"): deriva do git. Task publicada cuja versão
  # na principal (local ou, desatualizada ou ausente, a remota) também está publicada foi integrada — o commit
  # docs(task): … publicada é feito na branch da task e só chega à principal pelo merge.
  case "$s" in
    publicada*)
      case "$publicadas" in *"$nl$f$nl"*) s="integrada (derivado do git) — $s" ;; esac
      ;;
    pendente*)
      # em-andamento não é escrito (ciclo.md, "Status dos artefatos"): pendente com branch própria à frente da
      # principal está em andamento. Sem branch, branch inexistente ou ainda sem commit à frente: continua pendente.
      # Só conta commit além do registro do Gate 1 (docs(…): … aprovada (Gate 1)). Task empilhada (**Base:** com
      # branch existente) conta a partir da branch-base, não da principal.
      if [ -n "$br" ] && git rev-parse --verify -q "$br^{commit}" >/dev/null 2>&1; then
        if [ -n "$base" ] && git rev-parse --verify -q "$base^{commit}" >/dev/null 2>&1; then
          cmp_com="$base"
        else
          cmp_com="$BRANCH_PRINCIPAL origin/$BRANCH_PRINCIPAL"
        fi
        for p in $cmp_com; do
          git rev-parse --verify -q "$p^{commit}" >/dev/null 2>&1 || continue
          n=$(git log --format=%s "$p..$br" 2>/dev/null | grep -vc 'aprovada (Gate 1')
          [ "${n:-0}" -gt 0 ] 2>/dev/null && s="em-andamento (derivado do git)"
          break
        done
      fi
      ;;
  esac
  [ -n "$s" ] && echo "- $f: $s"
done

echo
modo="desligado"
grep -q '^enabled:[[:space:]]*true' agentic/auto-mode 2>/dev/null && modo="ligado"
echo "Modo automático: $modo"
gate1=$(sed -n 's/^gate1:[[:space:]]*//p' agentic/auto-mode 2>/dev/null | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*$//')
if [ "$modo" = "ligado" ] && [ -n "$gate1" ]; then
  echo "Gate 1: delegado ao orquestrador ($gate1)"
else
  echo "Gate 1: humano"
fi
exit 0
