[CmdletBinding()]
param(
    [string] $BotNexusRepoRoot = $env:BOTNEXUS_REPO_ROOT,
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($BotNexusRepoRoot)) {
    throw 'Set BOTNEXUS_REPO_ROOT or pass -BotNexusRepoRoot with the path to a BotNexus checkout.'
}

$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root 'src/BotNexus.Extensions.Reference/BotNexus.Extensions.Reference.csproj'
dotnet build $project -c $Configuration -p:BotNexusRepoRoot="$BotNexusRepoRoot"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
