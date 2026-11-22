# Prova do RED por caminho — Design

**Data:** 2026-11-21
**Status:** aprovado (2026-11-21; migração do §6.4 como escrita)
**Autor:** mantenedor do framework (decisões) · Claude (redação e análise)
**Origem:** dados da instância D (vault, notas de 21/11 "Custo do verify e memória" e "Comportamento de commits e paralelismo"), a análise de custo que a própria instância escreveu em 19/11 (itens A2, C e D, com patches e medição) e o histórico do repositório da instância, lido sem alteração.

## 1. Intenção

A prova do RED é o maior custo isolado da instância D, e ela está no modo degradado porque o kit não consegue expressar como provar um arquivo de teste num monorepo com vários executores. A instância contornou isso alterando o `verifica-red.sh` do kit, depois pausou o RED e, no fim do dia, tirou o kit de uma das branches de trabalho. O que se quer: o kit cobrir essa lacuna **sem código do projeto**, de modo que qualquer monorepo poliglota prove o RED arquivo por arquivo só com configuração.

## 2. Evidência

| Dado | Fonte |
|---|---|
| Cada RED novo leva de 30 a 40 min (suíte inteira, 21 suítes, 11 módulos Gradle); a rodada do revisor com o rápido leva de 7 a 13 min, e acima de 30 min o resto é espera pela prova | vault, nota de 21/11 sobre custo do verify e memória da instância D, §3 e §6 |
| `CMD_TESTE_ARQUIVO` vazio desde 15/11 porque o monorepo tem quatro executores (Gradle, node:test, pytest, Karma) e nenhum comando único que receba o caminho | comentário no `agentic/config` da instância |
| Executor por arquivo medido em REDs reais: node 0,4 s, pytest 4 s, Kotlin 254 s, contra cerca de 2.000 s do comando da suíte por RED | `refs/concluidos/agentic-custo.md` da instância |
| RED válido recusado: `frontend/src/…/*.component.spec.ts` classificado como produção (`DIRS_TESTE` só aceita prefixo) | análise de 19/11, item A2 |
| A instância alterou o kit para criar um marco (`RED_POR_ARQUIVO_DESDE`): trocar o comando invalidaria as 230 provas guardadas e poderia recusar REDs antigos | commits de 20/11 (PR de RED por arquivo) |
| O `verifica-red` descarta a saída do preparo e dos testes; o diagnóstico de um RED recusado não existe | `verifica-red.sh:322-334`; análise de 19/11, §2 |

## 3. Objetivos, não-objetivos e anti-objetivos

**Objetivos**
1. Um projeto com vários executores prova cada arquivo de teste do RED pelo executor certo, só com configuração.
2. O preparo do worktree do RED roda só para os executores que o RED toca.
3. Teste colocalizado (`*.spec.ts`, `*_test.go`, `*.test.ts` ao lado da produção) é reconhecido como teste sem marcar o diretório inteiro como teste.
4. Ligar a prova por arquivo num projeto em andamento não refaz nem recusa os REDs já provados.
5. RED recusado deixa a saída em log.
6. Opcionalmente, o executor separa "falhou um teste" de "nada rodou" (compilação, coleta, zero casos) pelo JUnit XML, sem script do projeto.

**Não-objetivos**
- Trava global da stack entre sessões, memória e processos órfãos (tema separado, já levantado).
- Rodadas de revisão, completo do revisor e do orquestrador (G já está na branch `verify-prova-e-log`).
- Itens E e H da análise da instância.
- Absorver o executor JavaScript da instância (212 linhas); o kit continua só em POSIX sh.

**Anti-objetivos** (falha mesmo que funcione)
- Aceitar RED falso: erro de compilação ou de coleta contado como RED quando o projeto pediu a distinção.
- Classificar produção como teste (o padrão amplo vira brecha para o RED tocar código).
- Mudar o comportamento de um projeto que não configurou nada novo: sem as chaves novas, a saída e as decisões do `verifica-red` são as de hoje.
- Exigir marco, data ou SHA do projeto para migrar.

## 4. Restrições

- POSIX sh, rodando também no Git Bash do Windows; nenhuma dependência nova nos scripts do kit.
- `agentic/config` é superfície de política (caminho protegido): a configuração nova mora nele, editada pelo humano.
- Nada de nome de projeto no repositório; as instâncias aparecem por letra.
- Coerência do kit: toda regra nova descrita nos dois lados (script e `ciclo.md`/`README`/entrevista) e conferida pelo `coerencia-kit`.
- A prova continua isolada (worktree temporário no commit RED) e guardada em `<git-common-dir>/agentic/red-provados`.

## 5. Abordagens consideradas

