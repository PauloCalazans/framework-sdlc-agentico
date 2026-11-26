#!/bin/sh
# verifica-decisoes.sh [base] — integridade das decisões: um arquivo por decisão em
# agentic/projeto/decisoes/<slug>.md (citada como D:<slug>) e o registro antigo agentic/projeto/decisoes.md
# (congelado: as "### D<n>" continuam resolvendo, e nenhuma nova entra ali):
#   (1) toda referência resolve: "D<n>" num "### D<n>" do decisoes.md; "D:<slug>" num arquivo decisoes/<slug>.md.
#       Varre agentic/projeto/**/*.md, inclusive os arquivos de decisoes/, exceto o decisoes.md;
#   (2) nada da base (merge-base com a principal) some: nenhuma "D<n>" do registro, nenhum arquivo de decisoes/ —
#       decisão nunca é apagada nem renomeada, só revogada (cobre a perda silenciosa por conflito de merge,
#       que os testes da stack não enxergam);
#   (3) "### D<n>" presente em HEAD e ausente na base bloqueia: o registro está congelado;
#   (4) todo .md do primeiro nível de decisoes/ tem slug válido, título "# " e "**Status:**" vigente ou
#       "revogada em <AAAA-MM-DD>: <motivo>" (.gitkeep e subpastas são ignorados);
#   (5) delegação do Gate 1 pelo agentic/auto-mode local (enabled, gate1, plano), lido da árvore principal do
#       repositório também quando o script roda num worktree (o do worktree é ignorado): gate1 vazio, "todas"
#       ou "<nome>, <nome>"; preenchido exige plano: com arquivo existente em HEAD. Todo commit da branch
#       "<tipo>: <nome> aprovada (Gate 1 delegado)" exige no corpo gate1: cobrindo o nome e plano: existente
#       em HEAD (em todo clone); com o auto-mode presente, exige também enabled: true e gate1 cobrindo o nome.
#       Formato antigo "(Gate 1 delegado, D<n>)": só a regra do auto-mode, sem corpo. Um Gate 1 humano do
#       mesmo artefato na branch libera o delegado. Sem auto-mode (outro clone, CI): o que depende dele é
#       declarado "não verificável". Roda mesmo sem registro; sem base, declara a checagem degradada.
# Tudo em lote: uma varredura, um git ls-tree, um awk por conjunto; nenhum processo por decisão ou referência
# (os commits de Gate 1 delegado são conferidos um a um).
# Sem registro e sem pasta de decisões, em HEAD e na base: (1) a (4) são puladas; (5) roda sempre.
. "$(dirname "$0")/lib-agentic.sh"
cd "$agentic_raiz" || exit 1
reg=agentic/projeto/decisoes.md
dir=agentic/projeto/decisoes

# ids <arquivo>: números das decisões definidas ("### D<n>"), um por linha, sem repetição.
ids() { sed -n 's/^### D\([0-9][0-9]*\)\([^0-9].*\)\{0,1\}$/\1/p' | sort -u; }

