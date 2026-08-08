[CmdletBinding()]
param([switch]$Strict)

$ErrorActionPreference = 'SilentlyContinue'
$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    param([string]$Name, [bool]$Ok, [string]$Detail, [bool]$Required = $true)
    $checks.Add([pscustomobject]@{
        Status = if ($Ok) { 'PASS' } elseif ($Required) { 'FAIL' } else { 'WARN' }
        Required = $Required
        Component = $Name
        Detail = $Detail
    })
}

if ($env:OS -eq 'Windows_NT') { Add-Check 'Windows' $true ([Environment]::OSVersion.VersionString) }
else { Add-Check 'Windows' $false 'This workflow targets Windows 10/11.' }

$git = Get-Command git.exe -ErrorAction SilentlyContinue
Add-Check 'Git' ($null -ne $git) $(if ($git) { (& $git.Source --version) -join ' ' } else { 'Install Git for Windows.' })

$node = Get-Command node.exe -ErrorAction SilentlyContinue
$nodeVersion = if ($node) { (& $node.Source --version) -join ' ' } else { '' }
$nodeOk = $false
if ($nodeVersion -match '^v(\d+)') { $nodeOk = [int]$Matches[1] -ge 20 }
Add-Check 'Node.js 20+' $nodeOk $(if ($node) { $nodeVersion } else { 'Install Node.js 20 or newer.' })

$python = Get-Command py.exe, python.exe -ErrorAction SilentlyContinue | Select-Object -First 1
Add-Check 'Python' ($null -ne $python) $(if ($python) { $python.Source } else { 'Install Python 3.11+.' }) $false

$kicadCli = @(
    'C:\Program Files\KiCad\10.0\bin\kicad-cli.exe',
    (Get-Command kicad-cli.exe -ErrorAction SilentlyContinue).Source
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
$kicadVersion = ''
if ($kicadCli) {
    $kicadVersion = ((& $kicadCli version 2>&1) | Where-Object { "$_" -match '^10\.' } | Select-Object -First 1)
}
Add-Check 'KiCad 10' ([bool]$kicadVersion) $(if ($kicadVersion) { "$kicadVersion ($kicadCli)" } else { 'Install KiCad 10 x64.' })

$ngspice = @(
    (Get-Command ngspice_con.exe -ErrorAction SilentlyContinue).Source,
    'C:\Spice64\bin\ngspice_con.exe',
    'D:\Spice64\bin\ngspice_con.exe',
    'C:\Program Files\ngspice\bin\ngspice_con.exe'
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
$ngVersion = if ($ngspice) { ((& $ngspice -v 2>&1) | Where-Object { "$_" -match 'ngspice-' } | Select-Object -First 1) } else { '' }
Add-Check 'ngspice' ([bool]$ngVersion) $(if ($ngVersion) { "$ngVersion ($ngspice)" } else { 'Install a Windows x64 stable build and add bin to PATH.' })

$uninstallRoots = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$apps = Get-ItemProperty $uninstallRoots -ErrorAction SilentlyContinue
$ltspice = $apps | Where-Object DisplayName -eq 'LTspice' | Select-Object -First 1
Add-Check 'LTspice' ($null -ne $ltspice) $(if ($ltspice) { "$($ltspice.DisplayVersion) $($ltspice.InstallLocation)" } else { 'Install LTspice from Analog Devices.' })

$easyeda = $apps | Where-Object { $_.DisplayName -match '嘉立创EDA\(专业版\)|EasyEDA Pro' } | Select-Object -First 1
$easyedaExe = 'C:\Program Files\lceda-pro\lceda-pro.exe'
$easyedaOk = ($null -ne $easyeda) -or (Test-Path -LiteralPath $easyedaExe)
$easyedaDetail = if ($easyeda) { "$($easyeda.DisplayVersion) $($easyeda.InstallLocation)" } elseif (Test-Path -LiteralPath $easyedaExe) { $easyedaExe } else { 'Install EasyEDA Pro.' }
Add-Check 'EasyEDA Pro' $easyedaOk $easyedaDetail

$agentDirs = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Programs') -Directory -Filter 'easyeda-agent-v*' -ErrorAction SilentlyContinue
$agent = $agentDirs | Sort-Object { try { [version]($_.Name -replace '^easyeda-agent-v','') } catch { [version]'0.0' } } -Descending | Select-Object -First 1
$agentExe = if ($agent) { Join-Path $agent.FullName 'easyeda.exe' } else { '' }
Add-Check 'easyeda-agent' ($agentExe -and (Test-Path -LiteralPath $agentExe)) $(if ($agentExe) { $agentExe } else { 'Install matching CLI, connector and Skill.' })

$codexConfig = Join-Path $env:USERPROFILE '.codex\config.toml'
$hasKicadMcp = (Test-Path -LiteralPath $codexConfig) -and (Select-String -LiteralPath $codexConfig -Pattern '^\[mcp_servers\.kicad\]$' -Quiet)
Add-Check 'Codex KiCad MCP config' $hasKicadMcp $(if ($hasKicadMcp) { $codexConfig } else { 'Register the built mixelpixx server, then restart Codex.' })

$skillPath = Join-Path $env:USERPROFILE '.codex\skills\windows-ai-eda-workflow\SKILL.md'
Add-Check 'Codex workflow skill' (Test-Path -LiteralPath $skillPath) $skillPath

$checks | Format-Table Status, Required, Component, Detail -AutoSize -Wrap

$failures = @($checks | Where-Object { $_.Status -eq 'FAIL' })
if ($Strict -and $failures.Count -gt 0) { exit 1 }
