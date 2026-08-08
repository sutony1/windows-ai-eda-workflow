---
name: kicad-ct-rms-pcb
description: "Design and verify a 5 V current-transformer RMS-to-DC conditioner in KiCad 10: ngspice/LTspice simulation, LTC1967 calibration, clean schematic, footprints, PCB placement/routing, and ERC/DRC closure. Use for CT or 50/60 Hz AC sensors in the 0–300 mVrms range, KiCad MCP work, or when converting an existing CT design into a manufacturable KiCad project."
---

# KiCad CT RMS-to-DC PCB

## Purpose

Use this workflow to turn a low-level CT secondary voltage into a calibrated DC
measurement output, then deliver a real KiCad 10 schematic and PCB.  It is
based on a 5 V, 0–300 mVrms at 50 Hz reference design using an LTC1967 true-RMS
converter, BC547B input buffer, and OPA333 output stage.

Read [references/workflow.md](references/workflow.md) before selecting values,
changing the topology, or operating FreeRouting.  It records the proven values,
simulation table, tool versions, and recovery procedures.

## Required outcome

Before declaring the design complete, provide all of the following:

1. A simulation deck and a sweep table covering zero, mid-scale, and full-scale.
2. A KiCad project (`.kicad_pro`, `.kicad_sch`, `.kicad_pcb`) that opens in the
   target KiCad version.
3. A connected schematic whose generated netlist matches the intended pins.
4. PCB footprints, outline, placement, routing, and saved DRC report.
5. ERC and DRC with **zero errors**.  Explain and resolve warnings where possible.

Never claim that visual adjacency proves electrical connection: inspect the
generated netlist and run ERC/DRC.

## Workflow

### 1. Establish scope and input assumptions

- Record supply voltage, AC input range/frequency, sensor source impedance and
  burden resistor, ADC/load impedance, target DC range, accuracy, and required
  isolation/creepage.
- For the reference case, use `5 V`, `0–300 mVrms`, `50 Hz`, `0–3 V DC`.
  The nominal transfer target is `10 V/V`.
- Treat the CT/burden as part of the calibration.  A different burden resistor
  or source impedance changes the transfer function.
- Keep mains wiring out of this low-voltage board unless the insulation,
  clearance, surge, and safety design are separately engineered.

### 2. Validate tools and model provenance

- Confirm KiCad 10 can open a small project, and confirm the KiCad MCP is live
  before driving the GUI.  Use a single authoritative board editor session.
- Use the vendor macro model for the LTC1967 when available.  Document its
  origin and exact simulator version; do not silently substitute an ideal RMS
  block for final calibration.
- Prefer an actual KiCad library symbol/footprint for real components.  If a
  library item is missing, add a clear procurement and footprint note.

### 3. Simulate before drawing PCB

- Centre the AC signal at the LTC1967 input bias/reference required by its model.
  Run transient long enough for its averaging capacitor to settle.
- Sweep at least 0, 50, 100, 150, 200, 250, and 300 mVrms.  Measure the average
  output after filtering and compute gain, full-scale error, and zero residual.
- Adjust gain with a stable resistor plus a multi-turn trim, not an arbitrary
  virtual gain.  Use 0.1% fixed gain-setting resistors where accuracy matters.
- Record the trim position needed at full scale and retain margin for component
  tolerance.  Calibrate final zero/span in firmware or production test when
  the RMS converter leaves a residual at zero.

### 4. Draw and electrically prove the schematic

- Use separate named nets for input, buffer, bias, RMS, feedback, output, 5 V,
  and ground.  Use labels at every intended remote connection.
- Implement any trim resistor as a real three-terminal potentiometer/rheostat:
  fixed resistor, correct end terminals, and wiper tied to the required end.
  Do not depict a two-pin fixed resistor as if it were adjustable.
- Assign all required power pins and decoupling capacitors.  Add input/output
  connectors and realistic load/ADC interface notes.
- Generate a netlist and inspect it for expected pins on every named net.  Then
  run ERC.  If a wire looks connected but the netlist is wrong, delete/re-place
  the label/wire snapped to the actual symbol pin grid and repeat.

### 5. Select physical footprints before PCB creation

- Assign manufacturable footprints, orientation constraints, and connector
  entry directions in the schematic first.
- Create the PCB from the schematic only after footprints are assigned.  Check
  the board contains every reference and has no duplicate/obsolete footprints.

### 6. PCB layout and routing

- Define board outline, mounting holes, layer stack, clearance, trace/via rules,
  and connector keep-out needs before placement.
- Place input and output connectors apart; keep the high-impedance/bias/RMS
  area compact and away from output/load routing.  Put each decoupler close to
  its IC supply pins.  Check courtyard overlap and edge clearance after moving.
- Route critical analog traces deliberately.  After each routing batch run DRC;
  delete temporary crossing traces rather than routing around a known short.
- For FreeRouting, begin with **no copper zones** unless the installed router and
  importer are verified to preserve them.  Export only after clearing old traces
  and vias, route all targeted nets, import, then prove every target net has
  tracks and DRC remains clean.  Add ground copper only afterward, followed by
  a fresh DRC.

### 7. Final handoff

- Save the project and a dated ERC/DRC report in the project folder.
- Open the final board in KiCad and visually review connector orientation,
  silkscreen, outline, mounting holes, and unconnected markers.
- Supply BOM/procurement substitutions, trim calibration instructions, measured
  simulation results, and remaining warning rationale.

## Common recovery rules

- KiCad editor and SWIG/file-based MCP access can conflict.  After an external
  `.kicad_pcb` edit, reopen the board through the MCP before any further action.
- Do not alternate GUI edits with file-based board modifications without saving
  and reopening; KiCad timestamp protection may otherwise reject the change.
- A current FreeRouting release may not match the MCP command-line integration.
  Run a small routing trial and confirm an SES file is imported before relying
  on a new JAR version.  Keep the validated JAR version documented.
- Do not let warnings mask real electrical errors.  Library/courtyard/silk
  warnings can be triaged only after shorts, clearance, crossing, and
  unconnected-item errors are zero.
