// Cálculo de preço final com desconto por faixa de quantidade.
function precoFinal(precoUnitario, quantidade) {
  const bruto = precoUnitario * quantidade;
  const desconto = quantidade >= 100 ? 0.1 : quantidade >= 10 ? 0.05 : 0;
  return Math.round(bruto * (1 - desconto) * 100) / 100;
}

module.exports = { precoFinal };
