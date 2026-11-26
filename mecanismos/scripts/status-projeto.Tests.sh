#!/bin/sh
# Testes do status-projeto.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(tl_repo)
mkdir -p "$r/agentic/projeto/intent" "$r/agentic/projeto/specs/pedidos/tasks" "$r/agentic/.estado"
printf '# Intent: pedidos\n**Status:** aprovado\n' > "$r/agentic/projeto/intent/001-pedidos.md"
printf '# Task 001\n**Status:** em-andamento\n**Branch:** pedidos/001\n' > "$r/agentic/projeto/specs/pedidos/tasks/001-criar.md"
printf '# modelo\n**Status:** <x>\n' > "$r/agentic/projeto/specs/_template.md"
echo "enabled: true" > "$r/agentic/auto-mode"
git -C "$r" checkout -q -b pedidos/001
git -C "$r" commit -q --allow-empty -m "w1"

tl_espera 0 "status sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Branch atual: pedidos/001" "mostra a branch atual"
tl_contem "agentic/projeto/intent/001-pedidos.md: aprovado" "lista status de intent"
tl_contem "agentic/projeto/specs/pedidos/tasks/001-criar.md: em-andamento" "lista status de task"
tl_contem "pedidos/001: 1 commit(s)" "mostra branch à frente da principal"
tl_contem "Modo automático: ligado" "lê o auto-mode"
tl_contem "Gate 1: humano" "sem gate1, o Gate 1 é humano"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "ignora arquivos _modelo" grep -q "_template" "$copia_saida"
mkdir -p "$r/agentic/projeto/specs/pedidos/pareceres"
printf '# Parecer — diff — pedidos/001 — rodada 2\n**Veredito:** APROVADO · C 0 I 0 M 1\n' \
  > "$r/agentic/projeto/specs/pedidos/pareceres/001-diff.md"
tl_espera 0 "status com parecer copiado sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_espera 1 "não lista parecer copiado para pareceres/" grep -q "pareceres/" "$TL_SAIDA"

# Review Focus 2: repositório sem a branch principal.
r2=$(mktemp -d); git -C "$r2" init -q -b trabalho
tl_espera 0 "não quebra sem a branch principal e sem commits" sh -c "cd '$r2' && sh '$dir/status-projeto.sh'"
tl_contem "Modo automático: desligado" "auto-mode ausente = desligado"
tl_contem "Gate 1: humano" "auto-mode ausente = Gate 1 humano"

printf 'enabled: true\ngate1: todas\n' > "$r/agentic/auto-mode"
tl_espera 0 "status com Gate 1 delegado sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Gate 1: delegado ao orquestrador (todas)" "mostra a decisão que delega o Gate 1"
printf 'enabled: false\ngate1: todas\n' > "$r/agentic/auto-mode"
tl_espera 0 "status com modo automático desligado sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "Gate 1: humano" "delegação só vale com o modo automático ligado"

# integrada deriva do git: task publicada cuja versão na principal (local ou origin/) também está publicada.
r3=$(tl_repo)
t=agentic/projeto/specs/pedidos/tasks
mkdir -p "$r3/$t"
printf '# Task 001\n**Status:** pendente\n' > "$r3/$t/001-integrada.md"
printf '# Task 002\n**Status:** pendente\n' > "$r3/$t/002-aberta.md"
printf '# Task 003\n**Status:** em-andamento\n' > "$r3/$t/003-andamento.md"
printf '# Task 004\n**Status:** pendente\n' > "$r3/$t/004-remota.md"
git -C "$r3" add -A; git -C "$r3" commit -q -m "Gate 1"
printf '# Task 001\n**Status:** publicada — PR #1\n' > "$r3/$t/001-integrada.md"
git -C "$r3" commit -q -am "docs(task): 001 publicada"   # merge na principal
printf '# Task 004\n**Status:** publicada\n' > "$r3/$t/004-remota.md"
git -C "$r3" commit -q -am "docs(task): 004 publicada"
git -C "$r3" update-ref refs/remotes/origin/main HEAD    # 004 integrada no remoto
git -C "$r3" reset -q --hard HEAD~1                      # main local ainda sem o merge da 004
git -C "$r3" checkout -q -b pedidos/002
printf '# Task 002\n**Status:** publicada\n' > "$r3/$t/002-aberta.md"
printf '# Task 004\n**Status:** publicada\n' > "$r3/$t/004-remota.md"
git -C "$r3" commit -q -am "docs(task): 002 publicada (PR aberto)"
tl_espera 0 "status com tasks publicadas sai com 0" sh -c "cd '$r3' && sh '$dir/status-projeto.sh'"
tl_contem "001-integrada.md: integrada (derivado do git) — publicada — PR #1" "publicada também na principal: integrada"
tl_contem "002-aberta.md: publicada" "publicada só na branch (PR aberto): continua publicada"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "PR aberto não aparece como integrada" grep -q "002-aberta.md: integrada" "$copia_saida"
tl_espera 0 "status diferente de publicada não muda" grep -q "003-andamento.md: em-andamento$" "$copia_saida"
tl_espera 0 "publicada na principal remota (local desatualizada): integrada" grep -q "004-remota.md: integrada (derivado do git) — publicada$" "$copia_saida"

