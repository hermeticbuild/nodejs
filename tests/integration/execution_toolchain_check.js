const fs = require("node:fs");

if (process.version !== "v26.13.0") {
  throw new Error(`expected Node.js v26.13.0, got ${process.version}`);
}

fs.writeFileSync(process.argv[2], `${process.version}\n`);
