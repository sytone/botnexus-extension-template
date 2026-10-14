# BotNexus extension template

Fork this repository to build a compiled BotNexus extension outside the main BotNexus repository.

The sample supplies one deterministic tool, `reference_echo`. It is intentionally small so the repository demonstrates the extension boundary rather than hiding it under application code.

> [!IMPORTANT]
> Compiled extensions run in the BotNexus gateway process with the gateway's full operating-system permissions. Only install code you trust and have reviewed.

## Current platform status

BotNexus supports repository registration and a full clone, build, and deployment lifecycle through `botnexus extensions sync` (also named `reconcile`). Registration with `extensions add` records the approved source and revision; it does not itself install or grant a tool. Sync reconciles enabled registrations, discovers projects with adjacent manifests, builds candidate output, and validates deployment before replacing the live extension tree. Failed candidates are reported without intentionally discarding last-known-good output.

Use the registered lifecycle below for durable installations. The template's `Install-Local.ps1` is only a disposable development helper: a manually copied, unregistered extension can be pruned by later deployment reconciliation. File presence alone does not prove successful loading or agent access.

## Repository contents

```text
src/BotNexus.Extensions.Reference/
  BotNexus.Extensions.Reference.csproj
  ReferenceEchoTool.cs
  botnexus-extension.json
tests/BotNexus.Extensions.Reference.Tests/
scripts/
  Build.ps1, Test.ps1, Package.ps1, Install-Local.ps1
  build.sh, test.sh
```

## Prerequisites

- .NET SDK 10.0.204 or a compatible later 10.0 SDK.
- An isolated BotNexus build checkout matching the host revision. The extension references BotNexus projects until extension SDK packages are published.
- PowerShell 7.3 or later for the commands below. Bash wrappers are included for build and test.
- For registered sync, Git and the .NET SDK must be available to the operator running the CLI.

## Start a new extension

1. Use **Use this template** on GitHub, or fork this repository.
2. Replace the reference identity consistently:

   | Current value | Replace with |
   | --- | --- |
   | `BotNexus.Extensions.Reference` | Your assembly, namespace, and project name |
   | `botnexus-reference` | A unique lowercase `botnexus-...` manifest ID |
   | `Reference Tool` | A concise display name |
   | `reference_echo` | A unique model-facing tool name |

3. Rename the source and test directories and update their project references.
4. Replace `ReferenceEchoTool` with your implementation.
5. Update `botnexus-extension.json`. Keep `entryAssembly` equal to the compiled DLL filename.
6. Add tests before adding behavior.
7. Update this README with the capability, permissions, configuration, and operational dependencies your extension requires.

Do not copy BotNexus contract DLLs into source control. The package script collects the build output needed at runtime.

## Point the template at BotNexus

For the template scripts, set `BOTNEXUS_REPO_ROOT` to an **isolated build checkout**, not the source tree or binaries serving a running gateway:

```powershell
$env:BOTNEXUS_REPO_ROOT = Read-Host 'Absolute path to the isolated BotNexus build checkout'
if ([string]::IsNullOrWhiteSpace($env:BOTNEXUS_REPO_ROOT) -or
    -not [System.IO.Path]::IsPathFullyQualified($env:BOTNEXUS_REPO_ROOT) -or
    -not (Test-Path -LiteralPath (Join-Path $env:BOTNEXUS_REPO_ROOT 'Directory.Packages.props'))) {
    throw 'Supply an existing isolated BotNexus checkout before building.'
}
```

Bash (replace the example with your isolated checkout):

```bash
export BOTNEXUS_REPO_ROOT="$HOME/src/botnexus-extension-build"
```

You can instead pass `-BotNexusRepoRoot` to each PowerShell script. The build fails with the resolved path when it is absent or not a BotNexus checkout.

Pin the BotNexus revision used by CI and releases to the **exact compatible revision of the installed host**. The contract is source-based today; a moving checkout can introduce incompatibility without changing this repository. Project references can build referenced BotNexus projects, so never point these scripts at a running installation's source tree.

## Build and test

Run from your extension checkout after selecting the isolated BotNexus checkout above:

```powershell
./scripts/Build.ps1
./scripts/Test.ps1
```

Bash:

```bash
./scripts/build.sh
./scripts/test.sh
```

The tests instantiate the actual tool, cross its argument-validation boundary, and verify its model-facing JSON schema.

## Package

```powershell
./scripts/Package.ps1
```

The package is written to:

```text
artifacts/extensions/botnexus-reference/
```

The folder contains the manifest, entry assembly, dependency closure, and runtime assets. `CopyLocalLockFileAssemblies=true` is required because each extension loads in its own `AssemblyLoadContext`.

## Register and sync a trusted repository

