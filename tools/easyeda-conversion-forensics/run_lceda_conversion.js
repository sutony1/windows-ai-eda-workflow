"use strict";

const { fork } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const [direction, outputArg, title, ...inputs] = process.argv.slice(2);
if (!['import', 'export'].includes(direction) || !outputArg || !title || inputs.length === 0) {
  throw new Error('Usage: node run_lceda_conversion.js <import|export> <output-dir> <title> <input...>');
}
if ((direction === 'import' && inputs.length !== 3) || (direction === 'export' && inputs.length !== 1)) {
  throw new Error('Import expects .kicad_pro, .kicad_sch and .kicad_pcb; export expects one .epro.');
}

const converterRoot = process.env.LCEDA_CONVERTER_ROOT || 'C:\\Program Files\\lceda-pro-format-converter';
const outputDir = path.resolve(outputArg);
const sourceFiles = inputs.map((file) => path.resolve(file));
for (const file of sourceFiles) {
  if (!fs.existsSync(file)) throw new Error(`Missing source: ${file}`);
}
fs.mkdirSync(outputDir, { recursive: true });

const worker = path.join(converterRoot, 'resources', 'app', 'js', 'eda-worker.min.js');
const sevenZip = path.join(converterRoot, 'resources', 'tools', '7z', 'x64', '7za.exe');
const localeDir = path.join(converterRoot, 'resources', 'app', 'locale');
for (const file of [worker, sevenZip, path.join(localeDir, 'lang-env.json')]) {
  if (!fs.existsSync(file)) throw new Error(`Converter component missing: ${file}`);
}
const languageENV = JSON.parse(fs.readFileSync(path.join(localeDir, 'lang-env.json'), 'utf8'));
const child = fork(worker, [], { stdio: ['ignore', 'pipe', 'pipe', 'ipc'] });
let finished = false;

function finish(code, detail) {
  if (finished) return;
  finished = true;
  if (detail) console.log(detail);
  if (child.connected) child.disconnect();
  // The bundled worker keeps its event loop alive after reporting `end`.
  // Terminate only after it has produced the final status so this wrapper
  // returns a reliable exit code instead of hanging indefinitely.
  if (!child.killed) child.kill('SIGTERM');
  process.exitCode = code;
}

child.stdout.on('data', (data) => process.stdout.write(`[worker] ${data}`));
child.stderr.on('data', (data) => process.stderr.write(`[worker] ${data}`));
child.on('error', (error) => finish(1, `Worker error: ${error.message}`));
child.on('exit', (code, signal) => {
  if (!finished && code !== 0 && signal !== 'SIGTERM') finish(1, `Worker exited: code=${code}, signal=${signal}`);
});
child.on('message', (message) => {
  console.log(JSON.stringify(message));
  if (message?.op === 'convertReady' && message?.data?.state === 'fail') finish(1, 'Conversion failed.');
  else if (message?.op === 'convertReady' && message?.data?.end) finish(0, 'Conversion worker finished.');
});

child.send({
  op: 'runConvert',
  options: {
    outputDir,
    eda: 'kicad',
    op: direction,
    rows: [{ asciiOK: true }],
    infoForChamelon: { rows: [{ filetype: 'prj', title, rowIndex: 0, files: sourceFiles }] },
    sevenZip,
    i18nConfig: { language: 'zh-hans', defaultLanguage: 'zh-hans', languageENV, localeDir },
  },
});

setTimeout(() => finish(1, 'Conversion timed out.'), 10 * 60 * 1000).unref();
