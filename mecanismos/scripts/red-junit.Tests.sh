#!/bin/sh
# Testes do red-junit.sh: o código de saída vem do JUnit XML, não do comando.
dir=$(cd "$(dirname "$0")" && pwd)
. "$dir/testlib.sh"

r=$(mktemp -d)
# rj <conteúdo do XML ou -> [código do comando]: limpa out/, roda o red-junit com um comando que grava o XML.
rj() {
  rm -rf "$r/out"; mkdir -p "$r/out"
  if [ "$1" = - ]; then
    sh "$dir/red-junit.sh" "$r/out/*.xml" -- sh -c "exit ${2:-0}"
  else
    printf '%s\n' "$1" > "$r/xml"
    sh "$dir/red-junit.sh" "$r/out/*.xml" -- sh -c "cp '$r/xml' '$r/out/TEST-a.xml'; exit ${2:-0}"
  fi
}

tl_espera 1 "junit: failure é RED" rj '<testsuite><testcase name="a"><failure message="x"/></testcase></testsuite>' 1
tl_contem "red-junit: casos 1 failure 1 error 0 -> 1" "junit: resumo na saída"
tl_espera 0 "junit: casos sem falha passam" rj '<testsuite><testcase name="a"/><testcase name="b"></testcase></testsuite>' 1
tl_contem "red-junit: casos 2 failure 0 error 0 -> 0" "junit: o código do comando é ignorado"
tl_espera 126 "junit: sem XML não é evidência" rj - 1
tl_espera 126 "junit: zero casos não é evidência" rj '<testsuite tests="0"></testsuite>' 1
tl_espera 126 "junit: só error (compilação/coleta) não é evidência" rj '<testsuite><testcase name="a"><error message="boom"/></testcase></testsuite>' 1
tl_espera 1 "junit: failure e error juntos é RED" rj '<testsuite><testcase name="a"><failure/></testcase><testcase name="b"><error/></testcase></testsuite>' 1
tl_espera 0 "junit: atributos failures= e errors= não contam como elemento" rj '<testsuite failures="0" errors="0"><testcase name="a"/></testsuite>'
tl_espera 126 "junit: sem -- é uso inválido" sh "$dir/red-junit.sh" "$r/out/*.xml" sh -c 'exit 0'
tl_contem "uso:" "junit: explica o uso"
tl_espera 126 "junit: sem comando é uso inválido" sh "$dir/red-junit.sh" "$r/out/*.xml" --
rm -rf "$r/out"; mkdir -p "$r/out"
printf '<testsuite><testcase name="a"/></testsuite>\n' > "$r/out/TEST-1.xml"
printf '<testsuite><testcase name="b"><failure/></testcase></testsuite>\n' > "$r/out/TEST-2.xml"
tl_espera 1 "junit: soma os arquivos do glob" sh "$dir/red-junit.sh" "$r/out/*.xml" -- true
tl_contem "casos 2 failure 1 error 0 -> 1" "junit: contagem somada"

tl_fim