These are **operator-run examples**, not instructions to run installation during a documentation change. Review your fork, its dependencies, and an immutable commit before registering it. Do not substitute a moving branch for the approved commit.

Before sync, the operator must provision a separate BotNexus build checkout at the source location the CLI actually resolves:

1. Start at `<OS user-profile>/botnexus` and walk upward for `Directory.Packages.props`.
2. If no marker is found there, start at the CLI application's base directory and walk its ancestors for the same marker.
3. If neither search finds a marker, the unresolved profile path is used; stop and provision a valid checkout instead of assuming sync will find one.

`extensions sync` does **not** accept `--source`, and the template's `BOTNEXUS_REPO_ROOT` environment variable does **not** override this resolution. `--target` selects the runtime home, not the build source. Confirm which marker wins and that its checkout matches the installed host's exact compatible revision. Provisioning this separate build checkout is an operator prerequisite; do not update, rebuild, or repurpose the running gateway's source tree to satisfy it. Sync can also deploy in-tree outputs from the resolved checkout, so review the entire target deployment, not just this sample.

Select an explicit runtime home, reviewed fork URL, and approved immutable commit. The empty variables deliberately require operator input:

```powershell
$ErrorActionPreference = 'Stop'
$botNexusHome = Read-Host 'Absolute BotNexus runtime home to manage'
$trustedForkUrl = Read-Host 'Reviewed HTTPS Git URL of your trusted fork'
$approvedImmutableRef = Read-Host 'Approved full 40-character Git commit SHA'
$repositoryId = 'reference-extension' # Registration ID; distinct from manifest ID.

if ([string]::IsNullOrWhiteSpace($botNexusHome) -or
    -not [System.IO.Path]::IsPathFullyQualified($botNexusHome) -or
    -not (Test-Path -LiteralPath $botNexusHome -PathType Container)) {
    throw 'Select an existing absolute runtime home.'
}
if ([string]::IsNullOrWhiteSpace($trustedForkUrl) -or
    $trustedForkUrl -notmatch '^https://[^/]+/.+' -or
    $trustedForkUrl -match '[<>]' -or
    $approvedImmutableRef -notmatch '^[0-9a-fA-F]{40}$') {
    throw 'Supply a reviewed fork URL and approved immutable commit, not placeholders.'
}

function Invoke-BotNexusCli {
    param([Parameter(Mandatory)][string[]] $CliArguments)
    & botnexus @CliArguments --target $botNexusHome
    if ($LASTEXITCODE -ne 0) {
        throw "BotNexus CLI failed with exit code $LASTEXITCODE."
    }
}

Invoke-BotNexusCli -CliArguments @('extensions', 'add', '--id', $repositoryId,
    '--url', $trustedForkUrl, '--ref', $approvedImmutableRef, '--no-updates')
Invoke-BotNexusCli -CliArguments @('extensions', 'sync')
Invoke-BotNexusCli -CliArguments @('extensions', 'list')
```

Run `add` once for a new registration; use `extensions update` for an existing registration after reviewing its replacement revision. `--no-updates` disables automatic fetching for an existing managed clone; a missing clone still needs initial materialization. Sync processes all enabled registrations, builds and deploys them; it is not a metadata-only operation or a dry run. Review its exit status and diagnostics. `list` reports registrations, not proof that assemblies loaded. Dirty or divergent managed clones require operator resolution rather than destructive reset or cleanup. Loading changed compiled code requires an operator-managed gateway restart; this README does not perform or automate gateway lifecycle actions.

## Disposable local development install

Use `Install-Local.ps1` only with a disposable development home. It packages the extension and replaces `<BotNexusHome>/extensions/botnexus-reference`; it does not create a durable repository registration. Even `-WhatIf` invokes packaging before previewing the copy. Its lifecycle warnings predate registered sync; use the registered route above for durable ownership.

Do not overwrite a directory in use by a gateway. The operator is responsible for making the disposable environment safe before copying and for any subsequent restart. The script deliberately does not stop or restart BotNexus.

```powershell
$developmentHome = Read-Host 'Absolute path to a disposable BotNexus development home'
if ([string]::IsNullOrWhiteSpace($developmentHome) -or
    -not [System.IO.Path]::IsPathFullyQualified($developmentHome)) {
    throw 'Select a disposable development home, not a production installation.'
}
./scripts/Install-Local.ps1 -BotNexusHome $developmentHome -WhatIf
# Only after reviewing the preview and making that environment safe:
./scripts/Install-Local.ps1 -BotNexusHome $developmentHome
```

## Configure an agent

The sample has **no secrets or extension-specific settings**. `ReferenceEchoTool` does not read configuration, and its manifest has an empty `configSchema`. Do not add a made-up per-agent `enabled` setting: the manifest's `enabled` flag is a loader control, not sample per-agent configuration. Grant the tool through the intended agent's `toolIds`.

