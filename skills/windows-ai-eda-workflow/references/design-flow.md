# Simulation to KiCad manufacturing flow

## 1. Capture requirements

Record supply, waveform, frequency, amplitude range, source/burden impedance, output target, load/ADC impedance, accuracy, isolation, environment and safety requirements.

## 2. Simulate

Use ngspice for portable smoke tests and LTspice for the Analog Devices LTC1967 macro model. Sweep zero, intermediate points and full scale. Run long enough for averaging capacitors to settle, then measure only the stable tail.

Keep behavioural or ideal models clearly labeled. Do not use an ideal RMS block as final calibration evidence.

## 3. Draw the KiCad schematic

Use real symbols and footprints. Snap every wire and net label to the actual pin grid. Model three-terminal trims as three-terminal parts with the intended wiper connection. Add connectors, power pins, decoupling, test points and calibration notes.

Generate and inspect the netlist, then run ERC. A clean-looking drawing is insufficient.

## 4. Build the PCB

Create the board from the checked schematic. Define board outline, mounting holes, stackup, rules and connector directions first. Keep analog input, bias and RMS nodes compact; separate input and output; place decouplers beside IC supply pins.

Run DRC after every routing batch. If using FreeRouting, verify its version with a small DSN/SES round trip before relying on it, route without copper zones unless preservation has been proven, then re-add/fill zones and rerun DRC.

## 5. Export manufacturing data

Run `scripts/Export-JlcpcbGerbers.ps1`. It rejects KiCad error-level DRC violations, generates a full warning report, plots both copper layers, masks, silkscreens, paste, outline and Excellon drill, then creates a ZIP.

Inspect the ZIP in a Gerber viewer. Verify dimensions, outline closure, copper on both sides, PTH/NPTH drill hits, connector orientation and reference text.

## 6. Hardware acceptance

Calibrate and test with an isolated low-voltage source before connecting a CT in its final installation. The included PyVISA script sweeps input and fits `Vout = intercept + gain * Vin_rms`.

Bench oscilloscope ground clips are normally earth referenced. Connect them only to isolated low-voltage board ground. Never connect them to mains or an unisolated high-side conductor.
