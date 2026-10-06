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
