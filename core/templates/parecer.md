<!-- Template de parecer do revisor. O revisor preenche e apaga este comentário.
- Onde: no caminho que o brief dá, agentic/.estado/execucao/<AAAA-MM-DD>-<nome>/NN-revisor-<modo>-parecer.md, fora do
  worktree revisado. O parecer é local (agentic/.estado/ não é versionado); o PR leva o veredito e os achados menores.
  Sem plataforma de PR, o orquestrador copia o parecer final aprovado para agentic/projeto/specs/<nome>/pareceres/<NNN>-diff.md (NNN = número da task).
- Escala do kit: Crítico e Importante bloqueiam; Menor fica registrado para a revisão final da branch.
- Toda evidência é `medido` (você abriu ou rodou) ou `inferido` (dedução). Aprovar sem abrir as citações e rodar a
  verificação não vale.
-->
# Parecer — <modo: spec | design | mudanca | diff> — <task ou artefato> — rodada <k>

**Veredito:** <APROVADO | DEVOLVIDO> · C <n> I <n> M <n>
**Revisado:** <intervalo de SHAs base..HEAD (modo diff) | caminho do artefato>
**Parecer anterior:** <caminho, na rodada de confirmação | não há>

## Rodada anterior
<só na confirmação; senão: não se aplica>

| Achado anterior | Situação | Evidência no HEAD |
|---|---|---|
| <ID> | <corrigido \| não corrigido \| parcial> | <arquivo:linha> |

## Critérios de aceite
<no modo diff; nos modos spec, design e mudanca: não se aplica>

| CA | Teste | Status |
|---|---|---|
| <CA-n> | <arquivo:linha do teste> | <coberto \| não coberto> (<medido \| inferido>) |

## Achados
<ou: nenhum>

| ID | Classe | Onde | Problema | Evidência |
|---|---|---|---|---|
| <C1 \| I1 \| M1> | <Crítico \| Importante \| Menor> | <arquivo:linha> | <o que está errado e o que outro papel deve fazer> | <medido \| inferido>: <o que você viu> |

## Verificação
```
<comando rodado, em primeiro plano (no modo diff, sh agentic/mecanismos/scripts/verify.sh)>
<últimas linhas da saída>
```
