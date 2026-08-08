# 5 V CT RMS-to-DC example

Target: 0–300 mVrms, 50 Hz current-transformer voltage input to approximately 0–3 V DC from a 5 V supply.

## Contents

- `kicad/`: authoritative KiCad 10 schematic, project, and routed PCB.
- `simulation/`: ngspice behavioural smoke test, portable LTspice sweep deck, and measured simulation results.
- `hardware-test/`: PyVISA/RIGOL automated verification example.
- `manufacturing/`: checked Gerber ZIP plus BOM and pick-and-place CSV.

## Selected values

- LTC1967 averaging capacitor: 10 uF.
- OPA2333 gain resistor: 10.0 kOhm, 0.1%.
- Feedback: 93.1 kOhm, 0.1%, plus 5 kOhm multiturn trim; nominal trim about 0.44 kOhm.
- Output filter/isolation: 1 kOhm, 10 uF, and 100 kOhm load.
- Full-scale calibration: adjust 300 mVrms input to 3.000 V output.

The macro-model predicts about 19.5 mV output at zero input after gain. Subtract it in firmware or add a low-offset trim stage if a true zero display is required. Calibrate with the real CT and burden.

## Status

The KiCad board has 126 track segments, zero unconnected pads, and zero error-level DRC findings. A clean-machine CLI run can also report non-electrical silkscreen and library-table warnings; review the full report without confusing those warnings with electrical errors. EasyEDA conversion is not authoritative; use the KiCad source and Gerbers for manufacturing.

## Optional RIGOL automated test

Install a VISA backend and PyVISA, connect the scope over USB or LAN, and list resources before running the script:

```powershell
py -3 -m pip install pyvisa pyvisa-py
py -3 .\hardware-test\rigol_ct_rms_verify.py --help
```

The script does not generate the 50 Hz input by itself; use a calibrated source or supported generator and observe the isolation/grounding rules for the current-transformer test setup.
