# lib-agentic.sh — configuração e funções comuns aos hooks e scripts do framework.
# Carregar com ". lib-agentic.sh". Lê <raiz>/agentic/config sobre os padrões abaixo.
agentic_raiz=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "agentic: BLOQUEADO — fora de um repositório git" >&2
  exit 1
}

BRANCH_PRINCIPAL="main"
BRANCHES_PROTEGIDAS="main master"
DIRS_TESTE="tests/ test/"
MARCADOR_DESABILITADO=""
MARCADOR_ASSERCAO="assert|expect"
RELATORIO_TESTES=""
CMD_PREPARAR_TESTE=""
CMD_TESTE=""
CMD_TESTE_ARQUIVO=""
CMD_VERIFY_STACK=""
CMD_VERIFY_RAPIDO=""
CMD_VALIDA_CONTRATO=""
CAMINHOS_N3=""
GITLEAKS_BIN="gitleaks"
# Executores TESTE_<n>_* só valem do agentic/config (superfície protegida): os herdados do ambiente são apagados.
for agentic_v in $(set | sed -nE 's/^(TESTE_[0-9]+_(PADROES|PREPARO|COMANDO|RC_RED))=.*/\1/p'); do
  unset "$agentic_v"
done

if [ -f "$agentic_raiz/agentic/config" ]; then
  . "$agentic_raiz/agentic/config"
fi

# agentic_branch_protegida <branch>: retorna 0 se a branch está em BRANCHES_PROTEGIDAS.
agentic_branch_protegida() {
  for agentic_b in $BRANCHES_PROTEGIDAS; do
    [ "$1" = "$agentic_b" ] && return 0
  done
  return 1
}

# agentic_falha <mensagem>: bloqueia com mensagem padronizada.
agentic_falha() {
  printf 'agentic: BLOQUEADO — %s\n' "$*" >&2
  exit 1
}

