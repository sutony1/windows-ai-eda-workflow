# ngspice installation and version policy

Use this reference when provisioning another Codex computer.

## Version to use

Install the **latest stable ngspice**, not a nightly build. As of 2026-08, the recommended release is **ngspice 46**. The official project calls it the current end-user stable release and provides a Windows x64 binary. Do not select the `47plus` nightly unless a task explicitly needs unreleased features.

The CT simulation workflow uses only broadly supported transient, `.meas`, behavioural-source, `.param`, and control-loop constructs. ngspice **42 or newer** is acceptable for reproducing old projects, but use 46 for new work and record the output of `ngspice -v` in the project note.

Official sources:

- <https://ngspice.sourceforge.io/download.html>
- <https://sourceforge.net/projects/ngspice/files/ng-spice-rework/ngspice-46/>

## Windows 10/11 x64

1. Install 7-Zip if it is not already available.
2. From the official download page, get `ngspice-46_64.7z` from the stable `ngspice-46` folder.
3. Extract it to a user-writable path such as `D:\Spice64`. The executable should be `D:\Spice64\bin\ngspice.exe`.
4. Add only that `bin` directory to the **user** `Path` variable. In PowerShell:

   ```powershell
   $ngspiceBin = 'D:\Spice64\bin'
   $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
   if (($userPath -split ';') -notcontains $ngspiceBin) {
     [Environment]::SetEnvironmentVariable('Path', "$userPath;$ngspiceBin", 'User')
   }
   ```

5. Close and reopen Codex (and any terminals) so the new `Path` is inherited.
6. Verify:

   ```powershell
   Get-Command ngspice
   ngspice -v
   ```

Do not use `setx PATH ...` with a hand-copied full system path: it can truncate or accidentally overwrite an existing user path.

## Linux and macOS

Use the distribution package for routine work, then verify the version:

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install ngspice

# Fedora
sudo dnf install ngspice

# macOS with Homebrew
brew install ngspice

ngspice -v
```

Repository packages may lag the current stable release. Accept version 42+ for this skill; compile or install the official current release only when a project requires a newer feature or a reproducible exact version.

## Batch-mode smoke test

Run this after installation. It must end with an operating-point result and exit code 0.

```powershell
@'
V1 out 0 1
R1 out 0 1k
.op
.end
'@ | Set-Content "$env:TEMP\ngspice-smoke.cir" -Encoding ascii
ngspice -b "$env:TEMP\ngspice-smoke.cir"
```

For KiCad workflows, also set the simulator path in **Preferences → Configure Paths / Simulation** if KiCad does not locate the executable automatically.
