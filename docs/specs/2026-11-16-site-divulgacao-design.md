# Site de divulgação do kit — design

**Data:** 2026-11-16 · **Status:** aguardando aprovação do dono

## 1. Intenção

Uma página pública no GitHub Pages que apresenta o kit à **comunidade de desenvolvedores**, em tom profissional, e que funcione como link compartilhado no LinkedIn. Ela explica **o que o kit resolve** e **por que o repositório é como é**, sustentando cada escolha com números medidos em execuções reais.

Sucesso: um desenvolvedor que chega pelo LinkedIn entende em 30 segundos o problema e a proposta, vê que cada afirmação tem dado e fonte conferível, e segue para o repositório.

## 2. Objetivos, não-objetivos, anti-objetivos

- **Objetivos:** problema → como funciona → números → por que o kit é assim → o que aprendemos medindo → como começar. Card Open Graph para o LinkedIn. Funciona no celular.
- **Não-objetivos:** documentar o kit (isso fica no README e em `core/`); blog; outros idiomas (só pt-BR nesta versão); analytics.
- **Anti-objetivos (é fracasso mesmo que funcione):**
  - número sem fonte pública, ou que contradiga o repositório;
  - nome de projeto de origem, de cliente ou de empresa, em qualquer arquivo, commit ou PR; e modelo ou fornecedor associado a um projeto;
  - tom de marketing ("revolucionário", "10x"): a página promete só o que um mecanismo garante, como o README;
  - esconder os números desfavoráveis (55% de devolução): eles aparecem com a causa e a correção.

## 3. Restrições

- Repositório público. Publicação por GitHub Actions a partir de `site/` na `main`, sem branch `gh-pages`.
- Sem build, sem `package.json`, sem `node_modules`: HTML e CSS, com JS mínimo (só a alternância de tema). Recurso externo só fontes do Google Fonts.
- Coerência com o kit: as afirmações sobre mecanismos usam a mesma redação do README, e cada número aponta para `docs/evidencias.md`.
- Projetos identificados só por código e descrição neutra:
  - **A**: sistema de gestão em Java/Spring, onde o kit nasceu;
  - **B**: servidor MCP em Python;
  - **C**: projeto Java maduro;
  - **D**: a maior instância, com uma série de 20 tasks.

## 4. Abordagens consideradas

| | Abordagem | Trade-off | Decisão |
|---|---|---|---|
| 1 | HTML e CSS estáticos em `site/`, publicados por Actions | escrito à mão; zero dependência; passa pelo mesmo PR e pelo mesmo verify do kit | **escolhida pelo dono** |
| 2 | Astro / Vite | componentes e ferramentas modernas; traz node e build a um kit que é só `sh` e Markdown | descartada |
| 3 | Jekyll servindo `docs/` | nativo do Pages; publicaria specs e planos junto; visual moderno mais difícil | descartada |
| — | Branch `gh-pages` órfã | a `main` fica só com o kit; a página fica fora do verify e do PR, e a coerência passa a ser conferida à mão | descartada pelo dono |

## 5. Conteúdo, na ordem das seções

1. **Hero.** Proposta de título: "Agentes de IA que seguem um processo de engenharia — e um kit que diz *não* quando eles saem dele." Subtítulo: 5 papéis, 2 gates humanos, mecanismos determinísticos, qualquer stack. Chamada para o repositório.
2. **Faixa de números**, com 4 destaques:
   - 705 despachos de agentes em 36 execuções;
   - 4 projetos reais, em Java e Python;
   - 227 achados bloqueantes classificados por causa;
   - cerca de 80% menos documentação na trilha enxuta.
