#!/usr/bin/env python3
"""Automated acceptance sweep for the 5 V CT RMS-to-DC conditioner.

CH1 measures the actual AC input and CH2 the board DC output.  The program
writes raw samples and a least-squares linearity report.

Safety: oscilloscope ground clips are earth-referenced. Connect them only to
the low-voltage board GND; never to mains or a high-side conductor.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    import pyvisa
except ImportError as exc:
    raise SystemExit("Missing dependency: install with `pip install pyvisa`.") from exc


DEFAULT_POINTS = (0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30)


def parse_points(value: str) -> list[float]:
    points = [float(item.strip()) for item in value.split(",") if item.strip()]
    if len(points) < 2 or any(point < 0 for point in points):
        raise argparse.ArgumentTypeError("Use at least two non-negative Vrms points.")
    return points


def measure(scope: Any, command: str) -> float:
    value = float(scope.query(command).strip())
    if not math.isfinite(value) or abs(value) > 1e20:
        raise RuntimeError(f"Invalid measurement from {command}: {value!r}")
    return value


def linear_fit(rows: list[dict[str, float]]) -> tuple[float, float]:
    """Return intercept and slope for output = intercept + slope * input."""
    x = [row["input_vrms"] for row in rows]
    y = [row["output_vavg"] for row in rows]
    x_mean, y_mean = sum(x) / len(x), sum(y) / len(y)
    denominator = sum((item - x_mean) ** 2 for item in x)
    if denominator == 0:
        raise RuntimeError("Measured input did not change; cannot fit a transfer function.")
    slope = sum((xi - x_mean) * (yi - y_mean) for xi, yi in zip(x, y)) / denominator
    return y_mean - slope * x_mean, slope


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--scope",
        required=True,
        help="VISA resource, e.g. TCPIP0::192.168.1.100::INSTR or USB0::...::INSTR",
    )
    result.add_argument("--visa-backend", default=None, help="Optional backend, e.g. @py.")
    result.add_argument("--frequency", type=float, default=50.0, help="Expected input frequency in Hz.")
    result.add_argument(
        "--points",
        type=parse_points,
        default=list(DEFAULT_POINTS),
        help="Comma-separated input values in Vrms (default 0,0.05,...,0.30).",
    )
    result.add_argument(
        "--settle-seconds",
        type=float,
        default=8.0,
        help="Wait after every input change for LTC1967/C6 settling (default: 8).",
    )
    result.add_argument("--target-gain", type=float, default=10.0, help="Expected zero-corrected gain.")
    result.add_argument("--target-full-scale", type=float, default=3.0, help="Desired raw full-scale output.")
    result.add_argument("--generator-resource", help="Optional VISA resource for an external generator.")
    result.add_argument(
        "--generator-command-template",
        help=(
            "SCPI sent to the generator. Fields: {freq}, {vrms}, {vpp}. Example: "
            "':SOURce1:APPLy:SINusoid {freq},{vpp},0'. Verify it with that generator's manual."
        ),
    )
    result.add_argument("--output-dir", type=Path, default=Path("test_results"))
    return result


def main() -> int:
    args = parser().parse_args()
    if bool(args.generator_resource) != bool(args.generator_command_template):
        raise SystemExit("Use --generator-resource and --generator-command-template together.")
    if args.settle_seconds < 0:
        raise SystemExit("--settle-seconds must be non-negative.")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    rm = pyvisa.ResourceManager(args.visa_backend or "")
    scope = rm.open_resource(args.scope)
    scope.timeout = 15_000
    scope.read_termination = "\n"
    scope.write_termination = "\n"
    generator = None
    try:
        scope_idn = scope.query("*IDN?").strip()
        print(f"Scope: {scope_idn}")
        if "DS1202Z-E" not in scope_idn.upper():
            print("WARNING: scope is not identified as DS1202Z-E; verify SCPI compatibility.")
        if args.generator_resource:
            generator = rm.open_resource(args.generator_resource)
            generator.timeout = 15_000
            generator.read_termination = "\n"
            generator.write_termination = "\n"
            print(f"Generator: {generator.query('*IDN?').strip()}")

        print(
            "CH1 tip -> CT_AC/J1; CH2 tip -> VOUT_0_3V; both ground clips -> board GND only. "
            "Use 10x probes with matching 10x scope settings."
        )
        print("Set CH1 to AC coupling and CH2 to DC coupling before proceeding.")
        input("Press Enter only after the wiring is verified safe ... ")

        rows: list[dict[str, float]] = []
        for commanded_vrms in args.points:
            vpp = 2.0 * math.sqrt(2.0) * commanded_vrms
            if generator is None:
                input(
                    f"Set isolated source: {args.frequency:g} Hz sine, {commanded_vrms:.6f} Vrms "
                    f"({vpp:.6f} Vpp), 0 V offset; then press Enter ... "
                )
            else:
                command = args.generator_command_template.format(
                    freq=args.frequency, vrms=commanded_vrms, vpp=vpp
                )
                print(f"Generator <= {command}")
                generator.write(command)

            time.sleep(args.settle_seconds)
            row = {
                "commanded_vrms": commanded_vrms,
                "input_vrms": measure(scope, ":MEASure:ITEM? VRMS,CHANnel1"),
                "input_frequency_hz": measure(scope, ":MEASure:ITEM? FREQuency,CHANnel1"),
                "output_vavg": measure(scope, ":MEASure:ITEM? VAVG,CHANnel2"),
                "output_vrms": measure(scope, ":MEASure:ITEM? VRMS,CHANnel2"),
            }
            rows.append(row)
            print(
                f"Vin={row['input_vrms']:.6f} Vrms @ {row['input_frequency_hz']:.4f} Hz, "
                f"Vout(avg)={row['output_vavg']:.6f} V, Vout(rms)={row['output_vrms']:.6f} V"
            )

        intercept, slope = linear_fit(rows)
        full_scale = max(rows, key=lambda row: row["input_vrms"])
        span = max(abs(slope * full_scale["input_vrms"]), 1e-12)
        for row in rows:
            row["fit_output_v"] = intercept + slope * row["input_vrms"]
            row["residual_v"] = row["output_vavg"] - row["fit_output_v"]
        max_linearity_error_pct_fs = 100.0 * max(abs(row["residual_v"]) for row in rows) / span
        gain_error_pct = 100.0 * (slope - args.target_gain) / args.target_gain
        full_scale_error_v = full_scale["output_vavg"] - args.target_full_scale
        frequency_error_hz = max(abs(row["input_frequency_hz"] - args.frequency) for row in rows)
        report = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "scope_resource": args.scope,
            "scope_idn": scope_idn,
            "frequency_target_hz": args.frequency,
            "target_gain_v_per_v": args.target_gain,
            "target_full_scale_v": args.target_full_scale,
            "fit_intercept_v": intercept,
            "fit_gain_v_per_v": slope,
            "gain_error_percent": gain_error_pct,
            "max_linearity_error_percent_fs": max_linearity_error_pct_fs,
            "full_scale_error_v": full_scale_error_v,
            "maximum_frequency_error_hz": frequency_error_hz,
            "notes": [
                "CH1 measures the zero-centred source before board biasing.",
                "CH2 VAVG is output DC; CH2 VRMS exposes residual ripple/noise.",
                "Calibrate a repeatable LTC1967 zero intercept in firmware or production test.",
                "Never use a scope ground clip on mains or high-side circuitry.",
            ],
            "samples": rows,
        }
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        csv_path = args.output_dir / f"ct_rms_sweep_{stamp}.csv"
        json_path = args.output_dir / f"ct_rms_report_{stamp}.json"
        with csv_path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        json_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print("\nAcceptance summary")
        print(f"  zero/intercept: {intercept:.6f} V")
        print(f"  fitted gain:    {slope:.6f} V/V ({gain_error_pct:+.3f}% vs target)")
        print(f"  linearity:      {max_linearity_error_pct_fs:.4f}% FS")
        print(f"  full-scale:     {full_scale['output_vavg']:.6f} V ({full_scale_error_v:+.6f} V vs target)")
        print(f"  output ripple:  {full_scale['output_vrms']:.6f} Vrms at full-scale")
        print(f"  saved: {csv_path}\n         {json_path}")
        return 0
    finally:
        if generator is not None:
            generator.close()
        scope.close()
        rm.close()


if __name__ == "__main__":
    raise SystemExit(main())
