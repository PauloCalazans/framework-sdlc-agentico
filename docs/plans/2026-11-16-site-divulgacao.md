# Site de divulgação — plano de implementação

> **Para agentes:** use superpowers:subagent-driven-development ou superpowers:executing-plans, task a task. Os passos usam checkbox (`- [ ]`).

**Objetivo:** publicar no GitHub Pages uma página estática que mostra o que o kit resolve e por que ele é como é, com cada número ligado a `docs/evidencias.md`.

**Arquitetura:**
- `LICENSE` e `docs/evidencias.md` vêm primeiro, porque são as fontes que a página cita.
- O protótipo no pen.dev passa pela aprovação do dono antes do HTML.
- `site/` tem HTML e CSS sem build e é publicado por um workflow do Actions.
- `scripts/coerencia-kit.Tests.sh` amarra página, README e evidências.

**Stack:** HTML5, CSS (custom properties e grid), JS de uma função só (tema), POSIX `sh` para os testes, GitHub Actions (`actions/configure-pages@v5`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4`), pen.dev via MCP `pencil`.

**Spec:** `docs/specs/2026-11-16-site-divulgacao-design.md`

## Restrições globais

- Nenhum nome de projeto de origem, cliente ou empresa em arquivo, commit ou PR. Projetos só como **A**, **B**, **C** e **D**, com as descrições da seção 3 da spec. Antes de cada commit, rode `grep -rniE` contra a lista local (Task 1).
- Sem `package.json`, sem build, sem dependência nova. Recurso externo só do Google Fonts (Inter, JetBrains Mono).
- Só pt-BR. Tom sem marketing: a página promete só o que um mecanismo garante.
- Data de corte dos dados: **2026-11-15**.
- Licença MIT, `Copyright (c) 2026 Paulo Ricardo Calazans`.
- Siga a memória "fetch antes do PR": `git fetch`, integrar `origin/main` e `sh scripts/verify.sh` → `verify: OK` antes de push. O verify completo leva mais de 10 min: rode com `run_in_background`.

## Foco da revisão

1. **Nome proibido dentro da própria checagem.** O teste não pode conter os nomes que proíbe. A lista fica num arquivo local, fora do git (Task 1).
2. **Número da página sem par em `evidencias.md`**, por exemplo depois de alguém editar a cópia. O teste confere cada `data-e` (Task 4).
3. **Link de âncora quebrado** entre a página e `evidencias.md`. O teste confere que cada `data-e="eN"` tem `<a id="eN"></a>` (Task 4).
4. **Celular a 360px com rolagem horizontal.** Confira a captura de tela em 360px (Task 4).
5. **Workflow publicando a raiz em vez de `site/`.** O teste confere `path: site` (Task 5).

---

### Task 1: Licença e checagem de nomes proibidos

**Arquivos:**
- Criar: `LICENSE`
- Modificar: `README.md` (seção `## Licença` no fim), `.gitignore` (linha `.nomes-proibidos`), `scripts/coerencia-kit.Tests.sh` (bloco novo antes de `tl_fim`)
- Criar, sem versionar: `.nomes-proibidos`, com uma ERE por linha, com os nomes que o dono informar (eles nunca entram no git).

**Interfaces:**
- Produz: a função `sem_nomes_proibidos <caminhos...>` em `coerencia-kit.Tests.sh`. Ela lê `$raiz/.nomes-proibidos` e retorna 0 quando nenhum caminho casa. Sem o arquivo, imprime `aviso: .nomes-proibidos ausente — nomes não conferidos` e retorna 0.

- [ ] **Passo 1: testes que falham.** Acrescente ao `coerencia-kit.Tests.sh`:
  ```sh
  # --- Site de divulgação (docs/specs/2026-11-16-site-divulgacao-design.md)
  tl_espera 0 "LICENSE: MIT" tem LICENSE 'MIT License'
  tl_espera 0 "LICENSE: titular" tem LICENSE 'Copyright (c) 2026 Paulo Ricardo Calazans'
  tl_espera 0 "README: seção Licença" linha README.md '^## Licença$'
  tl_espera 0 "sem nome de projeto de origem" sem_nomes_proibidos README.md LICENSE docs core adapters bootstrap mecanismos scripts
  ```
- [ ] **Passo 2:** `sh scripts/coerencia-kit.Tests.sh` → os 3 primeiros FALHAM.
- [ ] **Passo 3:** escreva `sem_nomes_proibidos`, junto de `nenhum()`. Para cada linha não vazia de `.nomes-proibidos`, chame `nenhum "<ere>" "$@"`. Inclua `.nomes-proibidos` no `.gitignore`, crie `LICENSE` com o texto MIT padrão e acrescente ao README `## Licença` + `MIT — ver [LICENSE](LICENSE).`
- [ ] **Passo 4:** `sh scripts/coerencia-kit.Tests.sh` → `0 falhas`. Depois, `git status --short` não pode listar `.nomes-proibidos`.
- [ ] **Passo 5: commit** `feat(kit): licença MIT e checagem local de nomes proibidos`

### Task 2: `docs/evidencias.md`

**Arquivos:**
- Criar: `docs/evidencias.md`
- Modificar: `scripts/coerencia-kit.Tests.sh`, `README.md` (linha final "Validação:" passa a citar também `docs/evidencias.md`)

**Interfaces:**
- Produz âncoras `<a id="eN"></a>` antes de cada seção. Cada seção traz **método, amostra, data e números**. Os valores são exatamente estes, que a Task 4 cita:

| Âncora | Título | Números exatos |
|---|---|---|
| `e1` | Projetos e amostra | A: sistema de gestão Java/Spring, onde o kit nasceu, 31 execuções; B: servidor MCP Python, 5 execuções; C: projeto Java maduro, kit desde 2026-11-06, sem execuções registradas; D: maior instância, série de 20 tasks. Total: **36 execuções, 705 despachos** |
| `e2` | Onde a revisão acontece | **57%** das revisões são de artefato, antes do código (107 de 187); design: 62 revisões, diff: 78 |
| `e3` | Devolução | **55%** devolvidas (A 60%, B 49%); revisor:dev 1,33 (A 1,08, B 1,96); gargalo: B revisor (37% dos despachos), A testes (35%) |
| `e4` | Causas dos achados bloqueantes | **227** achados Crítico/Importante de 157 pareceres: defeito real 72 (**32%**), contrato ignorado 76 (**33%**), afirmação sem conferir 69 (**30%**), exigência sem base 8 (**3,5%**), só forma 2 (**1%**) |
| `e5` | Volume por severidade | **528** Menores contra **260** Crítico + Importante |
| `e6` | Anatomia de duas cascatas de design | 31 achados; **58%** impacto não levantado; **61%** nasceram da correção anterior; 0 de forma; cascatas de 10 rodadas (A) e 17 revisões de design (B) |
| `e7` | Custo de contexto do brief | testes sem modelo de brief **25,8M** de cache lido → com modelo **5,3M** (**−80%**); regra só no contrato linkado não é seguida por modelo barato |
| `e8` | Trilha enxuta | padrão: **309** linhas em 4 arquivos; enxuta: **58** linhas, documento único (~**80%** menos), com RED, revisor e os dois gates |
| `e9` | RED e documentação | **32 de 40** commits RED também editavam o documento da task |
| `e10` | Custo do verify (D) | prova do RED **10,5 min → 6 s** com cache por SHA; verify inteiro em toda chamada estimado em **~20 h** numa série de 20 tasks |

Fontes no repositório, para citar no fim de cada seção quando houver: `docs/validacao-v1.md` (e8, e9), `docs/specs/2026-11-14-revisao-convergente-design.md` (e4), `docs/specs/2026-11-06-brief-e-parecer-design.md` (e7). Fecha com `## Limites`: amostra pequena (B: 5 execuções); classificação em primeira passada; parte das devoluções pode ser efeito de medição.

- [ ] **Passo 1: testes que falham.**
  ```sh
  e=docs/evidencias.md
  for a in e1 e2 e3 e4 e5 e6 e7 e8 e9 e10; do
    tl_espera 0 "evidências: âncora $a" tem $e "<a id=\"$a\"></a>"
  done
  tl_espera 0 "evidências: seção Limites" linha $e '^## Limites$'
  tl_espera 0 "evidências: data de corte" tem $e '2026-11-15'
  tl_espera 0 "evidências sem nome de projeto de origem" sem_nomes_proibidos $e
  ```
- [ ] **Passo 2:** rode a suíte → FALHA.
- [ ] **Passo 3:** escreva `docs/evidencias.md` com a tabela acima, em prosa curta por seção e só com os códigos A a D.
- [ ] **Passo 4:** rode a suíte → `0 falhas`.
- [ ] **Passo 5: commit** `docs(evidencias): medições públicas que sustentam o kit`

### Task 3: protótipo no pen.dev (com aprovação do dono)

**Arquivos:**
- Criar: `design/site-divulgacao.pen`. Arquivo **novo**: não abra nem edite nenhum `.pen` de outro projeto.

**Interfaces:**
- Consome: as seções 5 e 8 da spec e os números da Task 2.
- Produz:
  - um frame `Desktop · 1440`;
  - um frame `Mobile · 360`;
  - um frame `OG · 1200x630`, sem números;
  - tokens de cor para o tema escuro e o claro, que a Task 4 copia como custom properties.

- [ ] **Passo 1:** `mcp__pencil__get_app_state`. Leia as instruções da ferramenta `execute` e o `read_skill` relevante. Crie o arquivo novo em `design/`.
- [ ] **Passo 2:** desenhe os 8 blocos da spec, na ordem da seção 5. Cada número aparece com a legenda e a referência `eN`.
- [ ] **Passo 3:** tire capturas dos três frames e mostre ao dono. **PARE até o dono aprovar.** Ajustes pedidos voltam ao Passo 2.
- [ ] **Passo 4:** exporte o frame OG como `site/og.png`; se não houver export, use a captura em 1200×630. **Commit** `docs(design): protótipo do site de divulgação`

### Task 4: a página

**Arquivos:**
- Criar: `site/index.html`, `site/estilo.css`, `site/favicon.svg`, `site/og.png` (da Task 3)
- Modificar: `scripts/coerencia-kit.Tests.sh`

**Interfaces:**
- Consome:
  - as âncoras `e1`…`e10` da Task 2;
  - os tokens da Task 3.
- Produz:
  - cada número exibido como `<strong class="num" data-e="eN">VALOR</strong>`, seguido de um link para `https://github.com/PauloCalazans/framework-sdlc-agentico/blob/main/docs/evidencias.md#eN`;
  - as frases de mecanismo copiadas do README literalmente, dentro de `<p class="mecanismo">`;
  - nas metas, `og:title`, `og:description`, `og:image` com URL absoluta para `og.png` e `twitter:card=summary_large_image`.
- Conteúdo:
  - o da seção 5 da spec;
  - mais o cartão "prova do RED em cache por SHA ← 10,5 min → 6 s (e10)" na seção "Por que o repositório é assim";
  - rodapé com "MIT", link do repositório e "Dados até 2026-11-15".
- Tema: escuro por padrão. O botão alterna `data-theme` em `<html>` e grava a escolha em `localStorage`, dentro de `try/catch`. Sem JS, a página funciona no tema escuro.

- [ ] **Passo 1: testes que falham.**
  ```sh
  s=site/index.html
  tl_espera 0 "site: página existe" tem $s '<html lang="pt-BR"'
  tl_espera 0 "site: og:image" tem $s 'property="og:image"'
  tl_espera 0 "site: data de corte" tem $s '2026-11-15'
  tl_espera 0 "site: licença no rodapé" tem $s 'MIT'
  tl_espera 0 "site sem nome de projeto de origem" sem_nomes_proibidos site
  sem_package() { ! [ -e "$raiz/package.json" ]; }
  tl_espera 0 "site: sem build (sem package.json)" sem_package
  # cada número tem par na seção citada e âncora existente
  site_nums_ok() {
    tr -d '\r' < "$raiz/$s" | grep -o 'data-e="e[0-9]*">[^<]*<' | sed 's/data-e="\(e[0-9]*\)">\([^<]*\)</\1 \2/' |
    while read -r a v; do
      tem docs/evidencias.md "<a id=\"$a\"></a>" || { echo "sem âncora $a"; return 1; }
      tem docs/evidencias.md "$v" || { echo "valor sem par: $a $v"; return 1; }
    done
  }
  tl_espera 0 "site: todo número tem par em evidencias.md" site_nums_ok
  # cada frase de mecanismo existe no README
  site_mec_ok() {
    tr -d '\r' < "$raiz/$s" | grep -o '<p class="mecanismo">[^<]*</p>' | sed 's/<[^>]*>//g' |
    while IFS= read -r f; do tem README.md "$f" || { echo "frase fora do README: $f"; return 1; }; done
  }
  tl_espera 0 "site: frases de mecanismo iguais ao README" site_mec_ok
  ```
- [ ] **Passo 2:** rode a suíte → FALHA.
- [ ] **Passo 3:** escreva `index.html` e `estilo.css` a partir do protótipo aprovado. Use HTML semântico (`header`, `main`, `section` com `id`, `footer`), contraste AA nos dois temas e um layout sem rolagem horizontal a 360px.
- [ ] **Passo 4:** rode a suíte → `0 falhas`. Abra `site/index.html` no navegador e capture a tela a 1440px e a 360px, nos dois temas. Mostre as capturas ao dono.
- [ ] **Passo 5: commit** `feat(site): página de divulgação do kit`

### Task 5: publicação por Actions e PR

**Arquivos:**
- Criar: `.github/workflows/pages.yml`
- Modificar: `scripts/coerencia-kit.Tests.sh`, `README.md` (link do site perto do topo)

**Interfaces:**
- Workflow `pages`:
  - roda em `push` na `main` que toque `paths: ['site/**']` e também em `workflow_dispatch`;
  - permissões: `pages: write`, `id-token: write`, `contents: read`;
  - concorrência: grupo `pages`;
  - passos: `checkout@v4` → `configure-pages@v5` → `upload-pages-artifact@v3` com `path: site` → `deploy-pages@v4`, no ambiente `github-pages`.
- URL publicada: `https://paulocalazans.github.io/framework-sdlc-agentico/`.

- [ ] **Passo 1: testes que falham.**
  ```sh
  w=.github/workflows/pages.yml
  tl_espera 0 "pages: publica só site/" linha $w 'path: *site$'
  tl_espera 0 "pages: deploy oficial" tem $w 'actions/deploy-pages@v4'
  tl_espera 0 "README: link do site" tem README.md 'paulocalazans.github.io/framework-sdlc-agentico'
  ```
- [ ] **Passo 2:** rode a suíte → FALHA.
- [ ] **Passo 3:** escreva o workflow e acrescente ao README, abaixo do parágrafo de abertura, `**Site:** https://paulocalazans.github.io/framework-sdlc-agentico/`.
- [ ] **Passo 4:**
  - `git fetch`, depois integre `origin/main`;
  - rode `sh scripts/verify.sh` em segundo plano → `verify: OK`;
  - confira a lista local de nomes no repositório e nas mensagens de commit: `git log origin/main..HEAD --format=%B | grep -i -f .nomes-proibidos` não pode retornar nada.
- [ ] **Passo 5: commit** `ci(pages): publica site/ no GitHub Pages`. Faça o push e abra o PR (trilha rápida, docs/ferramental), sem nenhum nome proibido no texto.
- [ ] **Passo 6:** peça ao dono que ative Settings → Pages → Source: **GitHub Actions** e faça o merge. Depois do merge, rode `gh run list --workflow pages` → `completed success` e abra a URL.
