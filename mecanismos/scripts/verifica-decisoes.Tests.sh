#!/bin/sh
# Testes do verifica-decisoes.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

reg() { # reg <repo> <ids...>: escreve o registro com uma decisão "### D<n>" por id
  r=$1; shift
  mkdir -p "$r/agentic/projeto"
  { printf '# Registro de decisões\n\n## Vigentes\n\n'; for n in "$@"; do printf '### D%s — t\n- **Decisão:** x\n\n' "$n"; done; printf '## Decisões revogadas\n\n<nenhuma>\n'; } > "$r/agentic/projeto/decisoes.md"
}
dec() { # dec <repo> <slug> [status]: escreve agentic/projeto/decisoes/<slug>.md válido
  mkdir -p "$1/agentic/projeto/decisoes"
  printf '# %s\n\n**Status:** %s\n' "$2" "${3:-vigente}" > "$1/agentic/projeto/decisoes/$2.md"
}
confirma() { git -C "$1" add -A; git -C "$1" commit -q -m "$2"; }
roda() { sh -c "cd '$1' && sh '$dir/verifica-decisoes.sh' $2"; }

r=$(tl_repo)
tl_espera 0 "sem registro de decisões: pulado" roda "$r"
tl_contem "pulado" "declara que pulou"

r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
mkdir -p "$r/agentic/projeto/specs/x"; printf 'Conforme D1 e (D2); veja D1.\n' > "$r/agentic/projeto/specs/x/design.md"
tl_espera 0 "referências a decisões existentes passam" roda "$r"

printf 'Decisão D7 pendente.\n' >> "$r/agentic/projeto/specs/x/design.md"
tl_espera 1 "referência a decisão inexistente bloqueia" roda "$r"
tl_contem "D7 (em agentic/projeto/specs/x/design.md)" "aponta a decisão e o arquivo"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf 'ID1, AD7, D, D1a, XD9, D_8 e d5 não são referências.\n' > "$r/agentic/projeto/nota.md"
tl_espera 0 "tokens parecidos com D<n> não são referências" roda "$r"

r=$(tl_repo); reg "$r" 1; printf '\n### D9 — extensão\n' >> "$r/agentic/projeto/decisoes.md"; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf 'Tratado em D1\n' > "$r/agentic/projeto/nota.md"
sed -i.bak 's/D1$/D1, D9/' "$r/agentic/projeto/nota.md"; rm -f "$r/agentic/projeto/nota.md.bak"
tl_espera 0 "título de decisão com sufixo (D9 — extensão) conta como definida" roda "$r"

# Varredura em lote: vários arquivos, subpastas, nome com espaço; o registro e o que não é .md ficam de fora.
r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
mkdir -p "$r/agentic/projeto/specs/a/tasks" "$r/agentic/projeto/planos/com espaco"
printf 'Usa D1.\nLinha com D8 e D9; de novo D8.\n' > "$r/agentic/projeto/specs/a/tasks/001-t.md"
printf '(D2) e :D7.\r\n' > "$r/agentic/projeto/planos/com espaco/plano um.md"
printf 'D5\n' > "$r/agentic/projeto/nota.txt"
printf '\nSubstitui a D6 antiga.\n' >> "$r/agentic/projeto/decisoes.md"
tl_espera 1 "referências órfãs em vários arquivos bloqueiam" roda "$r"
tl_contem "  D7 (em agentic/projeto/planos/com espaco/plano um.md)" "órfã em arquivo com espaço no nome"
tl_contem "  D8 (em agentic/projeto/specs/a/tasks/001-t.md)" "órfã em subpasta"
tl_contem "  D9 (em agentic/projeto/specs/a/tasks/001-t.md)" "segunda órfã da mesma linha"
copia=$(mktemp); cp "$TL_SAIDA" "$copia"
tl_espera 0 "cada órfã aparece uma vez por arquivo, em ordem" sh -c "[ \"\$(grep -c ' (em ' '$copia')\" = 3 ] && [ \"\$(grep ' (em ' '$copia' | cut -c3-4 | tr -d '\n')\" = D7D8D9 ]"
tl_espera 1 "arquivo que não é .md não é varrido" grep -q "D5" "$copia"
tl_espera 1 "o próprio registro não é varrido" grep -q "D6" "$copia"
rm -f "$copia"

