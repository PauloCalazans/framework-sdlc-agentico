const { test } = require("node:test");
const assert = require("node:assert/strict");
const { precoFinal } = require("../src/precos");

test("sem desconto abaixo de 10 unidades", () => {
  assert.equal(precoFinal(2.5, 4), 10);
});

test("5% a partir de 10 unidades", () => {
  assert.equal(precoFinal(10, 10), 95);
});

test("10% a partir de 100 unidades", () => {
  assert.equal(precoFinal(1, 100), 90);
});
