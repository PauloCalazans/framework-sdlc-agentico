<!-- Template de brief de papel. O orquestrador preenche e apaga este comentário; o brief começa na linha "Papel:".
Por quê: cada requisição do papel reenvia o contexto inteiro. Arquivo lido inteiro, saída de shell larga e exploração
sem rumo são contexto inútil; "leia só isto", saída curta e teto declarado cortam esse custo. E a regra que está só no
contrato linkado não chega ao papel: o brief é o texto que ele lê com atenção.

- Meta: até ~40 linhas. Brief maior vira um segundo contrato e traz o custo de volta.
- Toda seção obrigatória aparece; quando não há nada a dizer, escreva `nenhum`.
- Caminhos absolutos sempre, inclusive em rodada de correção. `Papel:` é o nome exato de um contrato de agentic/processo/papeis/.
- Rodada de correção: copie para um arquivo novo o brief anterior do mesmo papel, inteiro; reescreva "O que fazer",
  acrescente "Desde a rodada anterior" e ajuste o resto só onde a rodada mudou. Nunca "mesmo contrato", "mesmo escopo
  do brief anterior" nem "continuação": o papel numa sessão nova não tem o brief anterior.
- Arquivos na pasta de execução agentic/.estado/execucao/<AAAA-MM-DD>-<nome>/, pela ordem de despacho (NN = 01, 02, …):
  brief `NN-<papel>[-<modo>]-brief.md`; relatório `NN-<papel>[-<modo>]-relatorio.md`; revisor `NN-revisor-<modo>-parecer.md`
  (pelo template agentic/processo/templates/parecer.md).
- Linha de retorno: `NN-<papel>: <FEITO|FEITO_COM_RESSALVAS|BLOQUEADO> | <campos do "Ao terminar" do contrato> | <arquivo de relatório>`;
  no revisor: `NN-revisor-<modo>: <APROVADO|DEVOLVIDO> | C n I n M n | <arquivo do parecer>`.
-->
Papel: <papel exato do kit>[ — modo <modo>]
Contrato: <caminho absoluto de agentic/processo/papeis/<papel>.md>
Perfil: <caminho absoluto de agentic/projeto/papeis/<papel>.md>[; <outro perfil absoluto>]
Task: <caminho da task ou do documento enxuto> — fase <n>

## Escopo
Worktree: <caminho absoluto> (branch <branch>). Escreva só em: <caminhos>. Precisa de outro arquivo: PARE e pergunte pelo canal de dúvida.

## O que fazer
<até 5 linhas; cada uma, uma entrega verificável>

## Já decidido
<Rulings, respostas do humano e itens N3 que você não reabre, um por linha, ou: nenhum>

## Nunca faz
<as linhas de "No brief" do contrato que valem nesta rodada, coladas; mais os itens de "Padrões" e "Nunca faz neste
projeto" do perfil que se aplicam. Em forma de ação: "PARE e diga", nunca um link>

## Leia só isto
- <arquivo>:<a>-<b> — <para quê> (até ~80 linhas por trecho; nada de "leia o arquivo" nem "veja o commit")

## Comandos
- <comando exato, com saída limitada e em primeiro plano>
- Quem roda cada verificação longa: <você | o orquestrador>. Exceção: o brief nunca tira do `revisor` o
  `sh agentic/mecanismos/scripts/verify.sh`; ele o roda, em primeiro plano.
- Proibido: <ex.: push, leitura de código de dependência, verificação que é do orquestrador>.

## Teto
~<n> requisições (ou turnos, na ferramenta que não conta requisições). Ao atingir: pare, comite o que estiver pronto
(se o seu papel comita) e reporte onde travou.

## Entrega
- Commits (sem push): <tipo(escopo): mensagem>, ou: nenhum (o revisor não comita).
- Relatório: <caminho absoluto do NN-…-relatorio.md ou NN-revisor-<modo>-parecer.md>.
- Retorno, uma linha: <linha de retorno com os campos deste papel>.
- Dúvida que trava: <canal>; espere a resposta.

## Desde a rodada anterior
<só em rodada de correção, obrigatória: brief anterior (caminho), o parecer ou relatório que motivou a rodada (caminho
e IDs dos achados) e o que mudou. Não substitui nenhuma seção acima>

## Assinaturas
<testes e dev, quando há contrato executável: tipos, métodos e records colados, para o papel não procurar>

## API externa
<testes e dev, quando o papel usa biblioteca externa: um snippet pronto>

<!-- Antes de enviar (o orquestrador confere; nenhum mecanismo obriga, é por revisão):
- [ ] cabeçalho de quatro linhas, caminhos absolutos, `Papel:` igual ao nome do contrato;
- [ ] em correção: copiado do brief anterior, com "Desde a rodada anterior";
- [ ] toda leitura com intervalo; todo comando com saída limitada;
- [ ] teto declarado;
- [ ] "Nunca faz" colado, não linkado.

Ao receber (antes de passar a entrega adiante):
- [ ] `sh agentic/mecanismos/scripts/verifica-escopo.sh <task.md>` na branch do papel;
- [ ] depois do RED: `sh agentic/mecanismos/scripts/verifica-red.sh`; depois da GREEN: `sh agentic/mecanismos/scripts/verify.sh`;
- [ ] revisor, modo diff: `git rev-parse HEAD` no worktree igual ao SHA final do intervalo do brief (o revisor não
  comita) e `git status --porcelain` vazio;
- [ ] revisor, modos spec, design e mudanca (nada commitado): `git status --porcelain` e
  `{ git diff; git ls-files -o --exclude-standard | xargs cat; } | sha256sum` iguais aos que você anotou no
  progress.md antes do despacho. O parecer fica fora do que é conferido;
- [ ] a linha de retorno confere com o arquivo de relatório.
Desvio que é da stack não entra aqui: pelo Princípio 2, vai para o CMD_VERIFY_STACK do projeto.
-->
