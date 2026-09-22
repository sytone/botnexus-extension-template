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
$project = Join-Path $root 'tests/BotNexus.Extensions.Reference.Tests/BotNexus.Extensions.Reference.Tests.csproj'
dotnet test $project -c $Configuration -p:BotNexusRepoRoot="$BotNexusRepoRoot" --nologo
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
