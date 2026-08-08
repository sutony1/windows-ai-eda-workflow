"use strict";

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const [sourceArg, outputArg] = process.argv.slice(2);
if (!sourceArg || !outputArg) throw new Error('Usage: node hide_imported_metadata.js <source.epro> <output.epro>');
const sourceEpro = path.resolve(sourceArg);
const outputEpro = path.resolve(outputArg);
const converterRoot = process.env.LCEDA_CONVERTER_ROOT || 'C:\\Program Files\\lceda-pro-format-converter';
const sevenZip = path.join(converterRoot, 'resources', 'tools', '7z', 'x64', '7za.exe');
const workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'epro-metadata-'));

function run(args) {
  const result = spawnSync(sevenZip, args, { encoding: 'utf8', windowsHide: true });
  if (result.status !== 0) throw new Error(`${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
}

try {
  if (!fs.existsSync(sourceEpro)) throw new Error(`Missing EPRO: ${sourceEpro}`);
  if (!fs.existsSync(sevenZip)) throw new Error(`Missing 7-Zip helper: ${sevenZip}`);
  fs.mkdirSync(path.dirname(outputEpro), { recursive: true });
  run(['x', sourceEpro, '-y', `-o${workDir}`]);
  const sheetRoot = path.join(workDir, 'SHEET');
  if (!fs.existsSync(sheetRoot)) throw new Error('EPRO contains no SHEET directory.');
  let hidden = 0;

  for (const dir of fs.readdirSync(sheetRoot, { withFileTypes: true }).filter((item) => item.isDirectory())) {
    for (const name of fs.readdirSync(path.join(sheetRoot, dir.name))) {
      if (!name.endsWith('.esch')) continue;
      const file = path.join(sheetRoot, dir.name, name);
      const updated = fs.readFileSync(file, 'utf8').split(/\r?\n/).map((line) => {
        if (!line.startsWith('["ATTR",')) return line;
        const record = JSON.parse(line);
        if ((record[3] === 'Description' || record[3] === 'User doc link') && record[6] === true) {
          record[6] = false;
          hidden += 1;
        }
        return JSON.stringify(record);
      });
      fs.writeFileSync(file, updated.join('\r\n'), 'utf8');
    }
  }
  if (hidden === 0) throw new Error('No visible imported metadata fields were found; refusing a no-op rewrite.');
  if (fs.existsSync(outputEpro)) fs.rmSync(outputEpro, { force: true });
  run(['a', '-tzip', '-mx=9', outputEpro, path.join(workDir, '*')]);
  run(['t', outputEpro]);
  console.log(JSON.stringify({ sourceEpro, outputEpro, hidden }, null, 2));
} finally {
  fs.rmSync(workDir, { recursive: true, force: true });
}
