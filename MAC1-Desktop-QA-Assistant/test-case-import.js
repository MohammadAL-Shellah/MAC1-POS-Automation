'use strict';

const MAX_CASES = 100;
const CASE_HEADING = /^####\s+(TC-[A-Z0-9-]+)\s+—\s+(.+?)\s*$/i;

// Only a top-level field ends the previous one; indented "  - **Items:** ..." lines belong to it.
const ANY_FIELD = /^-\s*\*\*[^*]+:\*\*/;

// A field may continue on the following lines (for example an Expected written as a bullet list).
// It ends at the next field, a heading, or a blank line followed by a non-list line.
function extractField(lines, name) {
  const prefix = new RegExp(`^-\\s*\\*\\*${name}:\\*\\*\\s*(.*)$`, 'i');
  const start = lines.findIndex((candidate) => prefix.test(candidate));
  if (start === -1) return null;
  const parts = [lines[start].match(prefix)[1].trim()];
  for (let index = start + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (ANY_FIELD.test(line) || /^\s*#/.test(line)) break;
    if (!line.trim()) {
      const next = lines.slice(index + 1).find((candidate) => candidate.trim());
      if (!next || !/^\s+[-*]\s|^\s+\d+\.\s/.test(next)) break;
      continue;
    }
    parts.push(line.trim());
  }
  return parts.filter(Boolean).join(' ').trim();
}

function splitNumberedSteps(value) {
  const steps = [];
  const marker = /(?:^|\s)(\d+)\.\s+/g;
  let match;
  let previousIndex = 0;
  let foundMarker = false;
  while ((match = marker.exec(value)) !== null) {
    if (foundMarker) {
      steps.push(value.slice(previousIndex, match.index).trim());
    }
    foundMarker = true;
    previousIndex = marker.lastIndex;
  }
  if (!foundMarker) return value.trim() ? [value.trim()] : [];
  steps.push(value.slice(previousIndex).trim());
  return steps;
}

function parseMarkdownTestCases(markdown) {
  if (typeof markdown !== 'string' || !markdown.trim()) {
    throw new Error('The Markdown file is empty.');
  }

  const lines = markdown.replace(/^\uFEFF/, '').split(/\r?\n/);
  const cases = [];
  let current = null;
  const finishCase = () => {
    if (!current) return;
    const category = extractField(current.lines, 'Category');
    const preconditions = extractField(current.lines, 'Preconditions/data');
    const stepsText = extractField(current.lines, 'Steps');
    const expected = extractField(current.lines, 'Expected');
    if (!category || !preconditions || !stepsText || !expected) {
      throw new Error(`${current.id} must include Category, Preconditions/data, Steps, and Expected fields.`);
    }
    const steps = splitNumberedSteps(stepsText);
    if (!steps.length || steps.some((step) => !step)) {
      throw new Error(`${current.id} must include at least one non-empty numbered step.`);
    }
    cases.push({
      id: current.id,
      title: current.title,
      category,
      preconditions,
      manualSteps: steps,
      expected,
    });
  };

  for (const line of lines) {
    const heading = line.match(CASE_HEADING);
    if (heading) {
      finishCase();
      current = { id: heading[1], title: heading[2], lines: [] };
    } else if (current) {
      current.lines.push(line);
    }
  }
  finishCase();

  if (!cases.length) {
    throw new Error('No test cases were found. Use headings like "#### TC-01 — Test title".');
  }
  if (cases.length > MAX_CASES) {
    throw new Error(`The Markdown file contains ${cases.length} cases; the maximum supported is ${MAX_CASES}.`);
  }

  const ids = new Set();
  for (const testCase of cases) {
    if (ids.has(testCase.id)) throw new Error(`Duplicate test case ID: ${testCase.id}.`);
    ids.add(testCase.id);
  }
  return cases;
}

module.exports = { parseMarkdownTestCases };