# (2) decisão da base que sumiu
r=$(tl_repo); reg "$r" 1 2 3 4; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
reg "$r" 1 3; confirma "$r" "perde a D2 e a D4"
tl_espera 1 "várias decisões da base ausentes em HEAD bloqueiam" roda "$r"
tl_contem "revogue-a): D2 D4" "nomeia todas as decisões perdidas, em ordem"

r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
reg "$r" 1; confirma "$r" "perde a D2"
tl_espera 1 "decisão da base ausente em HEAD bloqueia" roda "$r"
tl_contem "D2" "nomeia a decisão perdida"

# perda por merge: a principal ganha a D3 depois do fork; a branch faz merge e resolve descartando-a
r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
git -C "$r" checkout -q main; reg "$r" 1 2 3; confirma "$r" "main ganha D3"
git -C "$r" checkout -q feat/k; reg "$r" 1 2; printf 'x\n' > "$r/a.txt"; confirma "$r" "trabalho na branch"
tl_espera 0 "branch atrás da principal (sem a D3 nova) não é perda" roda "$r"
git -C "$r" merge -q -s ours main -m "merge descartando a D3" >/dev/null 2>&1
tl_espera 1 "merge que descarta decisão da principal bloqueia" roda "$r"
tl_contem "D3" "nomeia a decisão descartada no merge"

# revogada continua definida
r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
printf '# Registro\n\n## Vigentes\n\n### D1 — t\n\n## Decisões revogadas\n\n### D2 — t (revogada em 2026-10-10: motivo)\n' > "$r/agentic/projeto/decisoes.md"
printf 'D2\n' > "$r/agentic/projeto/nota.md"; confirma "$r" "revoga a D2"
tl_espera 0 "decisão movida para revogadas continua definida" roda "$r"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
tl_espera 1 "base explícita inválida bloqueia" roda "$r" nao-existe-xyz
tl_contem "base inválida" "explica base inválida"

r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" branch -m main trunk
tl_espera 0 "sem principal: degradado, não falha" roda "$r"
tl_contem "degradado" "declara a verificação degradada"

# Gate 1 delegado: agentic/auto-mode local (enabled, gate1, plano); sem D<n>
modo() { mkdir -p "$1/agentic"; printf '%s\n' "$2" > "$1/agentic/auto-mode"; }
plano() { mkdir -p "$1/agentic/projeto/planos"; printf '# plano\n' > "$1/agentic/projeto/planos/p.md"; }
gate() { mkdir -p "$1/agentic/projeto/specs/x"; printf '%s\n' "$2" >> "$1/agentic/projeto/specs/x/spec.md"; confirma "$1" "$2"; }
P='plano: agentic/projeto/planos/p.md'
# deleg <gate1> <enabled> <assunto...>: repo com plano, auto-mode e os commits dados na branch
deleg() { # deleg <enabled> <gate1-literal> [assunto...]
  r=$(tl_repo); plano "$r"; confirma "$r" "plano"; git -C "$r" checkout -q -b feat/k
  modo "$r" "enabled: $1
gate1: $2
$P"
  shift 2; for a in "$@"; do gate "$r" "$a"; done
}
D='docs(spec): x aprovada (Gate 1 delegado)'

deleg true x "$D"
tl_espera 0 "delegação por nome passa" roda "$r"
deleg true todas "$D"
tl_espera 0 "gate1: todas passa" roda "$r"
deleg true "y, z" "$D"
tl_espera 1 "nome fora da lista bloqueia" roda "$r"
tl_contem "registra Gate 1 delegado sem delegação vigente" "explica o bloqueio do commit"
tl_contem "$D" "lista o commit"
deleg true "$(printf ' x , y\r')" "$D"
tl_espera 0 "lista com espaço extra e CRLF é lida por nome" roda "$r"
deleg false x "$D"
tl_espera 1 "modo desligado bloqueia" roda "$r"
tl_contem "sem delegação vigente" "explica o modo desligado"

