# Respostas pré-gravadas do bootstrap

- Contexto: serviço interno de cálculo de preços usado pelo time comercial; projeto existente; há uma implementação legada em `legado/` ainda usada por relatórios, com regra de desconto diferente.
- Stack: Node.js ≥ 20, CommonJS, sem dependências externas; testes com `node:test`.
- Comandos: instalar = (nenhum); build = (nenhum); lint = (nenhum); testes = `npm test`; arquitetura = (nenhum).
- CMD_VERIFY_STACK = `mkdir -p relatorio && npm test`
- CMD_TESTE = `node --test`
- Teste desabilitado: `\.skip\(|\{ *skip *:|test\.todo\(`. Relatório JUnit: `relatorio/*.xml`. Asserção: `assert\.`.
- Estrutura: código em `src/`, legado em `legado/` (não deve ser alterado sem decisão), testes em `test/`.
- Risco: caminho protegido `legado/`; gatilho N3 adicional: qualquer mudança em regra de desconto.
- Fontes externas: oráculo `legado-precos` sobre `legado/calculo-antigo.js` (leitura do arquivo no próprio repositório).
- Operação: branch principal `main`; sem plataforma de PR (integração local); sem CI; Gates aprovados pelo mantenedor; modo automático desligado.
