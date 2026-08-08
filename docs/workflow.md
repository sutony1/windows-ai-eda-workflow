# End-to-end design workflow

## Source hierarchy

1. Simulator decks and measured results establish circuit intent.
2. The KiCad project is the authoritative schematic, netlist, footprints, and PCB.
3. Gerbers exported from checked KiCad sources are the authoritative bare-board manufacturing files.
4. EasyEDA imports are downstream copies until their connectivity and component mapping are proven.

## Design gates

### Simulation

- Define supply, waveform, source impedance, burden, load, and required settling time.
- Sweep zero, low, mid, and full-scale input; include tolerance and temperature where models allow.
- Use ngspice for automation-friendly smoke tests and LTspice for the Analog Devices LTC1967 macro model.
- Store decks, simulator versions, model provenance, and numeric results.

### KiCad schematic

- Draw a readable left-to-right signal chain with real symbols and explicit power pins.
- Confirm pin numbers against datasheets before selecting footprints.
- Run ERC to zero errors. Document any intentional warning exception.
- Export or inspect a netlist; touching graphics do not prove connectivity.

### PCB

- Assign real footprints and check connector polarity and IC orientation.
- Place decoupling at IC supply pins and keep the RMS converter/input nodes short and quiet.
- Route all nets, add copper zones where appropriate, refill zones, and require zero unconnected pads.
- Run DRC to zero errors. Visually inspect both copper layers, silkscreen, mask, drills, and outline.

### Manufacturing

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\windows-ai-eda-workflow\scripts\Export-JlcpcbGerbers.ps1 `
  -BoardPath .\examples\ct-rms-to-dc\kicad\ct_amp_rectifier_5v_clean.kicad_pcb
```

Open the generated ZIP in a Gerber viewer before upload. Never submit or pay for an order without explicit authorization.

### Bench verification

- Use a generator or calibrated source and scope/DMM to compare AC input against DC output.
- Automate the sweep with the included PyVISA example when a compatible RIGOL scope is available.
- Record gain, offset, linearity, ripple, settling time, and calibration control position.
