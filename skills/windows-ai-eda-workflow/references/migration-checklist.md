# New Windows computer migration checklist

## Install

- [ ] Install Git, Node.js 20+, Python 3.11+ and Codex.
- [ ] Clone this repository.
- [ ] Run root `install.ps1` and restart Codex.
- [ ] Install KiCad 10.x and enable the KiCad API.
- [ ] Run `Install-KicadMcp.ps1`; add the printed MCP config; restart Codex.
- [ ] Install ngspice x64 and LTspice; obtain the vendor LTC1967 model separately.
- [ ] Install EasyEDA Pro.
- [ ] Install exactly matching easyeda-agent CLI, connector `.eext`, and upstream Skill.
- [ ] Enable EasyEDA external interaction and start the daemon.

## Smoke tests

- [ ] `Test-AiEdaEnvironment.ps1 -Strict` passes required checks.
- [ ] ngspice runs the behavioural deck in batch mode.
- [ ] LTspice runs the vendor macro-model sweep.
- [ ] Codex can call a read-only KiCad MCP tool.
- [ ] The example KiCad project opens with no missing symbols/footprints.
- [ ] ERC has zero errors.
- [ ] PCB DRC has zero errors and zero unconnected pads.
- [ ] `Export-JlcpcbGerbers.ps1` creates a Gerber ZIP.
- [ ] Gerber viewer shows both copper layers and all drills.
- [ ] `easyeda daemon health` reports daemon and connector online.

## Handoff prompt

```text
Use $windows-ai-eda-workflow to run the migration checklist. Keep KiCad as the authoritative source,
pin the validated tool versions until smoke tests pass, and do not submit a PCB order.
```

Required archive sentence (kept verbatim):

> 解压到其他机器的 `%USERPROFILE%\.codex\skills\` 后，按新文档安装 ngspice 与 KiCad MCP、重启 Codex 即可。

The GitHub version expands that instruction to LTspice, EasyEDA Pro, and easyeda-agent and should be installed with the root `install.ps1`.