3. **O problema.** Cartões no formato "Sem o kit, o agente…", cada um com o mecanismo que garante a proteção. É a tabela do README, reduzida a 6 a 9 itens.
4. **Como funciona.** O fluxo Especificar → Gate 1 → RED → GREEN → Revisão → Gate 2; os 5 papéis, com o que cada um faz e nunca faz; as 3 trilhas.
5. **Por que o repositório é assim.** Cada cartão liga uma decisão do kit à evidência que a motivou:
   - revisor em contexto limpo e "Menor não abre rodada" ← 528 achados Menores contra 260 Críticos e Importantes;
   - `## Impacto` no design e no brief ← 58% dos achados de design vinham de impacto não levantado, e 61% nasceram da correção anterior;
   - brief estruturado com "leia só isto" e teto declarado ← 80% menos cache lido (25,8M → 5,3M);
   - regra colada no brief, não só no contrato ← modelo barato não segue regra que está só no link;
   - trilha enxuta ← 309 linhas de documento para uma faixa de desconto, contra 58 na trilha enxuta;
   - `verifica-red` por arquivo e isenção de `docs/` ← 32 de 40 commits RED também editavam o documento da task.
6. **O que aprendemos medindo.** A parte honesta da página:
   - 55% das revisões foram devolvidas;
   - 57% das revisões acontecem antes do código;
   - a revisão não devolve por forma: exigência sem base e forma somam menos de 5%;
   - o gargalo muda com a instância (em B, o revisor; em A, o `testes`);
   - gráfico de barras com as causas dos 227 achados: 32% defeito real, 33% contrato ignorado, 30% afirmação sem conferir, 3,5% exigência sem base, 1% forma.
7. **Comece.** O `/bootstrap` em 3 passos, com links para o README e para `docs/validacao-v1.md`.
8. **Rodapé.** Licença MIT, link para o repositório e a data de corte dos dados.

## 6. Arquivos

- `docs/evidencias.md` (novo): o resumo público das medições, cada número com método, amostra e data, sempre com os códigos A a D. É a fonte que a página cita.
- `LICENSE` (novo): MIT, titular "Paulo Ricardo Calazans", ano 2026. O README ganha uma seção "Licença".
- `site/index.html`, `site/estilo.css`, `site/og.png` (1200×630) e `site/favicon.svg`.
- `.github/workflows/pages.yml`: roda em push na `main` que toque `site/**`, com `actions/upload-pages-artifact` seguido de `actions/deploy-pages`. Depende de o dono habilitar no GitHub a opção Pages → Source: GitHub Actions.
- Protótipo: um arquivo `.pen` novo no pen.dev, sem tocar em nenhum `.pen` de outro projeto.
- `scripts/coerencia-kit.Tests.sh` ganha três tipos de checagem:
  - as frases de mecanismo que a página repete do README existem nos dois lados;
  - cada número da página existe em `docs/evidencias.md`;
  - nenhum nome de projeto de origem aparece em `site/` nem em `docs/evidencias.md`.

## 7. Decidido pelo dono

- Público: comunidade de desenvolvedores, em tom profissional, com uso no LinkedIn.
- `site/` na `main`, publicado por Actions.
- Protótipo no pen.dev, em arquivo novo, **aprovado pelo dono antes do HTML**.
- Fonte dos números: `docs/evidencias.md` publicado e anonimizado (opção 1a).
- Licença MIT, titular Paulo Ricardo Calazans.
- Nenhuma referência a projeto de origem no repositório, nem no histórico.

## 8. Chamadas minhas (corrija se quiser)

- Projetos só pelos códigos A a D, com descrição neutra e sem modelos por projeto.
- Só pt-BR.
- Tema escuro por padrão com alternância para o claro, porque o público é de desenvolvedores. Tipografia Inter e JetBrains Mono.
- Cada número traz a data de corte ("dados até 2026-11-15") e um link para a seção correspondente de `docs/evidencias.md`.
- Os números ficam escritos direto no HTML, sem `dados.json`: uma fonte só, sem cópia para sincronizar.
- O `og.png` é exportado do pen.dev e não leva números, para não envelhecer quando os dados mudarem.

## 9. Fica com quem constrói

Paleta, ilustrações, microcopy dos cartões e tamanho dos gráficos.
