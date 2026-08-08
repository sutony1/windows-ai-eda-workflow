# Windows installation

This guide reproduces the validated Windows toolchain. Install the pinned baseline first; upgrade one component at a time only after the smoke tests pass.

## 1. Base tools

Install Git, Node.js 20 or later, Python 3.11 or later, and Codex. Then clone this repository and install its Skills:

```powershell
git clone https://github.com/sutony1/windows-ai-eda-workflow.git
cd windows-ai-eda-workflow
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Restart Codex after installing or changing Skills or MCP configuration.

## 2. KiCad 10 and the mixelpixx MCP

1. Install KiCad 10 x64 from <https://www.kicad.org/download/windows/>.
2. In KiCad, open `Preferences -> Preferences -> KiCad API` and enable the API.
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\windows-ai-eda-workflow\scripts\Install-KicadMcp.ps1
```

4. Copy the printed TOML block into `%USERPROFILE%\.codex\config.toml`.
5. Restart Codex and test a read-only KiCad MCP command.

The exact source is <https://github.com/mixelpixx/KiCAD-MCP-Server>, baseline 2.6.0 at commit `0dc3ee8ccad6efbf62c02b6a8736ddcf43118188`. Do not confuse it with `mixelpixx/SSH-MCP` or unrelated forks. `mixelpixx/Konnect` is a newer successor and requires separate validation.

## 3. ngspice

Install the current stable Windows x64 build from <https://ngspice.sourceforge.io/download.html>. As of 2026-08 the official end-user stable release is ngspice 46; the validated machine's 42+ KLU build remains acceptable for reproducing the stored result. Add the directory containing `ngspice_con.exe` to the user `PATH` and verify:

```powershell
ngspice_con.exe -v
ngspice_con.exe -b .\examples\ct-rms-to-dc\simulation\ngspice_behavioral_smoke.cir
```

For unattended runs prefer `ngspice_con.exe`; the GUI executable can wait for a window and appear hung.

## 4. LTspice and LTC1967

Install LTspice from <https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html> and start it once. Obtain the LTC1967/LTC1966 macro model from Analog Devices or the installed LTspice libraries. The model is intentionally excluded from this public repository; record its source and version beside every result.

## 5. EasyEDA Pro and easyeda-agent

1. Install 嘉立创 EDA 专业版. The validated version is 3.2.175.
2. Download one easyeda-agent release from <https://github.com/zhoushoujianwork/easyeda-agent/releases>. The validated version is 0.21.2; upstream 0.21.4 is the latest as of 2026-08. Use 0.21.2 for an exact reproduction, or upgrade all pieces together to 0.21.4 and rerun every smoke test.
3. Install all matching pieces from that same release: Windows CLI/daemon, EasyEDA connector `.eext`, and the upstream Codex Skill.
4. In EasyEDA Pro enable external interaction in Settings.
5. Start the daemon:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\windows-ai-eda-workflow\scripts\Start-EasyEdaAgent.ps1
easyeda daemon health
```

The daemon must remain running. The provided script launches it in a hidden window; closing a manually opened daemon terminal stops that instance.

## 6. Full check

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\windows-ai-eda-workflow\scripts\Test-AiEdaEnvironment.ps1 -Strict
```

Application launch alone is insufficient. Verify an ngspice batch run, a read-only KiCad MCP call, ERC/DRC, Gerber generation, and easyeda-agent daemon plus connector health.