Use `botnexus config get` and `botnexus config set` rather than editing `config.json` or SQLite directly. These commands use the supported configuration read/write path for both JSON-only and SQLite-backed homes. A direct JSON edit can be shadowed by the store. The JSON below is a CLI value payload, not an instruction to modify a storage file.

Run in PowerShell **7.3 or later**, with an explicit home and named agent. The helper checks native exit codes because `$ErrorActionPreference` alone does not reliably stop a failed native command. Capture stdout only for JSON; do not merge stderr or enable verbose output.

```powershell
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion -lt [version]'7.3') {
    throw 'Use PowerShell 7.3 or later.'
}
$PSNativeCommandArgumentPassing = 'Standard'
$botNexusHome = Read-Host 'Absolute BotNexus runtime home to configure'
$agentId = Read-Host 'Existing named agent ID (not defaults)'
if ([string]::IsNullOrWhiteSpace($botNexusHome) -or
    -not [System.IO.Path]::IsPathFullyQualified($botNexusHome) -or
    -not (Test-Path -LiteralPath $botNexusHome -PathType Container) -or
    [string]::IsNullOrWhiteSpace($agentId) -or
    $agentId -eq 'defaults' -or $agentId -notmatch '^[a-zA-Z0-9_-]+$') {
    throw 'Supply an existing absolute runtime home and a concrete named agent ID.'
}

function Invoke-BotNexusCli {
    param([Parameter(Mandatory)][string[]] $CliArguments)
    & botnexus @CliArguments --target $botNexusHome
    if ($LASTEXITCODE -ne 0) {
        throw "BotNexus CLI failed with exit code $LASTEXITCODE."
    }
}

$agentJson = (Invoke-BotNexusCli -CliArguments @('config', 'get', "agents.$agentId")) -join [Environment]::NewLine
if ([string]::IsNullOrWhiteSpace($agentJson)) { throw 'Agent read returned no JSON.' }
$agent = ConvertFrom-Json -InputObject $agentJson -AsHashtable -ErrorAction Stop
if ($agent -isnot [System.Collections.IDictionary]) { throw 'Named agent must exist and be an object.' }

$existingTools = @($agent['toolIds'])
if ($null -eq $agent['toolIds'] -or $existingTools.Count -eq 0 -or
    @($existingTools | Where-Object {
        $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) -or $_ -match '[*?\[\]]'
    }).Count -gt 0) {
    throw 'Stop: null, empty, or wildcard tool policy needs an explicit operator decision. Nothing was written.'
}

# Preserve every existing entry; append only if absent. Never replace with a sample-only list.
if ($existingTools -notcontains 'reference_echo') {
    $mergedTools = @($existingTools) + @('reference_echo')
    $toolIdsJson = ConvertTo-Json -InputObject $mergedTools -Compress -Depth 100
    Invoke-BotNexusCli -CliArguments @('config', 'set', "agents.$agentId.toolIds", $toolIdsJson)
}
Invoke-BotNexusCli -CliArguments @('config', 'get', "agents.$agentId.toolIds")
```

The merge is idempotent and changes only `toolIds`; existing agent fields and tools are not replaced. If the guard stops, first decide the intended policy: retain the existing unrestricted/wildcard policy without this merge, or deliberately establish a complete reviewed explicit allow-list through the CLI. Do not convert a null, empty, or wildcard list into `['reference_echo']` just to make the sample work. Avoid concurrent writers during a read/modify/write; the CLI write lock is not a compare-and-swap over your earlier read.

### When your implementation adds settings

This is future-author guidance, **not additional configuration required by the sample**:

- Declare the supported `configurationScopes` (`world`, `gateway`, and/or `agent`) and real fields in the manifest's `configSchema`.
- Read named-agent settings through that agent's `ExtensionConfig` bag, keyed by manifest ID. Implement the binding in your code; declaring a schema does not make `ReferenceEchoTool` consume settings.
- For world or gateway consumers, read the intended section from gateway `IConfiguration` (`world:extensions:<manifest-id>` or `gateway:extensions:<manifest-id>`).
- `world.extensions.<manifest-id>`, `gateway.extensions.<manifest-id>`, and `agents.<agent-id>.extensions.<manifest-id>` are **independent scopes**, not an inheritance chain. World and gateway settings do not implicitly flow into agents. If you consume agent-default settings too, define precedence explicitly. The old `gateway.extensions.defaults` shape is obsolete and rejected; it is not world configuration.

For a future configured extension, use the helper and selected home/agent above to read and modify the **whole `extensions` object**. This preserves other extension entries and the selected entry's other fields; arbitrary nested settings should not be assumed to be individually addressable CLI keys. The prompts deliberately have no sample setting defaults:

