[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $BotNexusRepoRoot = $env:BOTNEXUS_REPO_ROOT,
    [string] $BotNexusHome = $env:BOTNEXUS_HOME,
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($BotNexusHome)) {
    $BotNexusHome = Join-Path $HOME '.botnexus'
}

& (Join-Path $PSScriptRoot 'Package.ps1') -BotNexusRepoRoot $BotNexusRepoRoot -Configuration $Configuration
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'artifacts/extensions/botnexus-reference'
$destination = Join-Path $BotNexusHome 'extensions/botnexus-reference'

Write-Warning 'Current BotNexus lifecycle commands only preserve in-repository extension IDs. A later serve/update deployment may remove this manually installed directory as stale. See README.md.'
if ($PSCmdlet.ShouldProcess($destination, 'Replace the locally installed reference extension')) {
    if (Test-Path $destination) { Remove-Item $destination -Recurse -Force }
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item $source $destination -Recurse -Force
    Write-Host "Installed extension: $destination"
    Write-Host 'Restart the BotNexus gateway, then verify GET /api/extensions and the reference_echo tool.'
}
