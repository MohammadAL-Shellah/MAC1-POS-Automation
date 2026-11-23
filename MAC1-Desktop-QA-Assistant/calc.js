'use strict';

// Number reading and safe arithmetic for test plans. Expressions are parsed here (no eval):
// numbers, {variables}, + - * / ( ), and the functions round, abs, min, max.

const VARIABLE_NAME = /^[A-Za-z][A-Za-z0-9_]{0,40}$/;
const COMPARE_OPS = new Set(['=', '!=', '<', '<=', '>', '>=']);

// "17,725.11", "−51.00", "2.3%", "All (365)", "+2266.5% vs yesterday", "Qty 51" -> number or null.
function parseNumber(text) {
  const match = String(text ?? '').replace(/−/g, '-').match(/[+-]?\d[\d,]*(?:\.\d+)?|[+-]?\.\d+/);
  if (!match) return null;
  const value = Number(match[0].replace(/,/g, ''));
  return Number.isFinite(value) ? value : null;
}

function tokenize(expression) {
  const tokens = [];
  const source = String(expression);
  let index = 0;
  while (index < source.length) {
    const rest = source.slice(index);
    const space = rest.match(/^\s+/);
    if (space) { index += space[0].length; continue; }
    const number = rest.match(/^\d+(?:\.\d+)?|^\.\d+/);
    if (number) { tokens.push({ type: 'num', value: Number(number[0]) }); index += number[0].length; continue; }
    const variable = rest.match(/^\{([A-Za-z][A-Za-z0-9_]{0,40})\}/);
    if (variable) { tokens.push({ type: 'var', name: variable[1] }); index += variable[0].length; continue; }
    const name = rest.match(/^[a-z]+/);
    if (name) { tokens.push({ type: 'fn', name: name[0] }); index += name[0].length; continue; }
    if ('+-*/(),'.includes(rest[0])) { tokens.push({ type: rest[0] }); index += 1; continue; }
    throw new Error(`Unsupported character "${rest[0]}" in expression "${source}".`);
  }
  return tokens;
}

const FUNCTIONS = {
  round: (value, digits = 0) => {
    const factor = 10 ** digits;
    return Math.round((value + Number.EPSILON) * factor) / factor;
  },
  abs: (value) => Math.abs(value),
  min: (...values) => Math.min(...values),
  max: (...values) => Math.max(...values),
};

// Grammar: expr = term (('+'|'-') term)*; term = factor (('*'|'/') factor)*;
// factor = ('+'|'-') factor | number | {var} | fn '(' expr (',' expr)* ')' | '(' expr ')'
function evaluateExpression(expression, variables = {}) {
  const tokens = tokenize(expression);
  let position = 0;
  const peek = () => tokens[position];
  const take = (type) => {
    const token = tokens[position];
    if (!token || (type && token.type !== type)) {
      throw new Error(`Invalid expression "${expression}".`);
    }
    position += 1;
    return token;
  };
  const factor = () => {
    const token = peek();
    if (!token) throw new Error(`Invalid expression "${expression}".`);
    if (token.type === '-' || token.type === '+') {
      take();
      const value = factor();
      return token.type === '-' ? -value : value;
    }
    if (token.type === 'num') return take().value;
    if (token.type === 'var') {
      take();
      const entry = variables[token.name];
      if (entry === undefined) throw new Error(`Value {${token.name}} was not read before this check.`);
      const value = typeof entry === 'object' && entry !== null ? entry.value : entry;
      if (typeof value !== 'number' || !Number.isFinite(value)) {
        throw new Error(`Value {${token.name}} is not a number (read "${entry?.text ?? entry}").`);
      }
      return value;
    }
    if (token.type === 'fn') {
      const fn = FUNCTIONS[take().name];
      if (!fn) throw new Error(`Unknown function "${token.name}" in "${expression}".`);
      take('(');
      const args = [expr()];
      while (peek()?.type === ',') { take(','); args.push(expr()); }
      take(')');
      return fn(...args);
    }
    if (token.type === '(') {
      take('(');
      const value = expr();
      take(')');
      return value;
    }
    throw new Error(`Invalid expression "${expression}".`);
  };
  const term = () => {
    let value = factor();
    while (peek()?.type === '*' || peek()?.type === '/') {
      const operator = take().type;
      const right = factor();
      if (operator === '/' && right === 0) throw new Error(`Division by zero in "${expression}".`);
      value = operator === '*' ? value * right : value / right;
    }
    return value;
  };
  const expr = () => {
    let value = term();
    while (peek()?.type === '+' || peek()?.type === '-') {
      value = take().type === '+' ? value + term() : value - term();
    }
    return value;
  };
  const result = expr();
  if (position !== tokens.length) throw new Error(`Invalid expression "${expression}".`);
  return result;
}

function expressionVariables(expression) {
  return [...String(expression).matchAll(/\{([A-Za-z][A-Za-z0-9_]{0,40})\}/g)].map((match) => match[1]);
}

function compareNumbers(left, op, right, tolerance = 0.01) {
  const close = Math.abs(left - right) <= tolerance + 1e-9;
  switch (op) {
    case '=': return close;
    case '!=': return !close;
    case '<': return left < right - tolerance;
    case '<=': return left <= right + tolerance;
    case '>': return left > right + tolerance;
    case '>=': return left >= right - tolerance;
    default: throw new Error(`Unsupported comparison "${op}".`);
  }
}

function formatNumber(value) {
  return Number.isInteger(value) ? String(value) : String(Math.round(value * 10_000) / 10_000);
}

module.exports = {
  COMPARE_OPS,
  VARIABLE_NAME,
  compareNumbers,
  evaluateExpression,
  expressionVariables,
  formatNumber,
  parseNumber,
};
