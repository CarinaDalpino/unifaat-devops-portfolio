// test-problems.js - Arquivo para testar o AI Review
// TODO: remover este arquivo após o teste

// CRITICAL: secret hardcoded
const apiKey = 'sk-1234567890abcdef';
const dbPassword = 'super_secret_123';

// CRITICAL: SQL injection (concatenação de string)
function getUser(userId) {
  const query = 'SELECT * FROM users WHERE id = ' + userId;
  return db.query(query);
}

// WARNING: console.log em produção
function processOrder(order) {
  console.log('Processing order:', order);
  return order;
}

// WARNING: catch vazio
try {
  dangerousOperation();
} catch (e) {}

// CRITICAL: eval com input
function evaluate(userInput) {
  return eval(userInput);
}

module.exports = { getUser, processOrder, evaluate, apiKey, dbPassword };