# Só a primeira linha **Status:** conta, no arquivo e na versão da principal; nome com espaço e Status vazio.
r7=$(tl_repo)
mkdir -p "$r7/$t"
printf '# Task 001\n**Status:** pendente\n\nExemplo:\n**Status:** publicada\n' > "$r7/$t/001-exemplo.md"
printf '# Task 002\n**Status:** aprovado\n' > "$r7/$t/002 com espaco.md"
printf '# Task 003\n**Status:**\n' > "$r7/$t/003-vazio.md"
git -C "$r7" add -A; git -C "$r7" commit -q -m "Gate 1"
git -C "$r7" checkout -q -b pedidos/001
printf '# Task 001\n**Status:** publicada\n\nExemplo:\n**Status:** publicada\n' > "$r7/$t/001-exemplo.md"
git -C "$r7" commit -q -am "docs(task): 001 publicada (PR aberto)"
tl_espera 0 "status com segunda linha Status sai com 0" sh -c "cd '$r7' && sh '$dir/status-projeto.sh'"
tl_contem "001-exemplo.md: publicada" "publicada na branch"
tl_contem "002 com espaco.md: aprovado" "artefato com espaço no nome é listado"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "segunda linha Status da principal não torna a task integrada" grep -q "001-exemplo.md: integrada" "$copia_saida"
tl_espera 1 "Status vazio não é listado" grep -q "003-vazio.md" "$copia_saida"
git -C "$r7" checkout -q main
tl_espera 0 "status na principal sai com 0" sh -c "cd '$r7' && sh '$dir/status-projeto.sh'"
tl_contem "001-exemplo.md: pendente" "a primeira linha Status é a que vale"

# em-andamento deriva do git: task pendente cuja branch (**Branch:**) está à frente da principal.
r4=$(tl_repo)
t=agentic/projeto/specs/pedidos/tasks
mkdir -p "$r4/$t"
printf '# Task 001\r\n**Status:** pendente\r\n**Branch:** `pedidos/001`\r\n' > "$r4/$t/001-criar.md"
printf '# Task 002\n**Status:** pendente\n**Branch:** pedidos/002\n' > "$r4/$t/002-sem-branch.md"
printf '# Task 003\n**Status:** em-andamento\n**Branch:** pedidos/003\n' > "$r4/$t/003-legado.md"
git -C "$r4" add -A; git -C "$r4" commit -q -m "Gate 1"
git -C "$r4" checkout -q -b pedidos/001
git -C "$r4" commit -q --allow-empty -m "test(red): x"
git -C "$r4" checkout -q main
tl_espera 0 "status deriva em-andamento do git" sh -c "cd '$r4' && sh '$dir/status-projeto.sh'"
tl_contem "001-criar.md: em-andamento (derivado do git)" "mostra derivado"
tl_contem "002-sem-branch.md: pendente" "pendente sem branch fica pendente"
tl_contem "003-legado.md: em-andamento" "em-andamento escrito continua lido"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "pendente sem branch não é derivado" grep -q "002-sem-branch.md: em-andamento" "$copia_saida"