| | Abordagem | Ganho | Custo | Decisão |
|---|---|---|---|---|
| **A** | Executores por caminho declarados no `agentic/config`: cada um diz que arquivos são dele, como preparar e como provar | cobre C, D e A2 com uma só declaração; nenhum código do projeto | mudança maior no `verifica-red.sh`, no `verifica-skip.sh` e nos testes | **escolhida** |
| B | Um comando só, com contrato do wrapper documentado e um wrapper de exemplo | mudança pequena | cada monorepo escreve o próprio roteador: a personalização que se quer evitar | descartada |
| C | Degradado por módulo (suíte do módulo tocado) | simples | resolve pela metade (um módulo pesado sozinho leva de 230 a 460 s); A cobre o caso com um executor por módulo | descartada |

Escolha do mantenedor em 2026-11-21: A, com migração das provas, contrato do código de saída, ajuda de JUnit e log.

## 6. Desenho

### 6.1 Executores no `agentic/config`

Blocos numerados, lidos pelo `lib-agentic.sh` como o resto da configuração (sem formato novo nem parser):

```sh
# Executor 1: módulo Kotlin "bridge"
TESTE_1_PADROES="backend/bridge/src/test/*.kt"
TESTE_1_PREPARO=""
TESTE_1_COMANDO="cd backend && ./gradlew :bridge:test --tests {classe}"
TESTE_1_RC_RED=""
# Executor 2: Angular, teste colocalizado
TESTE_2_PADROES="frontend/src/*.spec.ts"
TESTE_2_PREPARO="npm ci --ignore-scripts --prefix frontend"
TESTE_2_COMANDO="cd frontend && npx ng test --include={}"
```

- `TESTE_<n>_PADROES`: padrões separados por espaço, casados com `case` do sh (o `*` cruza `/`). Obrigatório para o bloco existir. A leitura para no primeiro `n` sem `PADROES`.
- `TESTE_<n>_COMANDO`: roda na raiz do worktree do RED. `{}` é o caminho do arquivo e `{classe}` o nome qualificado JVM (linha `package` do arquivo + nome sem extensão; arquivo sem `package` dá só o nome), os dois entre aspas simples como hoje.
- `TESTE_<n>_PREPARO`: opcional, roda uma vez por worktree para cada preparo distinto entre os executores tocados.
- `TESTE_<n>_RC_RED`: opcional. Vazio mantém a regra de hoje (qualquer código fora de 0, 126 e 127 conta como RED). Preenchido, só esse código é RED, e outro código diferente de zero bloqueia como "não é evidência".

O primeiro bloco cujo padrão casa com o arquivo é o executor dele. Um executor por módulo é a forma de cobrir build multi-módulo sem roteador.

### 6.2 O que é arquivo de teste

Uma função `agentic_e_teste <arquivo>` no `lib-agentic.sh`: o arquivo é teste se casa um prefixo de `DIRS_TESTE` **ou** um padrão de algum `TESTE_<n>_PADROES`. Ela substitui os laços de prefixo em `verifica-red.sh` (recusa de produção no RED, lista de arquivos do RED e checagem de GREEN sem RED) e em `verifica-skip.sh` (varredura do marcador de teste desabilitado, que passa a filtrar o diff por arquivo em vez de usar `DIRS_TESTE` como pathspec). `docs/` e `agentic/projeto/` continuam isentos.

### 6.3 Escolha do caminho de prova, por RED

Para cada arquivo de teste com asserção tocado pelo RED:
1. tem executor → prova pelo `TESTE_<n>_COMANDO`;
2. não tem e `CMD_TESTE_ARQUIVO` está preenchido → prova por ele (comportamento de hoje);
3. nenhum dos dois → o RED cai na suíte inteira (`CMD_TESTE`), **uma vez por RED**, com o aviso `degradado: <arquivo> sem executor — RED provado pela suíte inteira`.

O preparo do worktree passa a ser a união dos `TESTE_<n>_PREPARO` dos executores usados, mais o `CMD_PREPARAR_TESTE` quando há prova por `CMD_TESTE_ARQUIVO` ou pela suíte. Sem nenhum bloco `TESTE_<n>`, o preparo é o `CMD_PREPARAR_TESTE`, como hoje.

### 6.4 Cache e migração

- A assinatura da prova por executor é o hash do `PADROES`, `PREPARO`, `COMANDO` e `RC_RED` **daquele** executor: acrescentar ou mudar um executor não invalida as provas dos outros.
- As provas por `CMD_TESTE_ARQUIVO` e pela suíte mantêm a assinatura de hoje.
- **Migração:** um RED com prova `*suite*` guardada, de qualquer assinatura, conta como provado e imprime `RED <sha>: provado antes pela suíte (assinatura anterior) (ok)`. Assim, ligar os executores num projeto em andamento não refaz os REDs antigos nem os submete à régua nova. `AGENTIC_RED_SEM_CACHE=1` refaz tudo.
- A recusa de produção, a contagem de asserções e o vínculo CA → teste rodam sempre, como hoje.