definidas=""
[ -f "$reg" ] && definidas=$(ids < "$reg")
# slugs da pasta: nome dos .md do primeiro nível, sem a extensão
lista_slugs() { find "$dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sed 's|.*/||; s|\.md$||' | sort -u; }
slugs=$(lista_slugs)
status=0

# ausentes <formato> <conjunto>: lê itens (ou "<item>\t<arquivo>") e imprime os que não estão no conjunto
# (lista separada por quebra de linha). Um awk para a lista toda: um processo por item custava dezenas de
# segundos em projeto com centenas de artefatos.
ausentes() {
  CONJUNTO=$2 awk -F'\t' -v formato="$1" '
    BEGIN { n = split(ENVIRON["CONJUNTO"], d, "\n"); for (i = 1; i <= n; i++) def[d[i] ""] = 1 }
    $1 != "" && !(($1 "") in def) { printf formato "\n", $1, $2 }'
}

# base de comparação: usada por (2), (3) e pelos commits de (5)
if [ -n "${1:-}" ]; then
  base=$(git merge-base HEAD "$1") || agentic_falha "base inválida: $1"
else
  base=$(agentic_base)
fi
if [ -n "$base" ] && ! git rev-parse --verify -q "$base^{commit}" >/dev/null; then
  agentic_falha "base inválida: $base"
fi

# pula (1) a (4) só quando nem HEAD nem a base têm o registro ou a pasta: apagá-los inteiros não pula nada
sem_reg=""
if [ ! -f "$reg" ] && [ ! -d "$dir" ]; then
  sem_reg=1
  if [ -n "$base" ] && { git cat-file -e "$base:$reg" 2>/dev/null || [ -n "$(git ls-tree --name-only "$base" -- "$dir/")" ]; }; then
    sem_reg=""
  fi
fi

if [ -z "$sem_reg" ]; then


# (1) referências órfãs — uma varredura para todos os arquivos; o /dev/null faz o grep imprimir o nome do arquivo.
padrao='(^|[^A-Za-z0-9_])(D[0-9]+([^A-Za-z0-9_]|$)|D:[a-z0-9]+(-[a-z0-9]+)*([^A-Za-z0-9_-]|$))'
refs=$(
  find agentic/projeto -type f -name '*.md' ! -path "$reg" -exec grep -o -E "$padrao" /dev/null {} + 2>/dev/null | awk '
    { sub(/\r$/, "") }
    match($0, /:[^A-Za-z0-9_]?(D[0-9]+[^A-Za-z0-9_]?|D:[a-z0-9]+(-[a-z0-9]+)*[^A-Za-z0-9_-]?)$/) {
      arquivo = substr($0, 1, RSTART - 1); r = substr($0, RSTART + 1)
      sub(/^[^D]*/, "", r)
      if (substr(r, 2, 1) == ":") { r = substr(r, 3); sub(/[^a-z0-9-].*$/, "", r); r = "D:" r }
      else { r = substr(r, 2); sub(/[^0-9].*$/, "", r); r = "D" r }
      print r "\t" arquivo
    }' | sort -u
)
# D<n> resolve em $definidas, D:<slug> em $slugs: o prefixo "D"/"D:" é tirado e o conjunto escolhido por tipo.
orfas=$(printf '%s\n' "$refs" | CONJ_N=$definidas CONJ_S=$slugs awk -F'\t' '
  BEGIN { n = split(ENVIRON["CONJ_N"], a, "\n"); for (i = 1; i <= n; i++) num[a[i] ""] = 1
          n = split(ENVIRON["CONJ_S"], a, "\n"); for (i = 1; i <= n; i++) slug[a[i] ""] = 1 }
  $1 == "" { next }
  substr($1, 1, 2) == "D:" { if (!((substr($1, 3) "") in slug)) print $1 " (em " $2 ")"; next }
  { if (!((substr($1, 2) "") in num)) print $1 " (em " $2 ")" }')
if [ -n "$orfas" ]; then
  echo "agentic: BLOQUEADO — referência a decisão inexistente (D<n> em $reg, D:<slug> em $dir/):"
  printf '%s\n' "$orfas" | sed 's/^/  /'
  status=1
fi

# (2) e (3): comparação com a base
if [ -z "$base" ]; then
  echo "degradado: sem base de comparação — perda de decisões não verificada"
else
  if git cat-file -e "$base:$reg" 2>/dev/null; then
    perdidas=$(git show "$base:$reg" | ids | ausentes 'D%s' "$definidas")
    if [ -n "$perdidas" ]; then
      echo "agentic: BLOQUEADO — decisão(ões) da base ausente(s) em $reg (decisão não se apaga; revogue-a): $(printf '%s' "$perdidas" | tr '\n' ' ')"
      status=1
    fi
    # (3) o registro está congelado: nenhuma "### D<n>" nova
    antigas=$(git show "$base:$reg" | ids)
  else
    antigas=""
  fi
  novas=$([ -f "$reg" ] && ids < "$reg" | ausentes 'D%s' "$antigas")
  if [ -n "$novas" ]; then
    echo "agentic: BLOQUEADO — decisão nova no registro congelado $reg: $(printf '%s' "$novas" | tr '\n' ' ') (decisão nova vai em $dir/<slug>.md)"
    status=1
  fi
  # (2) arquivos de decisão da base
  da_base=$(git ls-tree --name-only "$base" -- "$dir/" | sed -n 's|^.*/\([^/]*\)\.md$|\1|p' | sort -u)
  perdidos=$(printf '%s\n' "$da_base" | ausentes '%s' "$slugs")
  if [ -n "$perdidos" ]; then
    echo "agentic: BLOQUEADO — decisão(ões) da base ausente(s) em $dir/ (decisão não se apaga nem se renomeia; revogue-a): $(printf '%s' "$perdidos" | tr '\n' ' ')"
    status=1
  fi
fi

# (4) formato dos arquivos de decisão — um awk para todos
formato=$(find "$dir" -maxdepth 1 -type f -name '*.md' -exec awk '
  function fecha() {
    if (arq == "") return
    if (!titulo) print "  " arq ": sem título \"# \""
    if (!st) print "  " arq ": sem **Status:** vigente | revogada em <AAAA-MM-DD>: <motivo>"
  }
  FNR == 1 { fecha(); arq = FILENAME; titulo = 0; st = 0; visto = 0
    nome = FILENAME; sub(/^.*\//, "", nome); sub(/\.md$/, "", nome)
    if (nome !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) print "  " arq ": nome não é slug" }
  { sub(/\r$/, "") }
  !visto && $0 != "" { visto = 1; if ($0 ~ /^# /) titulo = 1 }
  $0 ~ /^\*\*Status:\*\* (vigente|revogada em [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]: .+)$/ { st = 1 }
  END { fecha() }' {} + 2>/dev/null | sort)
# arquivo vazio não tem registro para o awk acima: uma segunda busca em lote cobre os de 0 byte
vazios=$(find "$dir" -maxdepth 1 -type f -name '*.md' -size 0 2>/dev/null | awk '
  { arq = $0; nome = arq; sub(/^.*\//, "", nome); sub(/\.md$/, "", nome)
    if (nome !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) print "  " arq ": nome não é slug"
    print "  " arq ": sem título \"# \""
    print "  " arq ": sem **Status:** vigente | revogada em <AAAA-MM-DD>: <motivo>" }')
[ -n "$vazios" ] && formato=$(printf '%s\n%s\n' "$formato" "$vazios" | sed '/^$/d' | sort)
if [ -n "$formato" ]; then
  echo "agentic: BLOQUEADO — decisão fora do formato em $dir/:"
  printf '%s\n' "$formato"
  status=1
fi

fi

# (5) delegação do Gate 1 — agentic/auto-mode local: enabled, gate1 (vazio | todas | <nome>, <nome>) e plano.
# Roda também sem registro de decisões. O arquivo é local e fora do git: é lido da árvore principal do
# repositório (pai do diretório git comum), também quando o verify roda num worktree, onde ele não existe;
# um agentic/auto-mode criado dentro de um worktree é ignorado.
principal=$(cd "$(git rev-parse --git-common-dir)/.." 2>/dev/null && pwd) || principal=$agentic_raiz
auto=$principal/agentic/auto-mode
chave() { sed -n "s/^$1:[[:space:]]*//p" "$auto" | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*$//'; }
# itens <gate1>: a lista normalizada, um nome por linha
itens() { printf '%s\n' "$1" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }
# cobre <gate1> <nome>: o gate1 ("todas" ou a lista) cobre o nome
cobre() { [ -n "$2" ] && { [ "$1" = todas ] || itens "$1" | grep -qxF -- "$2"; }; }
gate1=""; ligado=""; plano=""; formato_ok=1
if [ -f "$auto" ]; then
  gate1=$(chave gate1)
  plano=$(chave plano)
  [ "$(chave enabled)" = true ] && ligado=1
  if printf '%s\n' "$gate1" | grep -q '^D[0-9][0-9]*$'; then
    echo "agentic: BLOQUEADO — gate1: $gate1 em agentic/auto-mode é do formato antigo (a delegação não é mais uma decisão): use todas ou a lista de specs e mudanças"
    status=1; formato_ok=""
  elif [ -n "$gate1" ] && [ "$gate1" != todas ]; then
    # lista: itens separados por vírgula, espaço aparado; item com espaço interno ou vazio é formato inválido
    if itens "$gate1" | grep -q -e '^$' -e '[[:space:]]'; then
      echo "agentic: BLOQUEADO — gate1: em agentic/auto-mode precisa ser vazio, todas ou <nome>, <nome> (encontrado: $gate1)"
      status=1; formato_ok=""
    fi
  fi
  # o plano é versionado: conferido em HEAD, não na árvore de trabalho
  if [ -n "$gate1" ] && [ -n "$formato_ok" ] && { [ -z "$plano" ] || ! git cat-file -e "HEAD:$plano" 2>/dev/null; }; then
    echo "agentic: BLOQUEADO — gate1: preenchido em agentic/auto-mode exige plano: com um arquivo existente em HEAD (encontrado: ${plano:-vazio})"
    status=1
  fi
fi

# commits de registro do Gate 1 delegado
if [ -z "$base" ]; then
  echo "degradado: sem base de comparação — commits de Gate 1 delegado não verificados"
else
  assuntos=$(git log --format='%s' "$base..HEAD")
  # um registro por commit com "Gate 1 delegado" no assunto: gate1:<US>plano:<US><hash> <assunto>, com o
  # gate1: e o plano: da primeira linha de cada um no corpo (US, não espaço, separa: campo vazio fica vazio)
  us=$(printf '\037')
  delegados=$(git log --format='%x1e%h %s%n%b' "$base..HEAD" | tr -d '\r' | awk -v us="$us" '
    BEGIN { RS = "\036" }
    {
      n = split($0, l, "\n"); c = l[1]; g = ""; p = ""; tg = 0; tp = 0
      if (index(c, "Gate 1 delegado") == 0) next
      for (i = 2; i <= n; i++) {
        if (!tg && l[i] ~ /^gate1:/) { tg = 1; g = l[i]; sub(/^gate1:[ \t]*/, "", g); sub(/[ \t]*$/, "", g) }
        if (!tp && l[i] ~ /^plano:/) { tp = 1; p = l[i]; sub(/^plano:[ \t]*/, "", p); sub(/[ \t]*$/, "", p) }
      }
      print g us p us c
    }')
  if [ -n "$delegados" ]; then
    # cada linha sai com a categoria: S (corpo sem gate1:/plano:), C (corpo que não cobre), N (não verificável
    # sem o auto-mode), F (o auto-mode não cobre)
    achados=$(printf '%s\n' "$delegados" | while IFS=$us read -r g1 pl c; do
      assunto=${c#* }
      # Gate 1 humano do mesmo artefato registrado na mesma branch, em qualquer posição ("<tipo>: <nome> aprovada (Gate 1)") substitui o delegado.
      humano="${assunto%% (Gate 1 delegado*} (Gate 1)"
      printf '%s\n' "$assuntos" | grep -qxF -- "$humano" && continue
      # nome do artefato: "docs(spec|mudanca): <nome> aprovada (Gate 1 delegado)"; o formato antigo traz ", D<n>"
      nome=$(printf '%s\n' "$assunto" | sed -n -e 's/^docs(spec): \(.*\) aprovada (Gate 1 delegado)$/\1/p' -e 's/^docs(mudanca): \(.*\) aprovada (Gate 1 delegado)$/\1/p')
      if [ -n "$nome" ]; then
        if [ -z "$g1" ] || [ -z "$pl" ]; then echo "S $c"; continue; fi
        if ! cobre "$g1" "$nome" || ! git cat-file -e "HEAD:$pl" 2>/dev/null; then echo "C $c"; continue; fi
      else
        nome=$(printf '%s\n' "$assunto" | sed -n -e 's/^docs(spec): \(.*\) aprovada (Gate 1 delegado, D[0-9][0-9]*)$/\1/p' -e 's/^docs(mudanca): \(.*\) aprovada (Gate 1 delegado, D[0-9][0-9]*)$/\1/p')
      fi
      if [ ! -f "$auto" ]; then echo "N $c"; continue; fi
      if [ -n "$ligado" ] && [ -n "$formato_ok" ] && cobre "$gate1" "$nome"; then continue; fi
      echo "F $c"
    done)
    # grupo <categoria> <mensagem>: imprime a mensagem e os commits da categoria; devolve 0 se havia algum
    grupo() {
      linhas=$(printf '%s\n' "$achados" | sed -n "s/^$1 /  /p")
      [ -n "$linhas" ] || return 1
      echo "$2"; printf '%s\n' "$linhas"
    }
    grupo S "agentic: BLOQUEADO — commit registra Gate 1 delegado sem gate1:/plano: no corpo (copie-os do agentic/auto-mode):" && status=1
    grupo C "agentic: BLOQUEADO — commit registra Gate 1 delegado com gate1:/plano: do corpo que não cobrem o artefato ou plano sem arquivo em HEAD:" && status=1
    grupo F "agentic: BLOQUEADO — commit registra Gate 1 delegado sem delegação vigente (agentic/auto-mode com enabled: true e gate1: cobrindo o artefato):" && status=1
    grupo N "verifica-decisoes: delegação não verificável neste clone (sem agentic/auto-mode na árvore principal):"
  fi
fi

if [ "$status" -eq 0 ]; then
  if [ -n "$sem_reg" ]; then echo "verifica-decisoes: sem registro de decisões — pulado"; else echo "verifica-decisoes: OK"; fi
fi
exit $status
