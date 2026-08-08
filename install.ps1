[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $env:USERPROFILE '.codex\skills')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = Join-Path $repoRoot 'skills'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path (Split-Path -Parent $Destination) (Join-Path 'skill-backups' $stamp)

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

Get-ChildItem -LiteralPath $sourceRoot -Directory | ForEach-Object {
    $target = Join-Path $Destination $_.Name
    if (Test-Path -LiteralPath $target) {
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $backup = Join-Path $backupRoot $_.Name
        Move-Item -LiteralPath $target -Destination $backup
        Write-Host "Backed up existing skill: $backup"
    }
    Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse
    Write-Host "Installed skill: $($_.Name) -> $target"
}

Write-Host ''
Write-Host 'Restart Codex so it discovers the installed skills.'
Write-Host 'Then invoke: $windows-ai-eda-workflow'
