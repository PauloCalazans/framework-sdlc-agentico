#!/bin/sh
# montar-exemplo.sh <nome> <destino> — cria um projeto-exemplo isolado e instala o kit nele.
fw=$(cd "$(dirname "$0")/.." && pwd)
nome=${1:-}; dest=${2:-}
{ [ -n "$nome" ] && [ -n "$dest" ]; } || { echo "uso: montar-exemplo.sh <nome> <destino>" >&2; exit 2; }
[ -d "$fw/exemplos/$nome" ] || { echo "exemplo inexistente: $nome" >&2; exit 2; }
[ ! -e "$dest" ] || { echo "destino já existe: $dest" >&2; exit 2; }

cp -R "$fw/exemplos/$nome" "$dest"
git -C "$dest" init -q -b main
git -C "$dest" config core.autocrlf false
git -C "$dest" add -A
git -C "$dest" -c user.email=exemplo@exemplo.invalid -c user.name=exemplo commit -q -m "inicial"
sh "$fw/bootstrap/instalar.sh" "$dest"