### 6.5 Log

A saída do preparo e de cada execução vai para `agentic/.estado/verifica-red.log` (reescrito a cada execução do script), com cabeçalho `== RED <sha> <arquivo|suite> (<executor>)` e a duração em segundos. Em bloqueio, as últimas 40 linhas daquela execução são repetidas na saída, como no `verify.sh`. O `verifica-escopo.sh` ignora o arquivo.

### 6.6 Ajuda `red-junit.sh`

`sh agentic/mecanismos/scripts/red-junit.sh '<glob dos XML>' -- <comando>` roda o comando, lê os JUnit XML que ele gerou e sai com:
- `1` (RED): pelo menos um `<testcase>` e pelo menos um `<failure>`;
- `0`: casos rodaram e nenhum falhou;
- `126`: nenhum XML, zero casos, ou só `<error>` (compilação, coleta, fixture).

Usada com `TESTE_<n>_RC_RED="1"`, ela separa "o teste falhou" de "nada rodou" para Gradle, Maven, pytest, node:test e Karma com reporter JUnit. O worktree do RED é novo a cada prova, então não há XML antigo. Limite declarado: no JUnit, exceção lançada no corpo do teste também é `<failure>`; asserção contra exceção continua sendo dever do `testes` (papel) e do revisor.

### 6.7 Prova do completo (branch `verify-prova-e-log`)

A assinatura da prova do completo no `verify.sh` passa a incluir todas as chaves `TESTE_<n>_*`.

### 6.8 Documentação e instalação

- `bootstrap/config.padrao`: bloco comentado de exemplo, com um executor de arquivo e um por módulo.
- `bootstrap/entrevista.md`: a pergunta do `CMD_TESTE_ARQUIVO` passa a perguntar por executor (padrões, preparo, comando) quando há mais de um.
- `core/processo/ciclo.md` ("Verificação"), `README.md` e o comentário de topo do `verifica-red.sh`: o caminho de prova, a migração e o log.
- `coerencia-kit`: confere que as chaves descritas na documentação são as lidas pelo `lib-agentic.sh`.

## 7. Critério de pronto

1. Um projeto sem as chaves novas passa nos testes existentes do `verifica-red` e do `verifica-skip` sem mudança neles: mesmas decisões (aceito, bloqueado, degradado), mesmos códigos e mesmas linhas de resultado. O que muda é só o acréscimo: o log e, no bloqueio, o trecho repetido.
2. Testes novos (RED/GREEN), cada um com seu fixture:
   - roteamento: dois executores, cada arquivo pelo seu;
   - fallback: arquivo sem executor cai na suíte uma vez, com aviso;
   - preparo: só o dos executores tocados, sem repetir;
   - `RC_RED`: o código certo é RED, outro bloqueia;
   - colocalizado: `x.spec.ts` aceito, `x.component.ts` recusado como produção;
   - migração: prova `*suite*` antiga aceita após ligar executores; `AGENTIC_RED_SEM_CACHE=1` refaz;
   - assinatura por executor: mudar o executor 2 não refaz prova do 1;
   - log: escrito, e as 40 linhas repetidas no bloqueio;
   - `red-junit.sh`: XML com failure (1), sem failure (0), sem XML, zero casos e só error (126);
   - `verify.sh`: mudar uma chave `TESTE_<n>_*` invalida a prova do completo.
3. Na instância D, configurada só com blocos `TESTE_<n>`, um RED de Kotlin é provado em minutos (referência: 254 s medidos pelo executor da instância), sem prova refeita para os REDs já guardados. É a medição de validação depois do merge, não um teste do kit.

## 8. Calls do redator (para o mantenedor conferir)

- Configuração por blocos numerados no `agentic/config`, e não arquivo separado: uma só superfície de política, já protegida e já lida pelo `lib-agentic.sh`.
- `{classe}` entra no kit porque Java, Kotlin, Scala e Groovy precisam dele e a derivação é a mesma (`package` + nome do arquivo). Módulo do build não vira placeholder: um executor por módulo resolve sem regra nova.
- `RC_RED` por executor, e não global: a ajuda `red-junit` vale para uns executores e não para outros.
- O log é reescrito a cada execução, como o `verify.log`.

## 9. Deixado ao construtor

- Nome e forma exatos das funções no `lib-agentic.sh`, desde que `agentic_e_teste` seja a única regra de classificação.
- Como `red-junit.sh` lê o XML em sh (contagem de `<testcase`, `<failure`, `<error`, como o `verifica-skip` já faz com relatórios).
- Divisão em commits e ordem dos testes.
