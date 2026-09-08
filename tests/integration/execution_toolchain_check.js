const fs = require("node:fs");

if (process.version !== "v26.3.1") {
  throw new Error(`expected Node.js v26.3.1, got ${process.version}`);
}

fs.writeFileSync(process.argv[2], `${process.version}\n`);
