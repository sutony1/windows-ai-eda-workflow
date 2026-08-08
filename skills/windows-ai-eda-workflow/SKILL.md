---
name: windows-ai-eda-workflow
description: "Set up, diagnose, reproduce, and operate a Windows AI-assisted electronics workflow spanning ngspice/LTspice simulation, KiCad 10, the mixelpixx KiCAD MCP server, EasyEDA Pro/easyeda-agent, Gerber export, and JLCPCB ordering. Use when migrating this EDA toolchain to another Windows PC, validating installed versions and MCP connectivity, turning a simulated circuit into a checked KiCad PCB, transferring designs to EasyEDA, or preparing a safe manufacturing handoff without submitting an order automatically."
---

# Windows AI EDA Workflow

Preserve KiCad as the authoritative electrical and PCB source. Use EasyEDA as a downstream collaboration/order surface unless its reconstructed schematic passes a real netlist check.

## Start here

1. Read [references/toolchain.md](references/toolchain.md) when installing or diagnosing software/MCP.
2. Read [references/design-flow.md](references/design-flow.md) before simulation, schematic, PCB, ERC/DRC, or Gerber work.
3. Read [references/easyeda-jlcpcb.md](references/easyeda-jlcpcb.md) before importing into EasyEDA or quoting/ordering.
4. Read [references/migration-checklist.md](references/migration-checklist.md) for a new-computer handoff.
5. For the included CT RMS-to-DC design, also invoke `$kicad-ct-rms-pcb`.

## Required gates

- Run `scripts/Test-AiEdaEnvironment.ps1` before operating GUI tools.
- Simulate at zero, mid-scale, and full-scale before drawing the final PCB.
- Treat vendor macro models as external inputs; record source and simulator version.
- Inspect the generated KiCad netlist. Visual contact is not electrical proof.
- Require ERC and PCB DRC to have zero errors before manufacturing export.
- Generate Gerbers with `scripts/Export-JlcpcbGerbers.ps1`; inspect both copper layers, drill, mask, silkscreen, and outline.
- Never submit or pay for a manufacturing order without explicit user authorization.

## Tool boundaries

- Use the validated mixelpixx TypeScript MCP baseline when reproducing this exact workflow. Upstream's newer Konnect successor is a separate migration, not a drop-in substitution.
- Keep one authoritative KiCad editor session. After external file/MCP edits, reopen the board before further GUI work.
- Keep easyeda-agent CLI/daemon, connector `.eext`, and upstream Skill on exactly the same version.
- Keep the easyeda-agent daemon running. Use `scripts/Start-EasyEdaAgent.ps1` to launch it hidden.
- Do not trust converted EasyEDA connectivity until `sch read/check` reports real nets and expected components.

## Recovery rules

- If KiCad MCP is missing, run `scripts/Install-KicadMcp.ps1`, register the printed TOML block in Codex, and restart Codex.
- If EasyEDA shows `encoding-error`, use the official format conversion assistant, then import the resulting `.epro`.
- If EasyEDA DRC reports a netlist mismatch after KiCad import, stop using that converted schematic for electrical synchronization. Order bare boards from checked KiCad Gerbers.
- If bottom copper disappears during conversion, compare the imported track count/layers against KiCad and do not proceed until both match.
- If a tool version differs from the validated baseline, run smoke tests before trusting production output.

## Expected handoff

Deliver project sources, simulator decks/results, version manifest, ERC/DRC reports, BOM/PnP where applicable, Gerber ZIP, calibration notes, and known warnings. State which file is authoritative.

Do not claim the workflow is reproduced merely because applications launch. Prove the MCP connection, a SPICE smoke test, KiCad ERC/DRC, Gerber generation, and EasyEDA daemon/connector health.
