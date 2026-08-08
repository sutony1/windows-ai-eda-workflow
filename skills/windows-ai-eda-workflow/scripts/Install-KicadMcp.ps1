[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'ai-eda\KiCAD-MCP-Server'),
    [string]$Revision = '0dc3ee8ccad6efbf62c02b6a8736ddcf43118188'
)

$ErrorActionPreference = 'Stop'
$repo = 'https://github.com/mixelpixx/KiCAD-MCP-Server.git'

foreach ($command in 'git.exe','node.exe','npm.cmd') {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Missing prerequisite: $command"
    }
}

if (Test-Path -LiteralPath $InstallRoot) {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot '.git'))) {
        throw "InstallRoot exists but is not a git repository: $InstallRoot"
    }
    git -C $InstallRoot fetch origin --tags
    if ($LASTEXITCODE -ne 0) { throw 'Failed to refresh the KiCad MCP repository.' }
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallRoot) | Out-Null
    git clone $repo $InstallRoot
}

git -C $InstallRoot checkout --detach $Revision
if ($LASTEXITCODE -ne 0) { throw 'Failed to check out the validated revision.' }

Push-Location $InstallRoot
try {
    & npm.cmd ci
    if ($LASTEXITCODE -ne 0) { throw 'npm ci failed.' }
    & npm.cmd run build
    if ($LASTEXITCODE -ne 0) { throw 'npm build failed.' }
} finally {
    Pop-Location
}

$server = Join-Path $InstallRoot 'dist\index.js'
$kicadPython = 'C:\Program Files\KiCad\10.0\bin\python.exe'
if (-not (Test-Path -LiteralPath $server)) { throw "Build output missing: $server" }

Write-Host ''
Write-Host 'Add this block to %USERPROFILE%\.codex\config.toml, then restart Codex:'
Write-Host ''
Write-Host '[mcp_servers.kicad]'
Write-Host 'command = "node"'
Write-Host ("args = ['" + $server + "']")
Write-Host 'startup_timeout_sec = 120.0'
Write-Host ''
Write-Host '[mcp_servers.kicad.env]'
Write-Host ("KICAD_PYTHON = '" + $kicadPython + "'")
Write-Host 'NODE_ENV = "production"'
Write-Host 'LOG_LEVEL = "info"'