# O commit de registro do Gate 1 não conta; task empilhada conta a partir da branch-base.
r5=$(tl_repo)
mkdir -p "$r5/$t"
printf '# Task 001\n**Status:** pendente\n**Branch:** pedidos/001\n' > "$r5/$t/001-a.md"
printf '# Task 002\n**Status:** pendente\n**Branch:** pedidos/002\n**Base:** pedidos/001\n' > "$r5/$t/002-b.md"
git -C "$r5" add -A; git -C "$r5" commit -q -m "base"
git -C "$r5" checkout -q -b pedidos/001
git -C "$r5" commit -q --allow-empty -m "docs(mudanca): a aprovada (Gate 1)"
git -C "$r5" checkout -q -b pedidos/002
git -C "$r5" commit -q --allow-empty -m "docs(mudanca): b aprovada (Gate 1)"
git -C "$r5" checkout -q main
tl_espera 0 "status com branches só com o commit do Gate 1" sh -c "cd '$r5' && sh '$dir/status-projeto.sh'"
tl_contem "001-a.md: pendente" "só o commit do Gate 1: continua pendente"
tl_contem "002-b.md: pendente" "empilhada só com commits da base e o Gate 1: continua pendente"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "nenhuma derivada de só Gate 1" grep -q "em-andamento" "$copia_saida"
git -C "$r5" checkout -q pedidos/002
git -C "$r5" commit -q --allow-empty -m "test(red): b"
git -C "$r5" checkout -q main
tl_espera 0 "status com um commit além do Gate 1" sh -c "cd '$r5' && sh '$dir/status-projeto.sh'"
tl_contem "002-b.md: em-andamento (derivado do git)" "um commit além do Gate 1 na empilhada: em andamento"
tl_contem "001-a.md: pendente" "a base continua pendente"

# A principal local é comparada com a remota (último fetch, sem rede): branch já integrada no remoto não aparece
# à frente, principal atrasada é avisada e branch com a remota apagada é apontada.
r6=$(tl_repo); git -C "$r6" remote add origin "$r6/nao-existe"
git -C "$r6" checkout -q -b feita
git -C "$r6" commit -q --allow-empty -m "feat: feita"
git -C "$r6" update-ref refs/remotes/origin/main HEAD       # merge da feita no remoto
git -C "$r6" config branch.feita.remote origin; git -C "$r6" config branch.feita.merge refs/heads/feita
git -C "$r6" checkout -q -b aberta main
git -C "$r6" commit -q --allow-empty -m "feat: aberta"
git -C "$r6" update-ref refs/remotes/origin/aberta HEAD
git -C "$r6" config branch.aberta.remote origin; git -C "$r6" config branch.aberta.merge refs/heads/aberta
git -C "$r6" checkout -q -b orfa main
git -C "$r6" commit -q --allow-empty -m "feat: orfa"
git -C "$r6" config branch.orfa.remote origin; git -C "$r6" config branch.orfa.merge refs/heads/orfa
git -C "$r6" checkout -q main
tl_espera 0 "status com a principal atrás da remota sai com 0" sh -c "cd '$r6' && sh '$dir/status-projeto.sh'"
tl_contem "main: 1 commit(s) atrás de origin/main" "avisa a principal local atrasada"
tl_contem "aberta: 1 commit(s)" "branch não integrada continua à frente"
tl_contem "orfa: 1 commit(s) — remota apagada" "branch não integrada com a remota apagada é apontada"
tl_contem "feita: integrada em origin/main" "branch integrada só no remoto é apontada para limpeza"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "integrada no remoto não aparece à frente" grep -q "feita: 1 commit" "$copia_saida"
tl_espera 1 "aberta com remota existente não é apontada" grep -q "aberta: 1 commit(s) —" "$copia_saida"
git -C "$r6" merge -q --ff-only origin/main
tl_espera 0 "status com a principal em dia sai com 0" sh -c "cd '$r6' && sh '$dir/status-projeto.sh'"
tl_contem "main: em dia com origin/main" "principal em dia"
tl_espera 0 "sem origin/main sai com 0" sh -c "cd '$r' && sh '$dir/status-projeto.sh'"
tl_contem "main: sem origin/main" "sem remota, diz que não há com o que comparar"

