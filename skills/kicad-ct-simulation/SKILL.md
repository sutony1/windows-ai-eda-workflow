---
name: kicad-ct-simulation
description: Design, simulate, calibrate, and document KiCad 9 current-transformer voltage conditioners and other low-voltage BJT/precision-rectifier measurement circuits. Use when a task involves ngspice, a CT secondary or AC sensor, 0–300 mV-scale inputs, calibrated AC-to-DC conversion, the mixelpixx KiCad MCP, or creating and validating a visible KiCad 9 schematic.
---

# KiCad CT simulation

Produce a reproducible ngspice design plus a KiCad 9-visible schematic. Treat simulation and manufacture-ready circuitry separately when a behavioral block is used.

## 1. Prepare the machine

Read [references/kicad9-mcp-setup.md](references/kicad9-mcp-setup.md) before installing or repairing the MCP on a new machine. Read [references/ngspice-install.md](references/ngspice-install.md) before installing or upgrading the simulator.

Confirm these before designing:

- KiCad 9 opens and **Enable KiCad API** is selected.
- Node.js is 18 or newer; use KiCad's bundled Python for `pcbnew` and `kicad-python`.
- `ngspice` is on `PATH`.
- Restart Codex after adding an MCP configuration, then begin a new task.
- Test live IPC by reading the running KiCad version or MCP `get_backend_state`; require `backend: ipc` and `ipcConnected: true` for realtime work.

Do not assume `kicad-cli` is on `PATH` on Windows. Use `<KiCad>\\bin\\kicad-cli.exe` when needed.

## 2. Turn electrical requirements into a testable transfer function

State whether input millivolts are RMS, peak, or peak-to-peak. For a 50 Hz sine with a requested `0–300 mVrms → 0–3 Vdc`, use the target transfer:

`Vout_dc = 10.00 × Vin_rms`

Use a BC547B or comparable small-signal NPN as a biased, emitter-degenerated buffer when the source can tolerate the bias network. Make its bias point explicit and model the actual transistor rather than an unnamed `NPN`.

Do not claim that a diode-only or BJT-only rectifier is linear at low voltage. Its junction threshold makes the low end unusable. For near-zero linearity on a 3.7 V rail, add a low-offset RRIO precision rectifier / RMS-to-DC stage. A behavioral RMS model is acceptable for early simulation, but label it clearly and replace it with an actual op-amp or RMS-converter circuit before fabrication.

## 3. Simulate and iterate

Create two netlists:

1. A single full-scale transient netlist with documented supply, source impedance, BJT model, bias, and output filter.
2. A reset-per-point calibration sweep over zero and the requested input range.

For a behavioral RMS stage, model `K × sqrt(LPF((Vsignal - Voffset)^2))`. Set the low-pass cutoff well below 50 Hz (10 Hz is a practical starting point) and calibrate `K` plus the BJT DC offset after observing the simulation.

For every iteration:

- Run a 0-input point; remove offset before accepting linearity.
- Sweep at least 0%, 17%, 33%, 50%, 67%, 83%, and 100% of full scale.
- Report the numeric table, not only a plot.
- Check output headroom against the 3.7 V rail and choose realistic source impedance.
- Preserve the sweep netlist and the raw ngspice log alongside the project.

Reject a design that matches only full scale but has a large zero offset or obvious low-end nonlinearity.

## 4. Create and validate the KiCad schematic

Create a project directory containing the netlists, log, KiCad schematic, and a short design note. Place and label at minimum: input connector, input coupling/burden interface, NPN bias network, active precision-rectifier/RMS block, output filter, output connector, VCC, and GND.

Write the calibrated transfer function and the behavioral-model caveat as visible schematic notes. Do not silently represent an ideal behavioral source as a manufacturer-qualified physical circuit.

Validate the generated schematic by exporting it with KiCad 9:

```powershell
& '<KiCad>\bin\kicad-cli.exe' sch export svg --black-and-white '<schematic>'
```

If mixelpixx MCP emits a KiCad 10 schematic (`version 20260101` or `generator_version "10.0"`) while the target machine has KiCad 9, do not claim it is compatible. Generate a KiCad legacy `.sch` interchange file, open it in Eeschema 9, and save the converted `.kicad_sch`; then rerun the export test.

## 5. Hand off

Deliver links to the full-scale netlist, sweep netlist, raw log, KiCad schematic, exported preview, and design note. State the calibration assumption, actual simulated sweep result, supply limit, and any remaining hardware validation required.
