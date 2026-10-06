# Respostas pré-gravadas do bootstrap

- Contexto: CLI de conversão de unidades (comprimento, temperatura) para uso pessoal; domínio simples; projeto novo; sem restrições regulatórias nem legado.
- Stack: Python 3 sem dependências externas; testes com unittest da biblioteca padrão.
- Comandos: instalar = (nenhum); build = `python -m compileall -q src`; lint = (nenhum); testes = `python -m unittest discover -s tests -q`; arquitetura = (nenhum).
- CMD_VERIFY_STACK = `python -m compileall -q src && python -m unittest discover -s tests -q`
- CMD_TESTE = `python -m unittest discover -s tests -q`
- Teste desabilitado: `@unittest\.skip|skipTest\(`. Relatório JUnit: não há (verificação degradada, aceito). Asserção: `assert[A-Z][A-Za-z]*\(`.
- Estrutura: pacote `src/conversor/`, testes em `tests/`. Sem ferramenta de fronteiras.
- Risco: nenhum caminho protegido além dos do framework; nenhum gatilho N3 adicional.
- Fontes externas: nenhuma.
- Operação: branch principal `main`; sem plataforma de PR (integração local com `git merge --ff-only`); sem CI; Gate 1 e Gate 2 aprovados pelo mantenedor; modo automático desligado.
