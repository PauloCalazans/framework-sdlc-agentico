#!/bin/sh
# Testes do verifica-skip.sh.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

prepara() {
  r=$(tl_repo)
  mkdir -p "$r/.agentic" "$r/tests" "$r/relatorio"
  cat > "$r/.agentic/config" <<'EOT'
MARCADOR_DESABILITADO='@unittest\.skip|\.skip\('
RELATORIO_TESTES="relatorio/*.xml"
EOT
  git -C "$r" add -A; git -C "$r" commit -q -m "config"
  git -C "$r" checkout -q -b feat/k
  printf '%s\n' "$r"
}
junit() { printf '<testsuite><testcase name="a"/>%s</testsuite>\n' "$2" > "$1/relatorio/junit.xml"; }

r=$(prepara); junit "$r" ""
echo "def test_a(): pass" > "$r/tests/test_a.py"
tl_espera 0 "passa sem marcador novo e sem skip no relatório" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" ""
printf '@unittest.skip("depois")\ndef test_b(): pass\n' > "$r/tests/test_b.py"
tl_espera 1 "falha com marcador em arquivo novo não rastreado" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "desabilitado" "explica o motivo"
git -C "$r" add -A; git -C "$r" commit -q -m "skip commitado"
tl_espera 1 "falha com marcador em commit da branch" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

# A varredura de marcador só olha os diretórios de teste (DIRS_TESTE; padrão "tests/ test/").
r=$(prepara); junit "$r" ""; mkdir -p "$r/docs" "$r/scripts"
printf 'Exemplo: @unittest.skip("x")\n' > "$r/docs/x.md"
tl_espera 0 "marcador em arquivo novo fora de DIRS_TESTE não bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
printf 'grep -E "\\.skip\\(" a\n' > "$r/scripts/kit.sh"
git -C "$r" add -A; git -C "$r" commit -q -m "docs e kit"
tl_espera 0 "marcador commitado fora de DIRS_TESTE não bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
printf '@unittest.skip("x")\ndef test_c(): pass\n' > "$r/tests/test_c.py"
git -C "$r" add -A; git -C "$r" commit -q -m "skip em teste"
tl_espera 1 "marcador commitado dentro de DIRS_TESTE bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" ""
printf '@unittest.skip("x")\ndef test_d(): pass\n' > "$r/tests/test_ação.py"
tl_espera 1 "marcador em arquivo novo com acento em DIRS_TESTE bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" ""; echo 'DIRS_TESTE=""' >> "$r/.agentic/config"
tl_espera 1 "marcador configurado com DIRS_TESTE vazio bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "DIRS_TESTE" "explica DIRS_TESTE vazio"

r=$(prepara)
printf '<testsuite><testcase name="b"><skipped/></testcase></testsuite>\n' > "$r/relatorio/junit a.xml"
tl_espera 1 "relatório com espaço no nome é lido (skip acima do baseline bloqueia)" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "1 teste(s) pulado(s)" "conta o skip do relatório com espaço"
printf '<testsuite><testcase name="b"/></testsuite>\n' > "$r/relatorio/junit a.xml"
tl_espera 0 "relatório com espaço no nome e sem skip passa" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" '<testcase name="b"><skipped/></testcase>'
tl_espera 1 "falha com skip no relatório acima do baseline" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

echo 1 > "$r/.agentic/baseline-skips"
tl_espera 0 "aceita skips até o baseline registrado" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

printf '1\r\n' > "$r/.agentic/baseline-skips"
tl_espera 0 "baseline com CRLF é aceito" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
printf 'abc\n' > "$r/.agentic/baseline-skips"
tl_espera 1 "baseline não numérico bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
: > "$r/.agentic/baseline-skips"
tl_espera 1 "baseline vazio bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara); junit "$r" '<testcase name="b"><skipped/></testcase><testcase name="c"><skipped/></testcase>'
echo 1 > "$r/.agentic/baseline-skips"
tl_espera 1 "2 skips com baseline 1 bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(prepara)
tl_espera 1 "falha se o relatório configurado não existe" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"

r=$(tl_repo); git -C "$r" checkout -q -b feat/sem-config
tl_espera 0 "sem configuração: degradado, não falha" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "degradado" "declara a verificação degradada"

r=$(prepara); junit "$r" ""
tl_espera 1 "base explícita inválida bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh' nao-existe-xyz"
tl_contem "base inválida" "explica base inválida"

r=$(prepara); junit "$r" ""
git -C "$r" branch -m main trunk
tl_espera 1 "marcador configurado sem base (sem main) bloqueia" sh -c "cd '$r' && sh '$dir/verifica-skip.sh'"
tl_contem "BLOQUEADO" "marcador sem base não é apenas degradado"

tl_fim
