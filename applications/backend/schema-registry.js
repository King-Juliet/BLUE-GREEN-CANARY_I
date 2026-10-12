// Loads the schema definitions from schemas.json (the single source of truth).
// To add a version, add an entry in schemas.json - nothing to change here.
const definitions = require('./schemas.json');

const schemaRegistry = {};

Object.keys(definitions).forEach((subject) => {
  const { compatibility, versions } = definitions[subject];
  schemaRegistry[subject] = {};

  Object.keys(versions).forEach((version) => {
    const { description, schema } = versions[version];
    schemaRegistry[subject][`v${version}`] = {
      subject,
      version: Number(version),
      fields: Object.keys(schema.properties),
      compatibility,
      description,
      schema
    };
  });
});

schemaRegistry.compatibilityPolicy = {
  strategy: 'write canonical fields, read flexible record shapes, ignore unknown fields',
  policy: 'READ_OLD_WRITE_NEW',
  note: 'Backend must tolerate schema drift with missing or extra columns.'
};

module.exports = schemaRegistry;




