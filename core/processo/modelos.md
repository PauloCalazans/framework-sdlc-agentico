# Escolha de modelo por papel

Lido pelo orquestrador e pelo `/bootstrap`. Os papéis não precisam deste arquivo.

**Regra-mãe:** otimize o custo da task **aprovada**, não o da chamada. Um modelo barato que gera rodada extra de revisão, retrabalho ou conferência pelo orquestrador sai mais caro que um modelo forte aprovado na primeira.

## Níveis
Por capacidade, não por nome (os nomes mudam a cada poucos meses):
- **forte** — o modelo de raciocínio de topo disponível;
- **médio** — o modelo de código de uso geral;
- **leve** — o rápido e barato.

O mapeamento produto/modelo → nível fica na decisão de composição do time, em `agentic/projeto/decisoes.md`.

## Nível de partida por papel
O nível acompanha o custo do erro que escapa e a existência de um mecanismo que o pegue.

| Papel | Nível | Por quê |
|---|---|---|
| `arquiteto` | forte | o design vira tasks, escopo e contrato; o erro se multiplica por todas as tasks e nenhum script o pega |
| `revisor` | forte | último filtro antes do humano; um APROVADO fraco obriga o orquestrador a refazer a conferência no modelo mais caro |
| `dominio` | médio | o erro é pego pelo `revisor` em modo `spec` e pelo humano no Gate 1 |
| `testes` | médio | `verifica-red.sh` pega teste que não falha |
| `dev` | médio | `verify.sh` pega teste quebrado; é o primeiro papel a rebaixar |
| transcrição | leve | o brief já contém o código completo |
| orquestrador | médio | precisa de contexto longo e uso confiável de ferramentas; lê relatórios, não artefatos inteiros; suba para forte só se o `revisor` não for forte |

## Ajuste por dado
É o princípio 2 aplicado a modelo. A medição são as devoluções e rodadas registradas no `progress.md`.
- **Subir um nível:** o papel teve Crítico ou Importante em duas rodadas da mesma task, ou em duas tasks seguidas.
- **Descer um nível, como experimento:** o papel foi aprovado na primeira rodada em três tasks seguidas. Volte se a regra de subir disparar.
- **Antes de trocar o modelo, baixe o esforço de raciocínio,** quando o produto permitir. É o mesmo eixo, com troca mais barata.
- **Nunca rebaixe o `revisor` para economizar:** o custo migra para o orquestrador.
- Toda troca é decisão humana: registre-a como ajuste da decisão de composição do time, com o dado que a motivou.

## Orquestrador externo ou mais de um produto
Quando os papéis rodam em produtos diferentes (por exemplo, um canvas que orquestra várias CLIs de agente), o orquestrador propõe a composição do time no `/bootstrap` e sempre que o humano mudar os produtos disponíveis:
1. **Inventário.** Para cada produto: modelos e o nível de cada um; cota ou limite da licença; se permite negar escrita a um papel; se aplica `deny` e hooks como o adaptador do Claude Code. Marque cada item `confirmado` ou `inferido`.
2. **Nível.** Atribua pela tabela acima. Na falta do nível pedido, use o mais próximo acima no `arquiteto` e no `revisor`, e o mais próximo abaixo nos demais.
3. **Cota.** Estime os despachos por papel: por spec, `dominio`, `arquiteto` e `revisor` (`spec` e `design`); por task, `testes`, `dev` e `revisor` (`diff`), mais as devoluções. Ponha os papéis frequentes no produto com mais cota.
4. **Ferramentas.** O `revisor` vai para um produto que negue escrita; sem isso, "nunca corrige" fica por revisão, e a decisão diz isso. Os papéis que escrevem (`testes`, `dev`) vão de preferência para um produto que aplique `deny`; nos outros, só os githooks protegem, e a decisão também diz isso.
5. **Independência.** Com mais de uma família de modelos, prefira o `revisor` numa família diferente da do `dev`: o mesmo modelo tende a repetir o próprio erro. É preferência, não exigência.
6. **Proposta.** Apresente uma composição recomendada e uma alternativa mais barata, com o que cada uma sacrifica. O humano escolhe. Grave `D<n> — Composição do time` com a tabela papel | produto | modelo | nível | ferramentas, incluindo a linha do orquestrador: é por ela que as demais sessões sabem que não são o orquestrador.

**Verificado por:** revisão. Nenhum mecanismo confere qual modelo de fato rodou.
