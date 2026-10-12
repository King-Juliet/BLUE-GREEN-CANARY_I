// CI check: every schema version must be compatible with the earlier one(s),
// according to the compatibility type declared for that subject in schemas.json.
// Pure file comparison - needs no AWS access and no dependencies.
const definitions = require('../schemas.json');

const errors = [];

// Can a reader using `reader` safely read data written with `writer`?
function readerCanReadWriter(reader, writer) {
  const problems = [];
  const readerRequired = reader.required || [];
  const writerProps = writer.properties || {};
  const readerProps = reader.properties || {};

  readerRequired.forEach((field) => {
    if (!(field in writerProps)) {
      problems.push(`required field "${field}" is missing from the data it must read`);
    } else if (!(writer.required || []).includes(field)) {
      problems.push(`field "${field}" is required by the reader but optional in the data`);
    }
  });

  Object.keys(readerProps).forEach((field) => {
    if (field in writerProps && readerProps[field].type !== writerProps[field].type) {
      problems.push(`field "${field}" changed type (${writerProps[field].type} -> ${readerProps[field].type})`);
    }
  });

  return problems;
}

Object.keys(definitions).forEach((subject) => {
  const { compatibility, versions } = definitions[subject];
  const numbers = Object.keys(versions).map(Number).sort((a, b) => a - b);

  numbers.forEach((n, i) => {
    if (n !== i + 1) {
      errors.push(`${subject}: versions must be 1,2,3... with no gaps (found ${numbers.join(', ')})`);
    }
  });

  if (compatibility === 'NONE') return;

  const transitive = compatibility.endsWith('_TRANSITIVE');
  const mode = compatibility.replace('_TRANSITIVE', '');
  if (!['BACKWARD', 'FORWARD', 'FULL'].includes(mode)) {
    errors.push(`${subject}: unknown compatibility "${compatibility}"`);
    return;
  }

  numbers.forEach((n, i) => {
    if (i === 0) return;
    const newer = versions[n].schema;
    const earlier = transitive ? numbers.slice(0, i) : [numbers[i - 1]];

    earlier.forEach((o) => {
      const older = versions[o].schema;
      const problems = [];

      // BACKWARD: new schema must be able to read data written with the old one.
      if (mode === 'BACKWARD' || mode === 'FULL') {
        readerCanReadWriter(newer, older).forEach((p) => problems.push(p));
      }
      // FORWARD: old schema must be able to read data written with the new one.
      if (mode === 'FORWARD' || mode === 'FULL') {
        readerCanReadWriter(older, newer).forEach((p) => problems.push(p));
      }

      problems.forEach((p) => errors.push(`${subject} v${o} -> v${n} breaks ${compatibility}: ${p}`));
    });
  });
});

if (errors.length > 0) {
  console.error('Schema compatibility check FAILED:');
  errors.forEach((e) => console.error(`  - ${e}`));
  process.exit(1);
}

console.log('Schema compatibility check passed.');