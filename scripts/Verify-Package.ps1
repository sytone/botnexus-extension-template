[CmdletBinding()]
param(
    [string] $PackagePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts/extensions/botnexus-reference')
)

$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PackagePath 'botnexus-extension.json'
if (-not (Test-Path $manifestPath -PathType Leaf)) { throw "Manifest missing: $manifestPath" }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($manifest.id)) { throw 'Manifest id is missing.' }
if ([string]::IsNullOrWhiteSpace($manifest.entryAssembly)) { throw 'Manifest entryAssembly is missing.' }
if (-not (Test-Path (Join-Path $PackagePath $manifest.entryAssembly) -PathType Leaf)) {
    throw "Entry assembly missing: $($manifest.entryAssembly)"
}
if (@($manifest.extensionTypes).Count -eq 0) { throw 'Manifest extensionTypes is empty.' }
Write-Host "Verified package '$($manifest.id)' at $PackagePath"