```powershell
# Future implementations only, after their manifest and consumer declare these settings.
$manifestId = Read-Host 'Your configured extension manifest ID'
$fieldId = Read-Host 'A real declared configSchema field ID'
$rawFieldValue = Read-Host 'Reviewed field value as JSON (do not enter secrets here)'
if ($manifestId -notmatch '^botnexus-[a-z0-9-]+$' -or
    $manifestId -eq 'botnexus-reference' -or [string]::IsNullOrWhiteSpace($fieldId)) {
    throw 'Use your configured implementation and a real declared field, not the setting-free sample.'
}
$fieldValue = ConvertFrom-Json -InputObject $rawFieldValue -AsHashtable -ErrorAction Stop
$extensionsKey = "agents.$agentId.extensions"
# For a declared world/gateway consumer, deliberately select 'world.extensions' or 'gateway.extensions' instead.
$extensionsJson = (Invoke-BotNexusCli -CliArguments @('config', 'get', $extensionsKey)) -join [Environment]::NewLine
if ([string]::IsNullOrWhiteSpace($extensionsJson)) { throw 'Extensions read returned no JSON.' }
$extensions = ConvertFrom-Json -InputObject $extensionsJson -AsHashtable -ErrorAction Stop
if ($null -eq $extensions) { $extensions = @{} }
if ($extensions -isnot [System.Collections.IDictionary]) { throw 'Extensions must be an object.' }
if (-not $extensions.Contains($manifestId) -or $null -eq $extensions[$manifestId]) {
    $extensions[$manifestId] = @{}
}
if ($extensions[$manifestId] -isnot [System.Collections.IDictionary]) {
    throw 'Existing extension settings must be an object; do not overwrite them.'
}
$extensions[$manifestId][$fieldId] = $fieldValue
$updatedExtensionsJson = ConvertTo-Json -InputObject $extensions -Compress -Depth 100
Invoke-BotNexusCli -CliArguments @('config', 'set', $extensionsKey, $updatedExtensionsJson)
Invoke-BotNexusCli -CliArguments @('config', 'get', $extensionsKey)
```

Read [BotNexus extension development](https://sytone.dev/botnexus/extension-development) and verify the contracts against the source revision matching your host before adding configuration, endpoints, channels, hooks, or hosted services.

## Verify the installed extension

After an operator-managed gateway restart:

1. Read `GET /api/extensions/details` at the **actual authenticated gateway origin** used by your installation. Use its configured authentication/session; do not assume a localhost address, port, or unauthenticated endpoint. Confirm `botnexus-reference` loaded successfully and review its details.
2. Read the intended agent's available tools and confirm `reference_echo` appears.
3. Start a new test conversation and ask the agent to call `reference_echo` with `text: hello`.
4. Confirm the tool result is `hello`.
5. Review gateway logs for load, type-identity, or pruned-registration messages.

A directory on disk or a registry listing is not sufficient evidence. The extension must load, the tool must be granted to the agent, and the tool must be present in that conversation.

## Manifest contract

`botnexus-extension.json` is the runtime contract. Required fields are:

- `id`: unique, lowercase, normally `botnexus-<name>`.
- `name`: display name.
- `version`: semantic version by convention.
- `entryAssembly`: bare DLL filename in the extension directory.
- `extensionTypes`: one or more supported singular values such as `tool`, `channel`, `command`, `media-handler`, `endpoint-contributor`, or `api-contributor`.

The gateway discovers immediate child directories of its extension root. Each child must contain its own manifest and entry assembly. Extensions with settings must also declare their configuration scopes and schema.

## Security checklist

Before installing a trusted extension:

- Review every source and dependency change, including the approved immutable revision.
- Use least-privilege credentials and keep secrets out of the repository.
- Treat tool descriptions and schemas as security-sensitive model input.
- Validate arguments before any external effect.
- Apply file, network, and command policy at the real execution boundary.
- Bound time, concurrency, and output size.
- Do not log secrets or return them in tool results.
- Test failure paths and cancellation.

## Known limitations

- There is no stable published BotNexus extension SDK package yet; build against an exact compatible host checkout.
- Registered sync supports clone/build/deploy, but requires an operator-provisioned, correctly resolved build source and toolchain; it does not automatically grant tools to agents.
- Unregistered manual deployments are not durable lifecycle ownership and may be pruned.
- Extension unload leaves service registrations until process restart.
- Compiled extensions are trusted in-process code, not a sandbox.

For lifecycle implementation and history, see [BotNexus #3844](https://github.com/sytone/botnexus/issues/3844). Verify behavior against your installed host revision rather than relying on older metadata-only descriptions.
