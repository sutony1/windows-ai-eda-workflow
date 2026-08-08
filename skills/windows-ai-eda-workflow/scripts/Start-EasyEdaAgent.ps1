[CmdletBinding()]
param([switch]$Visible)

$ErrorActionPreference = 'Stop'
$programs = Join-Path $env:LOCALAPPDATA 'Programs'
$dirs = Get-ChildItem -LiteralPath $programs -Directory -Filter 'easyeda-agent-v*' -ErrorAction SilentlyContinue
$selected = $dirs | Sort-Object { try { [version]($_.Name -replace '^easyeda-agent-v','') } catch { [version]'0.0' } } -Descending | Select-Object -First 1
if (-not $selected) { throw 'easyeda-agent is not installed under %LOCALAPPDATA%\Programs.' }

$exe = Join-Path $selected.FullName 'easyeda.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "Missing executable: $exe" }

& $exe daemon health *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "easyeda-agent daemon is already healthy: $exe"
    exit 0
}

$options = @{
    FilePath = $exe
    ArgumentList = @('daemon')
    PassThru = $true
}
if (-not $Visible) { $options.WindowStyle = 'Hidden' }
$process = Start-Process @options
Start-Sleep -Seconds 2

Write-Host "Started easyeda-agent daemon, PID $($process.Id)."
Write-Host 'The process must remain running. Open EasyEDA Pro, enable external interaction, and load the connector.'
& $exe daemon health
