# EasyEDA conversion forensics

These scripts preserve the source code used while diagnosing KiCad-to-EasyEDA conversion problems in the CT RMS-to-DC project.

They are not the preferred manufacturing route. The conversion assistant's internal worker and `.epro` line format are undocumented implementation details and may change without notice. Always keep KiCad authoritative and compare net count, component count, layer/track count, drills, and outline after running them.

## Scripts

- `run_lceda_conversion.js`: invokes the locally installed format converter worker with explicit input files.
- `repair_ct_bottom_traces.js`: restores the eight B.Cu segments that the validated converter omitted from this specific board.
- `hide_imported_metadata.js`: hides imported `Description` and `User doc link` attributes without deleting connectivity.

Set `LCEDA_CONVERTER_ROOT` if the converter is not installed at `C:\Program Files\lceda-pro-format-converter`.

```powershell
node .\run_lceda_conversion.js import .\converted ct_amp_rectifier_5v_clean `
  .\ct_amp_rectifier_5v_clean.kicad_pro `
  .\ct_amp_rectifier_5v_clean.kicad_sch `
  .\ct_amp_rectifier_5v_clean.kicad_pcb

node .\repair_ct_bottom_traces.js .\converted\ct_amp_rectifier_5v_clean.epro .\repaired.epro
node .\hide_imported_metadata.js .\repaired.epro .\visual-clean.epro
```

Each script fails closed on missing files or unexpected track counts. Do not upload a repaired `.epro` to production until it has been compared against KiCad and passed an independent Gerber review.
