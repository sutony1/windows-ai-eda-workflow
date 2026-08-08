[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$BoardPath,
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
$board = (Resolve-Path -LiteralPath $BoardPath).Path
if ([IO.Path]::GetExtension($board) -ne '.kicad_pcb') { throw 'BoardPath must be a .kicad_pcb file.' }

$kicad = @(
    'C:\Program Files\KiCad\10.0\bin\kicad-cli.exe',
    (Get-Command kicad-cli.exe -ErrorAction SilentlyContinue).Source
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $kicad) { throw 'KiCad 10 kicad-cli.exe was not found.' }

$boardDir = Split-Path -Parent $board
$name = [IO.Path]::GetFileNameWithoutExtension($board)
if (-not $OutputRoot) { $OutputRoot = Join-Path $boardDir ('manufacturing_' + (Get-Date -Format 'yyyyMMdd_HHmmss')) }
elseif (-not [IO.Path]::IsPathRooted($OutputRoot)) { $OutputRoot = Join-Path (Get-Location).Path $OutputRoot }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
if (Test-Path -LiteralPath $OutputRoot) { throw "OutputRoot already exists: $OutputRoot" }

$gerbers = Join-Path $OutputRoot 'gerbers'
New-Item -ItemType Directory -Force -Path $gerbers | Out-Null
$fullReport = Join-Path $OutputRoot 'drc_full.rpt'
$errorReport = Join-Path $OutputRoot 'drc_errors.rpt'

& $kicad pcb drc --output $fullReport --severity-all $board
if ($LASTEXITCODE -ne 0) { throw 'KiCad failed to generate the full DRC report.' }

& $kicad pcb drc --output $errorReport --severity-error --exit-code-violations $board
if ($LASTEXITCODE -ne 0) { throw "Error-level DRC violations found. Review: $errorReport" }

$layers = 'F.Cu,B.Cu,F.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts'
& $kicad pcb export gerbers --output $gerbers --layers $layers --subtract-soldermask $board
if ($LASTEXITCODE -ne 0) { throw 'Gerber export failed.' }

& $kicad pcb export drill --output $gerbers --format excellon --excellon-units mm --generate-map --map-format pdf $board
if ($LASTEXITCODE -ne 0) { throw 'Drill export failed.' }

$zip = Join-Path $OutputRoot ($name + '_JLCPCB_Gerbers.zip')
Compress-Archive -Path (Join-Path $gerbers '*') -DestinationPath $zip -CompressionLevel Optimal

$requiredPatterns = @('*F_Cu*','*B_Cu*','*F_Mask*','*B_Mask*','*Edge_Cuts*','*.drl')
foreach ($pattern in $requiredPatterns) {
    if (-not (Get-ChildItem -LiteralPath $gerbers -Filter $pattern -ErrorAction SilentlyContinue)) {
        throw "Expected manufacturing file is missing: $pattern"
    }
}

Write-Host "DRC full report: $fullReport"
Write-Host "Gerber ZIP:       $zip"
Write-Host 'Inspect both copper layers, drill, outline, masks and silkscreens before ordering.'
