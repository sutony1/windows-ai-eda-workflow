"use strict";

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const [sourceArg, outputArg] = process.argv.slice(2);
if (!sourceArg || !outputArg) throw new Error('Usage: node repair_ct_bottom_traces.js <source.epro> <output.epro>');
const sourceEpro = path.resolve(sourceArg);
const outputEpro = path.resolve(outputArg);
const converterRoot = process.env.LCEDA_CONVERTER_ROOT || 'C:\\Program Files\\lceda-pro-format-converter';
const sevenZip = path.join(converterRoot, 'resources', 'tools', '7z', 'x64', '7za.exe');
const workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ct-epro-repair-'));

const bottomSegmentsMm = [
  [132, 134.0517, 117, 119.0517], [117, 118, 117, 119.0517],
  [132, 139, 132, 134.0517], [107.356, 115, 116.4264, 124.0704],
  [106, 115, 107.356, 115], [120.3488, 119.0517, 122.0875, 120.7904],
  [119.54, 118, 119.54, 119.0517], [119.54, 119.0517, 120.3488, 119.0517],
];
const milPerMm = 39.37007874015748;

function run(args) {
  const result = spawnSync(sevenZip, args, { encoding: 'utf8', windowsHide: true });
  if (result.status !== 0) throw new Error(`${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
}

try {
  if (!fs.existsSync(sourceEpro)) throw new Error(`Missing EPRO: ${sourceEpro}`);
  if (!fs.existsSync(sevenZip)) throw new Error(`Missing 7-Zip helper: ${sevenZip}`);
  fs.mkdirSync(path.dirname(outputEpro), { recursive: true });
  run(['x', sourceEpro, '-y', `-o${workDir}`]);
  const pcbDir = path.join(workDir, 'PCB');
  const pcbFile = fs.readdirSync(pcbDir).find((name) => name.endsWith('.epcb'));
  if (!pcbFile) throw new Error('Converted EPRO contains no PCB document.');

  const pcbPath = path.join(pcbDir, pcbFile);
  const raw = fs.readFileSync(pcbPath, 'utf8');
  const existingLines = (raw.match(/^\["LINE"/gm) || []).length;
  if (existingLines !== 118) throw new Error(`Expected 118 converted F.Cu lines, got ${existingLines}.`);

  const bottomLines = bottomSegmentsMm.map(([x1, y1, x2, y2], index) => {
    const values = [x1, y1, x2, y2].map((value, pos) =>
      ((pos % 2 === 0 ? 1 : -1) * value * milPerMm).toFixed(5));
    return `["LINE","ie_bottom_${String(index + 1).padStart(2, '0')}",0,"",2,${values.join(',')},7.87402,0]`;
  });
  fs.writeFileSync(pcbPath, `${raw.trimEnd()}\n${bottomLines.join('\n')}\n`, 'utf8');

  const repaired = fs.readFileSync(pcbPath, 'utf8');
  const finalLines = (repaired.match(/^\["LINE"/gm) || []).length;
  const written = (repaired.match(/\["LINE","ie_bottom_\d+",0,"",2,/g) || []).length;
  if (finalLines !== 126 || written !== 8) throw new Error(`Repair count mismatch: lines=${finalLines}, bottom=${written}`);
  if (fs.existsSync(outputEpro)) fs.rmSync(outputEpro, { force: true });
  run(['a', '-tzip', '-mx=9', outputEpro, path.join(workDir, '*')]);
  run(['t', outputEpro]);
  console.log(JSON.stringify({ outputEpro, finalLines, bottomLinesWritten: written }, null, 2));
} finally {
  fs.rmSync(workDir, { recursive: true, force: true });
}
