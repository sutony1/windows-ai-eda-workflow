# Windows toolchain installation and diagnosis

## Validated baseline

| Component | Baseline | Verification |
|---|---|---|
| Windows | 10/11 x64 | `Get-ComputerInfo` |
| KiCad | 10.0.5 | `kicad-cli version` |
| KiCAD-MCP-Server | 2.6.0 / `0dc3ee8` | `package.json`, MCP tool call |
| ngspice | 42+ x64 KLU | `ngspice_con.exe -v` |
| LTspice | 26.0.2.1 | Windows Apps / registry |
| EasyEDA Pro | 3.2.175 | title bar / Apps |
| easyeda-agent | 0.21.2 | `easyeda daemon health` |
| Node.js | 20+ | `node --version` |

Install the exact baseline first when reproducibility matters. Upgrade only one layer at a time and repeat all smoke tests.

## KiCad 10

Install the official Windows x64 stable release. Enable `Preferences -> Preferences -> KiCad API -> Enable KiCad API`. Confirm:

```powershell
& 'C:\Program Files\KiCad\10.0\bin\kicad-cli.exe' version
```

## mixelpixx KiCAD MCP

The exact repository used in this workflow is [mixelpixx/KiCAD-MCP-Server](https://github.com/mixelpixx/KiCAD-MCP-Server), not `SSH-MCP`, the profile repository, or an unrelated fork. Use `scripts/Install-KicadMcp.ps1`. It clones the upstream repository, checks out the validated commit, installs Node dependencies, builds `dist/index.js`, and prints the Codex TOML block.

Expected Codex configuration:

```toml
[mcp_servers.kicad]
command = "node"
args = ['C:\Users\YOUR_NAME\AppData\Local\ai-eda\KiCAD-MCP-Server\dist\index.js']
startup_timeout_sec = 120.0

[mcp_servers.kicad.env]
KICAD_PYTHON = 'C:\Program Files\KiCad\10.0\bin\python.exe'
NODE_ENV = "production"
LOG_LEVEL = "info"
```

Restart Codex and call a read-only KiCad MCP tool before editing. [mixelpixx/Konnect](https://github.com/mixelpixx/Konnect) is the upstream successor for KiCad 10, but migrating to it changes architecture and must be validated separately.

## ngspice

Install an official stable Windows x64 build. The verified build is ngspice 42+ with KLU. Prefer the console executable for automation:

```powershell
ngspice_con.exe -v
ngspice_con.exe -b .\simulation\ngspice_behavioral_smoke.cir
```

Add its `bin` directory to the user `PATH`. A newer stable version is acceptable only after rerunning the sweep and comparing results.

## LTspice and vendor models

Install LTspice from Analog Devices. Open it once so its user library directories are created. Obtain the LTC1967/LTC1966 library through the official LTspice installation or Analog Devices model page. Do not copy a model out of a licensed install into this public repository.

Run the included deck after placing the required vendor library beside it or updating the `.include` path. Record LTspice version and model provenance in results.

## EasyEDA Pro and easyeda-agent

Install EasyEDA Pro and enable `Settings -> Allow external interaction`. Install the easyeda-agent CLI/daemon, matching connector `.eext`, and matching upstream Skill. All three must use the same release.

The exact validated combination is EasyEDA Pro 3.2.175 plus easyeda-agent 0.21.2. Upstream releases may be newer; upgrade CLI, connector and Skill together. Start and verify:

```powershell
.\scripts\Start-EasyEdaAgent.ps1
easyeda daemon health
```

The daemon must remain running. Closing its terminal stops the connection unless it was launched hidden or installed as a service.
