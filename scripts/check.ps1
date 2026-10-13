# The one check command: luacheck, then the unit tests. Stops at the first failure.
# Usage, from anywhere:  .\scripts\check.ps1
# Exit code 0 when everything passes, 1 otherwise.

$ErrorActionPreference = 'Stop'

# Run from the repo root, so .luacheckrc is found and tests\run.lua can load Logic.lua.
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  $luacheck = Join-Path $root 'tools\luacheck.exe'
  $lua      = Join-Path $root 'tools\lua\lua5.1.exe'
  foreach ($tool in @($luacheck, $lua)) {
    if (-not (Test-Path $tool)) {
      Write-Host "Missing $tool; see the design doc, 'Dev environment setup'." -ForegroundColor Red
      exit 1
    }
  }

  Write-Host '== luacheck' -ForegroundColor Cyan
  & $luacheck .
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'luacheck failed' -ForegroundColor Red
    exit 1
  }

  Write-Host '== tests' -ForegroundColor Cyan
  & $lua 'tests\run.lua'
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'tests failed' -ForegroundColor Red
    exit 1
  }

  Write-Host 'All checks passed' -ForegroundColor Green
  exit 0
}
finally {
  Pop-Location
}