r=$(tl_repo); confirma "$r" "base"; git -C "$r" checkout -q -b feat/k; modo "$r" 'enabled: true
gate1:'
gate "$r" "docs(mudanca): x aprovada (Gate 1 delegado)"
tl_espera 1 "gate1 vazio bloqueia o commit delegado" roda "$r"

deleg true x 'docs(spec): x aprovada (Gate 1 delegado, D2)'
tl_espera 0 "formato antigo é aceito pelo nome" roda "$r"
deleg true y 'docs(spec): x aprovada (Gate 1 delegado, D2)'
tl_espera 1 "formato antigo com nome fora da lista bloqueia" roda "$r"

r=$(tl_repo); confirma "$r" "base"; git -C "$r" checkout -q -b feat/k; modo "$r" "enabled: true
gate1: D2
$P"; plano "$r"
tl_espera 1 "gate1: D<n> bloqueia como formato antigo" roda "$r"
tl_contem "formato antigo" "aponta o formato antigo"

r=$(tl_repo); confirma "$r" "base"; git -C "$r" checkout -q -b feat/k; modo "$r" 'enabled: true
gate1: x'
tl_espera 1 "plano: ausente bloqueia" roda "$r"
tl_contem "plano:" "cita plano:"
modo "$r" 'enabled: true
gate1: x
plano: agentic/projeto/planos/nao.md'
tl_espera 1 "plano: inexistente bloqueia" roda "$r"
tl_contem "plano:" "cita plano:"

r=$(tl_repo); confirma "$r" "base"; git -C "$r" checkout -q -b feat/k; modo "$r" "enabled: true
gate1: a b
$P"; plano "$r"
tl_espera 1 "item com espaço interno bloqueia" roda "$r"
tl_contem "vazio, todas ou" "explica o formato de gate1"

deleg false "" 'docs(spec): x aprovada (Gate 1 delegado pelo orquestrador)'
tl_espera 1 "assunto fora do formato canônico não passa por si mesmo" roda "$r"
deleg false "" 'docs(spec): x aprovada (Gate 1 delegado, D2x)'
tl_espera 1 "sufixo D<n> malformado não passa por si mesmo" roda "$r"

deleg false "" "$D"
gate "$r" "docs(spec): x aprovada (Gate 1)"
tl_espera 0 "Gate 1 humano da branch libera o delegado" roda "$r"

r=$(tl_repo); confirma "$r" "base"; git -C "$r" checkout -q -b feat/k; gate "$r" "$D"
tl_espera 0 "sem auto-mode: não verificável, não bloqueia" roda "$r"
tl_contem "delegação não verificável neste clone" "declara não verificável"


# Decisões por arquivo: agentic/projeto/decisoes/<slug>.md, citadas como D:<slug>
novo() { r=$(tl_repo); dec "$r" "$@"; confirma "$r" "decisão"; git -C "$r" checkout -q -b feat/k; }
spec() { mkdir -p "$r/agentic/projeto/specs/x"; printf '%s\n' "$1" > "$r/agentic/projeto/specs/x/design.md"; }

novo cache-de-precos; spec 'Conforme D:cache-de-precos.'
tl_espera 0 "só a pasta, sem decisoes.md: D:<slug> resolve" roda "$r"

novo cache-de-precos; spec 'Conforme (D:cache-de-precos), D:cache-de-precos, e D:cache-de-precos'
tl_espera 0 "D:<slug> seguido de pontuação resolve o slug inteiro" roda "$r"

novo cache-de-precos; spec 'Conforme D:frete.'
tl_espera 1 "referência D:<slug> órfã bloqueia" roda "$r"
tl_contem "D:frete (em agentic/projeto/specs/x/design.md)" "aponta o slug e o arquivo"

novo cache-de-precos; spec 'Veja (D:cache)'
tl_espera 1 "prefixo de slug não resolve" roda "$r"
tl_contem "D:cache (em" "aponta o prefixo como órfão"

