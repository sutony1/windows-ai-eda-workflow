# KiCad 9 MCP setup and migration

Use this reference only when setting up or repairing a new computer.

## Migrate this skill first

1. Extract `kicad-ct-simulation.skill.zip` into `%USERPROFILE%\.codex\skills\`.
2. Confirm that `%USERPROFILE%\.codex\skills\kicad-ct-simulation\SKILL.md` exists.
3. Install ngspice from `ngspice-install.md`, then complete the KiCad MCP steps below.
4. Restart Codex and begin a **new** task. Invoke the workflow with `$kicad-ct-simulation`.

Do not copy another machine's whole `config.toml`: retain its unrelated settings and add only the `mcp_servers.kicad` section with this computer's own absolute paths.

## Required software

- KiCad 9.x; install its bundled Python support.
- Node.js 18 or newer.
- Python 3.11 or newer. Prefer the bundled executable at `<KiCad>\\bin\\python.exe` for KiCad-facing dependencies.
- ngspice.
- Git.

In KiCad, open **Preferences → General → KiCad API** and select **Enable KiCad API**. Keep a KiCad window running while testing realtime IPC.

## Install mixelpixx KiCad MCP

Choose a stable local installation directory, then run:

```powershell
git clone --depth 1 https://github.com/mixelpixx/KiCAD-MCP-Server.git <install-dir>
Set-Location <install-dir>
npm install
& '<KiCad>\bin\python.exe' -m pip install -r requirements.txt
```

For a Windows KiCad 9 default install, `<KiCad>` is normally `C:\Program Files\KiCad\9.0`.

## Codex configuration

Add the following to `%USERPROFILE%\.codex\config.toml`, substituting the absolute clone path:

```toml
[mcp_servers.kicad]
command = "node"
args = ['D:\path\to\KiCAD-MCP-Server\dist\index.js']
startup_timeout_sec = 120.0

[mcp_servers.kicad.env]
KICAD_PYTHON = 'C:\Program Files\KiCad\9.0\bin\python.exe'
NODE_ENV = "production"
LOG_LEVEL = "info"
```

Restart Codex and start a new task. The current task's tool set is not retroactively updated.

## Verify IPC, not just process startup

The server staying alive only proves that Node and Python can start. Confirm the real API transport:

```powershell
& 'C:\Program Files\KiCad\9.0\bin\python.exe' -c "from kipy import KiCad; print(KiCad().get_version())"
```

Then call MCP `get_backend_state`. A successful realtime session reports `backend: ipc`, `realtime: true`, and `ipcConnected: true`. If it falls back to `swig`, verify that KiCad is open and the KiCad API checkbox is enabled.

## KiCad 9 file-version trap

Some current MCP releases can emit a KiCad 10 schematic even when the installed editor is KiCad 9. Detect it with the first lines of the file:

```scheme
(version 20260101)
(generator_version "10.0")
```

KiCad 9 expects its own version (commonly `20250114` / `9.0`) and may still reject newer symbol syntax after a superficial version edit. Prefer a legacy `.sch` interchange file and let Eeschema 9 convert and save it. Always prove the result with `kicad-cli sch export svg` before handing it off.