# agentic_base_task: imprime a ref da **Base:** da task da branch atual (branch empilhada) enquanto ela
# não estiver integrada na principal; senão, nada (quem chama cai para a principal). Nunca falha.
# Com $1 (caminho de uma task), usa essa task em vez de procurar pela branch.
agentic_base_task() {
  agentic_t=${1:-}
  if [ -z "$agentic_t" ]; then
    agentic_br=$(git symbolic-ref --short -q HEAD)
    [ -n "$agentic_br" ] || return 0
    agentic_t=$(grep -l "^\*\*Branch:\*\*[[:space:]]*$agentic_br[[:space:]]*$" agentic/projeto/specs/*/tasks/*.md 2>/dev/null | head -n 1)
  fi
  [ -n "$agentic_t" ] || return 0
  agentic_bt=$(sed -n 's/^\*\*Base:\*\*[[:space:]]*//p' "$agentic_t" | head -n 1 | tr -d '\r`' | sed 's/[[:space:]]*$//')
  [ -n "$agentic_bt" ] || return 0
  for agentic_c in "$agentic_bt" "origin/$agentic_bt"; do
    if git rev-parse --verify -q "$agentic_c^{commit}" >/dev/null; then
      agentic_pr=$(agentic_principal_ref)
      if [ -n "$agentic_pr" ] && git merge-base --is-ancestor "$agentic_c" "$agentic_pr"; then
        return 0
      fi
      printf '%s\n' "$agentic_c"
      return 0
    fi
  done
  return 0
}

# agentic_base: ponto de divergência entre HEAD e a base de comparação. Ordem: AGENTIC_BASE, a **Base:**
# da task (branch empilhada ainda não integrada) e a principal (local ou, em clone de CI, origin/).
agentic_base() {
  agentic_ref=${AGENTIC_BASE:-}
  [ -n "$agentic_ref" ] || agentic_ref=$(agentic_base_task)
  if [ -n "$agentic_ref" ]; then
    git merge-base HEAD "$agentic_ref" 2>/dev/null
    return
  fi
  git merge-base HEAD "$BRANCH_PRINCIPAL" 2>/dev/null || git merge-base HEAD "origin/$BRANCH_PRINCIPAL" 2>/dev/null
}

# --- Executores por caminho: blocos TESTE_<n>_* do agentic/config (n = 1, 2, …), com os campos
# PADROES PREPARO COMANDO RC_RED. PADROES são padrões do case do sh separados por espaço (o * cruza /); o bloco
# só existe com PADROES. A leitura para no primeiro n sem PADROES.

# agentic_executores: imprime os n válidos, um por linha; um TESTE_<m>_PADROES além do buraco vira aviso em stderr.
agentic_executores() {
  agentic_n=1
  while eval "[ -n \"\${TESTE_${agentic_n}_PADROES:-}\" ]"; do
    printf '%s\n' "$agentic_n"
    agentic_n=$((agentic_n + 1))
  done
  for agentic_m in $(set | sed -n 's/^TESTE_\([1-9][0-9]*\)_PADROES=.*/\1/p'); do
    [ "$agentic_m" -gt "$agentic_n" ] || continue
    eval "[ -n \"\${TESTE_${agentic_m}_PADROES:-}\" ]" || continue
    echo "aviso: TESTE_${agentic_m}_PADROES ignorado — falta TESTE_${agentic_n}_PADROES" >&2
  done
  return 0
}

# agentic_executor_campo <n> <CAMPO>: imprime TESTE_<n>_<CAMPO> (vazio se não definido); n ou CAMPO inválido → 1.
agentic_executor_campo() {
  case $1 in ''|*[!0-9]*) return 1 ;; esac
  case " PADROES PREPARO COMANDO RC_RED " in *" $2 "*) ;; *) return 1 ;; esac
  eval "agentic_v=\${TESTE_${1}_${2}:-}"
  printf '%s\n' "$agentic_v"
}

# agentic_executor <arquivo>: imprime o primeiro n cujo padrão casa o arquivo; 1 se nenhum.
agentic_executor() {
  case $- in *f*) agentic_sf=1 ;; *) agentic_sf= ;; esac
  for agentic_n in $(agentic_executores 2>/dev/null); do
    agentic_ps=$(agentic_executor_campo "$agentic_n" PADROES)
    set -f
    for agentic_p in $agentic_ps; do
      # shellcheck disable=SC2254
      case "$1" in $agentic_p) [ -n "$agentic_sf" ] || set +f; printf '%s\n' "$agentic_n"; return 0 ;; esac
    done
    [ -n "$agentic_sf" ] || set +f
  done
  return 1
}

# agentic_e_teste <arquivo>: a única regra de "arquivo de teste": prefixo de DIRS_TESTE ou padrão de algum
# executor. Não trata docs/ nem agentic/projeto/ (quem chama mantém a isenção).
agentic_e_teste() {
  case $- in *f*) agentic_sf=1 ;; *) agentic_sf= ;; esac
  set -f
  for agentic_d in $DIRS_TESTE; do
    case "$1" in "$agentic_d"*) [ -n "$agentic_sf" ] || set +f; return 0 ;; esac
  done
  [ -n "$agentic_sf" ] || set +f
  agentic_executor "$1" >/dev/null
}

# agentic_principal_ref: a branch principal local ou, sem ela, a remota. Vazio se nenhuma existir.
agentic_principal_ref() {
  for agentic_p in "$BRANCH_PRINCIPAL" "origin/$BRANCH_PRINCIPAL"; do
    git rev-parse --verify -q "$agentic_p^{commit}" >/dev/null && { printf '%s\n' "$agentic_p"; return 0; }
  done
  return 1
}

# agentic_fora_do_git: lista, uma por linha ("- ..."), a configuração fora do git que muda o processo do kit, lida da
# árvore principal (os arquivos não versionados não vão para os worktrees, e a sessão da ferramenta roda na principal).
# Vazio se não houver nada. Do .claude/settings.local.json, só as chaves de topo (o awk acompanha a profundidade fora
# de strings): o local tem precedência sobre o .claude/settings.json versionado, ou soma a ele (hooks, permissions).
# Limite: skills globais (~/.claude/skills), plugins do escopo do usuário e a memória da ferramenta não são lidos.
agentic_fora_do_git() {
  agentic_fg_raiz=$(git worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
  [ -n "$agentic_fg_raiz" ] && [ -d "$agentic_fg_raiz" ] || agentic_fg_raiz=$agentic_raiz
  agentic_fg_local="$agentic_fg_raiz/.claude/settings.local.json"
  if [ -f "$agentic_fg_local" ]; then
    agentic_fg_chaves=$(tr -d '\r' < "$agentic_fg_local" | awk '
      BEGIN { RS = "\001" }
      {
        n = length($0); prof = 0; str = 0; tok = ""; ultimo = ""
        for (i = 1; i <= n; i++) {
          c = substr($0, i, 1)
          if (str) {
            if (c == "\\") { tok = tok c substr($0, i + 1, 1); i++; continue }
            if (c == "\"") { str = 0; ultimo = tok; continue }
            tok = tok c; continue
          }
          if (c == "\"") { str = 1; tok = ""; continue }
          if (c == "{" || c == "[") { prof++; ultimo = ""; continue }
          if (c == "}" || c == "]") { prof--; ultimo = ""; continue }
          if (c == ":") { if (prof == 1 && ultimo != "") chave[ultimo] = 1; ultimo = ""; continue }
          if (c !~ /[ \t\n]/) ultimo = ""
        }
        k = split("autoCompactWindow permissions enabledPlugins hooks disableAllHooks model", ordem, " ")
        for (j = 1; j <= k; j++) if (ordem[j] in chave) saida = saida (saida == "" ? "" : ", ") ordem[j]
        print saida
      }')
    [ -n "$agentic_fg_chaves" ] && \
      printf '%s\n' "- .claude/settings.local.json: $agentic_fg_chaves (precedência sobre o .claude/settings.json do kit, ou soma a ele)"
  fi
  for agentic_fg_f in CLAUDE.local.md .claude/CLAUDE.md; do
    [ -f "$agentic_fg_raiz/$agentic_fg_f" ] || continue
    git -C "$agentic_fg_raiz" ls-files --error-unmatch -- "$agentic_fg_f" >/dev/null 2>&1 && continue
    printf '%s\n' "- $agentic_fg_f: não versionado, lido pela ferramenta em toda sessão"
  done
  agentic_fg_l=$(git -C "$agentic_fg_raiz" -c core.quotepath=off ls-files --others --directory \
      -- .claude/skills .claude/agents .claude/commands .claude/hooks 2>/dev/null \
    | awk '{ n++; if (n <= 8) l = l (n > 1 ? ", " : "") $0 } END { if (n) print l (n > 8 ? " e mais " (n - 8) : "") }')
  [ -n "$agentic_fg_l" ] && printf '%s\n' "- não versionados em .claude/: $agentic_fg_l"
  return 0
}
