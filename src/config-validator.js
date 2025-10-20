// Copilot: Implement validateConfig() that:
// - Reads a JSON config file.
// - Checks required fields: name, version, scripts.
// - Logs errors for missing fields.
// - Exits process with code 1 on validation failure.
function validateConfig(filePath) {
  const fs = require('fs');
  let config;
  try {
    config = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  } catch (e) {
    console.error(`Invalid JSON in ${filePath}:`, e.message);
    process.exit(1);
  }
  const required = ['name','version','scripts'];
  let ok = true;
  required.forEach(field => {
    if (!(field in config)) {
      console.error(`Missing required field: ${field}`);
      ok = false;
    }
  });
  if (!ok) process.exit(1);
  console.log('Config validation passed.');
}
module.exports = { validateConfig };