# Checks a release package against what the game loads.
# Usage, from anywhere:
#   .\scripts\check-package.ps1 <path to Lodestar-<tag>.zip>
#   .\scripts\check-package.ps1 <path to a built Lodestar folder>
# Expected files, worked out from the package itself:
#   - Lodestar.toc and every file it lists;
#   - every Media file named by an Interface\AddOns\Lodestar\Media\<name> path in the packaged
#     .lua and .xml files (matched by name, any extension);
#   - README.md, LICENSE and CHANGELOG.md.
# Fails on any extra or missing file, on anything outside the top-level Lodestar folder (zip only),
# and on a .toc that still holds @project-version@.
# Exit code 0 when the package is right, 1 otherwise. Windows PowerShell 5.1, no extra tools.

param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'

$AddonName = 'Lodestar'
$ExtraDocs = @('README.md', 'LICENSE', 'CHANGELOG.md')
$MediaPattern = 'Interface\\+AddOns\\+Lodestar\\+Media\\+([A-Za-z0-9_.\-]+)'

$problems = New-Object System.Collections.Generic.List[string]
$tempDir = $null

function ConvertTo-PackagePath([string]$relative) {
  return ($relative -replace '\\', '/').TrimStart('/')
}

try {
  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "Not found: $Path" -ForegroundColor Red
    exit 1
  }
  $item = Get-Item -LiteralPath $Path

  # Find the addon folder: inside an extracted zip, or the folder given.
  if ($item.PSIsContainer) {
    $addonDir = $item.FullName
    if ($item.Name -ne $AddonName) {
      $problems.Add("folder is named '$($item.Name)', expected '$AddonName'")
    }
  }
  else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("check-package-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($item.FullName, $tempDir)

    foreach ($top in Get-ChildItem -LiteralPath $tempDir -Force) {
      if (-not ($top.PSIsContainer -and $top.Name -ceq $AddonName)) {
        $problems.Add("outside the top-level $AddonName folder: $($top.Name)")
      }
    }
    $addonDir = Join-Path $tempDir $AddonName
    if (-not (Test-Path -LiteralPath $addonDir)) {
      Write-Host "The zip has no top-level $AddonName folder." -ForegroundColor Red
      foreach ($p in $problems) { Write-Host "  $p" -ForegroundColor Red }
      exit 1
    }
  }

  # Every file in the package, as 'Data/Zones.lua'-style paths. Keys are case-insensitive, like the game.
  $actual = @{}
  $prefixLength = $addonDir.TrimEnd('\').Length + 1
  foreach ($file in Get-ChildItem -LiteralPath $addonDir -Recurse -File -Force) {
    $relative = ConvertTo-PackagePath $file.FullName.Substring($prefixLength)
    $actual[$relative] = $file.FullName
  }

  $expected = @{}
  $tocName = "$AddonName.toc"
  $expected[$tocName] = $true
  foreach ($doc in $ExtraDocs) { $expected[$doc] = $true }

  # The .toc: its file list and its version.
  if ($actual.ContainsKey($tocName)) {
    foreach ($line in Get-Content -LiteralPath $actual[$tocName]) {
      $trimmed = $line.Trim()
      if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
      $expected[(ConvertTo-PackagePath $trimmed)] = $true
    }
    if (Select-String -LiteralPath $actual[$tocName] -SimpleMatch '@project-version@' -Quiet) {
      $problems.Add("$tocName still holds @project-version@ (the packager did not set the version)")
    }
  }

  # Media files named in the packaged code, matched by name without the extension.
  $mediaNames = @{}
  foreach ($key in $actual.Keys) {
    if ($key -notmatch '\.(lua|xml)$') { continue }
    $text = [System.IO.File]::ReadAllText($actual[$key])
    foreach ($m in [regex]::Matches($text, $MediaPattern, 'IgnoreCase')) {
      $name = [System.IO.Path]::GetFileNameWithoutExtension($m.Groups[1].Value)
      $mediaNames[$name] = $key
    }
  }
  foreach ($name in $mediaNames.Keys) {
    $found = @($actual.Keys | Where-Object {
        $_ -like 'Media/*' -and $_.IndexOf('/', 6) -lt 0 -and
        [System.IO.Path]::GetFileNameWithoutExtension($_) -eq $name
      })
    if ($found.Count -eq 0) {
      $problems.Add("missing: Media/$name.* (referenced in $($mediaNames[$name]))")
    }
    foreach ($f in $found) { $expected[$f] = $true }
  }

  foreach ($key in ($expected.Keys | Sort-Object)) {
    if (-not $actual.ContainsKey($key)) { $problems.Add("missing: $key") }
  }
  foreach ($key in ($actual.Keys | Sort-Object)) {
    if (-not $expected.ContainsKey($key)) { $problems.Add("extra: $key") }
  }

  if ($problems.Count -gt 0) {
    foreach ($p in $problems) { Write-Host $p -ForegroundColor Red }
    Write-Host "Package check failed ($($problems.Count) problem(s)), $($actual.Count) files checked" -ForegroundColor Red
    exit 1
  }

  Write-Host "Package check passed: $($actual.Count) files, $($mediaNames.Count) Media files referenced" -ForegroundColor Green
  exit 0
}
finally {
  if ($null -ne $tempDir -and (Test-Path -LiteralPath $tempDir)) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
  }
}
