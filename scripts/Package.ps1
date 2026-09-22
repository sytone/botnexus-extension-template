[CmdletBinding()]
param(
    [string] $BotNexusRepoRoot = $env:BOTNEXUS_REPO_ROOT,
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'Build.ps1') -BotNexusRepoRoot $BotNexusRepoRoot -Configuration $Configuration
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root "src/BotNexus.Extensions.Reference/bin/$Configuration/net10.0"
$destination = Join-Path $root 'artifacts/extensions/botnexus-reference'
if (Test-Path $destination) { Remove-Item $destination -Recurse -Force }
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item (Join-Path $output '*') $destination -Recurse -Force
Copy-Item (Join-Path $root 'src/BotNexus.Extensions.Reference/botnexus-extension.json') $destination -Force
& (Join-Path $PSScriptRoot 'Verify-Package.ps1') -PackagePath $destination
Write-Host "Packaged extension: $destination"
