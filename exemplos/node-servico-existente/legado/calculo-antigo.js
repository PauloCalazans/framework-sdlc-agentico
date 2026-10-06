// Implementação antiga, ainda usada por relatórios. Arredonda para baixo (comportamento herdado).
function precoAntigo(precoUnitario, quantidade) {
  const desconto = quantidade > 100 ? 0.1 : 0;
  return Math.floor(precoUnitario * quantidade * (1 - desconto));
}

module.exports = { precoAntigo };