novo a; dec "$r" b; printf 'Veja D:zzz\n' >> "$r/agentic/projeto/decisoes/b.md"
tl_espera 1 "decisão em arquivo que cita outra inexistente bloqueia" roda "$r"
tl_contem "D:zzz (em agentic/projeto/decisoes/b.md)" "aponta o arquivo de decisão"

novo a; spec 'Veja D3'
tl_espera 1 "D<n> sem decisoes.md é órfã" roda "$r"
tl_contem "D3 (em" "aponta a D3"

# (2) arquivo da base que sumiu
novo a; git -C "$r" rm -q agentic/projeto/decisoes/a.md; dec "$r" b; confirma "$r" "apaga a"
tl_espera 1 "arquivo de decisão da base apagado bloqueia" roda "$r"
tl_contem "revogue-a): a" "nomeia o slug perdido"

novo a; git -C "$r" mv agentic/projeto/decisoes/a.md agentic/projeto/decisoes/a2.md; confirma "$r" "renomeia a"
tl_espera 1 "arquivo de decisão da base renomeado bloqueia" roda "$r"
tl_contem "revogue-a): a" "nomeia o slug antigo"

# (3) registro congelado
r=$(tl_repo); reg "$r" 1; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k; reg "$r" 1 2
tl_espera 1 "### D<n> nova no registro congelado bloqueia" roda "$r"
tl_contem "D2" "nomeia a decisão nova"
tl_contem "decisoes/<slug>.md" "aponta o formato novo"

r=$(tl_repo); reg "$r" 1 2; confirma "$r" "registro"; git -C "$r" checkout -q -b feat/k
tl_espera 0 "### D<n> que já estava na base passa" roda "$r"

# (4) formato
novo ok; mkdir -p "$r/agentic/projeto/decisoes"; printf '# x\n\n**Status:** vigente\n' > "$r/agentic/projeto/decisoes/Cache_Precos.md"
tl_espera 1 "nome fora do slug bloqueia" roda "$r"
tl_contem "Cache_Precos.md: nome não é slug" "nomeia o arquivo"

novo ok; printf '**Status:** vigente\n' > "$r/agentic/projeto/decisoes/semtitulo.md"
tl_espera 1 "arquivo sem título bloqueia" roda "$r"
tl_contem "sem título" "explica a falta de título"

novo ok; printf '# t\n\n**Status:** aprovado\n' > "$r/agentic/projeto/decisoes/aprov.md"
tl_espera 1 "status inválido bloqueia" roda "$r"
tl_contem "**Status:**" "explica o status"

novo ok; dec "$r" a "revogada em 2026-11-25: trocada por b"
tl_espera 0 "status revogada válido passa" roda "$r"

novo ok; printf '# t\r\n\r\n**Status:** vigente\r\n' > "$r/agentic/projeto/decisoes/crlf.md"; spec 'Veja D:crlf.'
tl_espera 0 "arquivo de decisão com CRLF passa" roda "$r"

novo ok; mkdir -p "$r/agentic/projeto/decisoes/x"; : > "$r/agentic/projeto/decisoes/.gitkeep"; printf 'sem formato\n' > "$r/agentic/projeto/decisoes/x/y.md"
tl_espera 0 ".gitkeep e subpasta são ignorados" roda "$r"

r=$(tl_repo)
tl_espera 0 "sem registro nem pasta: pulado" roda "$r"
tl_contem "pulado" "declara que pulou"


novo ok; : > "$r/agentic/projeto/decisoes/vazia.md"; spec 'Veja D:vazia.'
tl_espera 1 "arquivo de decisão vazio bloqueia" roda "$r"
tl_contem 'vazia.md: sem título' "vazio: sem título"
tl_contem 'vazia.md: sem **Status:**' "vazio: sem status"

novo ok; : > "$r/agentic/projeto/decisoes/Ruim.md"
tl_espera 1 "arquivo de decisão vazio com nome fora do slug bloqueia" roda "$r"
tl_contem 'Ruim.md: nome não é slug' "vazio: nome fora do slug"

tl_fim