# Kit atualizado: o status aponta o que mudou no ciclo.md, derivado do último commit que o tocou. Importar a
# atualização não basta: a sessão do orquestrador só relê o que lhe apontam no início.
ciclo() { # ciclo <repo> <texto de Onde> <linha da tabela> <item de Commits, ou vazio>
  mkdir -p "$1/agentic/processo/templates" "$1/agentic/processo/papeis"
  {
    printf '# Ciclo\n\nLeia antes de qualquer trabalho.\n\n## Trilha padrão\n\n| # | Fase |\n|---|---|\n| 3 | %s |\n\n' "$3"
    printf '## Regras de fluxo\n\n- **Isolamento:** um worktree por task.\n'
    [ -n "$4" ] && printf -- '- **Commits:** %s\n' "$4"
    printf '\n## Orquestração\n\n1. lê `status-projeto`;\n\n**Oráculo:** só leitura.\n\n## Rulings\n\n- **Onde:** %s\n- **Limite:** não contradiz a spec.\n' "$2"
  } > "$1/agentic/processo/ciclo.md"
}
r8=$(tl_repo)
tl_espera 0 "status sem o kit instalado sai com 0" sh -c "cd '$r8' && sh '$dir/status-projeto.sh'"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "sem ciclo.md, não há seção do kit" grep -q "^### Kit" "$copia_saida"
ciclo "$r8" "commit próprio da Ruling." "RED" "um commit por passo."
printf 'brief v1\n' > "$r8/agentic/processo/templates/brief.md"; printf 'revisor v1\n' > "$r8/agentic/processo/papeis/revisor.md"
tl_espera 0 "status com o kit ainda sem commit sai com 0" sh -c "cd '$r8' && sh '$dir/status-projeto.sh'"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "ciclo.md ainda sem commit: não há o que derivar" grep -q "^### Kit" "$copia_saida"
git -C "$r8" add -A; git -C "$r8" commit -q -m "chore: instancia o kit"
sha=$(git -C "$r8" log -1 --format=%h); dia=$(git -C "$r8" log -1 --format=%cd --date=short)
tl_espera 0 "status com o kit recém-instalado sai com 0" sh -c "cd '$r8' && sh '$dir/status-projeto.sh'"
tl_contem "### Kit" "seção do kit"
tl_contem "- agentic/processo/ciclo.md instalado em $dia ($sha): leia-o inteiro antes de orquestrar." "instalação: manda ler inteiro"

ciclo "$r8" "no próximo commit do papel; não há commit só de Ruling." "RED provado" "um commit por passo."
printf 'brief v2\n' > "$r8/agentic/processo/templates/brief.md"
printf 'x\n' > "$r8/fora-do-kit.txt"
git -C "$r8" add -A; git -C "$r8" commit -q -m "chore(kit): atualiza o kit"
sha=$(git -C "$r8" log -1 --format=%h)
git -C "$r8" commit -q --allow-empty -m "feat: trabalho depois da atualização"
tl_espera 0 "status depois de atualizar o kit sai com 0" sh -c "cd '$r8' && sh '$dir/status-projeto.sh'"
tl_contem "- agentic/processo/ciclo.md mudou em $dia ($sha). Releia antes de orquestrar: \"Trilha padrão\"; \"Rulings\" (Onde)." "aponta as seções e os itens alterados, na ordem do arquivo"
tl_contem "- No mesmo commit, em agentic/processo/: templates/brief.md" "lista os outros arquivos do processo que mudaram"
copia_saida=$(mktemp); cp "$TL_SAIDA" "$copia_saida"
tl_espera 1 "seção não alterada não é apontada" grep -q '"Orquestração"\|"Regras de fluxo"\|Limite' "$copia_saida"
tl_espera 1 "arquivo de fora do processo não é listado" grep -q "fora-do-kit" "$copia_saida"
tl_espera 1 "arquivo do processo que não mudou não é listado" grep -q "papeis/revisor.md" "$copia_saida"
tl_espera 0 "a seção do kit vem antes dos worktrees" sh -c "awk '/^### Kit/ { k = NR } /^### Worktrees/ { w = NR } END { exit (k && w && k < w) ? 0 : 1 }' '$copia_saida'"

# Item removido: a seção onde ele estava é apontada.
ciclo "$r8" "no próximo commit do papel; não há commit só de Ruling." "RED provado" ""
git -C "$r8" commit -q -am "chore(kit): tira um item"
sha=$(git -C "$r8" log -1 --format=%h)
tl_espera 0 "status depois de remover um item sai com 0" sh -c "cd '$r8' && sh '$dir/status-projeto.sh'"
tl_contem "($sha). Releia antes de orquestrar: \"Regras de fluxo\"" "remoção: aponta a seção"

# Kit copiado e ainda não commitado (instalador acabou de rodar): o aviso já sai.
ciclo "$r8" "no próximo commit do papel; não há commit só de Ruling." "RED provado" "um commit por passo do ciclo."
tl_espera 0 "status com atualização do kit sem commit sai com 0" sh -c "cd '$r8' && sh '$dir/status-projeto.sh'"
tl_contem "- agentic/processo/ciclo.md tem mudança ainda sem commit. Releia antes de orquestrar: \"Regras de fluxo\" (Commits)." "sem commit: aponta o que difere do HEAD"

tl_fim
