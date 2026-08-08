# LTC1967 official macro-model optimisation

Simulator: ADI LTspice 26.0.2.1 with the built-in `SpecialFunctions/LTC1967`
model.  The model was run from `ltc1967_filter_gain_optimization.cir` at 5 V,
50 Hz, with a differential input centred at 1.85 V.

The public portable deck is `ltspice_ltc1967_sweep.cir`. It intentionally omits
the proprietary `LTC1966.lib`; LTspice resolves that library from the local ADI
installation. The repository validation runs all seven input steps and saves
`V(VRMS)` and `V(VOUT)`; the numeric table below was extracted from the stable
tail of the generated waveforms.

## Chosen values

- LTC1967 output averaging capacitor, C6: 10 uF
- OPA2333 gain resistor, RG1: 10.0 kOhm, 0.1%
- OPA2333 feedback: 93.1 kOhm, 0.1%, in series with a 5 kOhm multiturn trim
- Calibration setting: approximately 0.44 kOhm trim resistance
- Output isolation/filter: 1.0 kOhm followed by 10 uF and a 100 kOhm ADC load

The final amplifier gain is approximately 10.354.  The 1 kOhm / 100 kOhm
output network reduces it by 100/101, giving a final calibrated scale of
about 10.251 at the LTC1967 output.

## Raw macro-model sweep, C6 = 10 uF, before final calibration

| Input (Vrms) | LTC1967 average (V) | Ripple at LTC output (Vpp) | Existing 10.26 gain output (V) |
|---:|---:|---:|---:|
| 0.000 | 0.001905 | 0.000000 | 0.01935 |
| 0.050 | 0.048777 | 0.000303 | 0.49549 |
| 0.100 | 0.097543 | 0.000619 | 0.99086 |
| 0.150 | 0.146321 | 0.000934 | 1.48637 |
| 0.200 | 0.195103 | 0.001250 | 1.98191 |
| 0.250 | 0.243891 | 0.001565 | 2.47751 |
| 0.300 | 0.292658 | 0.001881 | 2.97290 |

At the selected trim setting, the 0.300 Vrms point is 3.000 V.  The model's
residual zero-input offset maps to about 19.5 mV at the final output.  For an
absolute 0.000 V reading, subtract this offset in the ADC firmware, or add a
separate low-millivolt OPA2333 offset-trim stage.  Perform final calibration
with the assembled CT, because its burden, source impedance and phase are not
represented by an ideal voltage source.
