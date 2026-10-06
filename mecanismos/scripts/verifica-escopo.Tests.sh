#!/bin/sh
# Testes do verifica-escopo.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/docs/specs/pedidos/tasks" "$r/src/pedidos" "$r/tests"
  cat > "$r/docs/specs/pedidos/tasks/001-criar.md" <<'EOT'
# Task 001
**Status:** em-andamento
**Branch:** pedidos/001

## Arquivos
- `src/pedidos/*`
- tests/test_pedidos.py — testes da task

## Critérios de pronto
- src/fora.py não deve contar como escopo só por aparecer aqui
EOT
  git -C "$r" add -A; git -C "$r" commit -q -m "task"
  git -C "$r" checkout -q -b pedidos/001
  printf '%s\n' "$r"
}

r=$(prepara)
echo x > "$r/src/pedidos/criar.py"; echo t > "$r/tests/test_pedidos.py"
git -C "$r" add -A; git -C "$r" commit -q -m "impl"
tl_espera 0 "aceita arquivos dentro do escopo (glob e caminho)" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

echo y > "$r/docs/specs/pedidos/spec.md"
tl_espera 0 "aceita alteração na pasta da própria spec" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

echo z > "$r/src/fora.py"
tl_espera 1 "rejeita arquivo não rastreado fora do escopo" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
tl_contem "src/fora.py" "lista o arquivo fora do escopo"

r=$(prepara)
mkdir -p "$r/docs"; echo e > "$r/docs/a b.md"
tl_espera 1 "rejeita arquivo com espaço no nome" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
tl_contem "docs/a b.md" "reporta o nome com espaço inteiro"

tl_espera 2 "uso incorreto sem task" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh'"

r=$(prepara)
mkdir -p "$r/.agentic/verify.lock" "$r/.agentic/execucao"; echo 1 > "$r/.agentic/verify.lock/pid"; echo l > "$r/.agentic/execucao/log"
tl_espera 0 "ignora estado de runtime do framework (.agentic/verify.lock e execucao)" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

r=$(prepara)
tl_espera 1 "base inválida falha fechado" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md base-inexistente"

r=$(prepara)
echo a > "$r/src/pedidos/critérios.py"
tl_espera 0 "aceita nome acentuado dentro do escopo" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

r=$(prepara)
echo l > "$r/src/legado.py"; git -C "$r" add -A; git -C "$r" commit -q -m legado
git -C "$r" mv src/legado.py src/pedidos/legado.py; git -C "$r" commit -q -m mv
tl_espera 1 "rename de fora do escopo para dentro lista o caminho antigo" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md HEAD~1"
tl_contem "src/legado.py" "lista o caminho antigo"

r=$(prepara)
echo x > "$r/src/pedidos/criar.py"; git -C "$r" add -A; git -C "$r" commit -q -m "impl"
mkdir -p "$r/.agentic/worktrees/pedidos-002/src"; echo y > "$r/.agentic/worktrees/pedidos-002/src/outro.py"
tl_espera 0 "ignora worktrees aninhados em .agentic/worktrees/ mesmo sem .gitignore" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
r=$(prepara)
printf '# Spec\r\n**Intent:** intent/001-pedidos.md \r\n' > "$r/docs/specs/pedidos/spec.md"
mkdir -p "$r/intent"; echo i > "$r/intent/001-pedidos.md"
tl_espera 0 "isenta o intent referenciado pela spec da task" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"

echo i > "$r/intent/002-outro.md"
tl_espera 1 "rejeita outro intent não referenciado pela spec" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
tl_contem "intent/002-outro.md" "lista o intent não referenciado"

r=$(prepara)
mkdir -p "$r/intent"; echo i > "$r/intent/001-pedidos.md"
tl_espera 1 "sem spec.md não há isenção de intent" sh -c "cd '$r' && sh '$dir/verifica-escopo.sh' docs/specs/pedidos/tasks/001-criar.md"
tl_fim
