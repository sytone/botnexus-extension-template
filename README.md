# BotNexus extension template

Fork this repository to build a compiled BotNexus extension outside the main BotNexus repository.

The sample supplies one deterministic tool, `reference_echo`. It is intentionally small so the repository demonstrates the extension boundary rather than hiding it under application code.

> [!IMPORTANT]
> Compiled extensions run in the BotNexus gateway process with the gateway's full operating-system permissions. Only install code you trust and have reviewed.

## Current platform status

BotNexus can load a compiled extension from its extensions directory. Repository registration currently records source metadata only; it does not yet clone, build, deploy, or update the repository. Until [BotNexus issue #3844](https://github.com/sytone/botnexus/issues/3844) is complete, use the build, test, package, and local-install scripts in this repository.

A manually installed extension can be removed as stale by a later `botnexus serve`, gateway deployment, or platform update because current deployment discovers owned extension IDs only under the main repository's `src/extensions` tree. Keep the source repository and package output so you can reinstall it.

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
- A local BotNexus checkout. The extension references BotNexus projects until extension SDK packages are published.
- PowerShell 7 for the complete build/package/install workflow. Bash wrappers are included for build and test.

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

Set `BOTNEXUS_REPO_ROOT` to the root of a BotNexus checkout.

PowerShell:

```powershell
$env:BOTNEXUS_REPO_ROOT = 'Q:/repos/botnexus'
```

Bash:

```bash
export BOTNEXUS_REPO_ROOT="$HOME/src/botnexus"
```

You can instead pass `-BotNexusRepoRoot` to each PowerShell script. The build fails with the resolved path when it is absent or not a BotNexus checkout.

Pin the BotNexus revision used by your CI and release process. The extension contract is source-based today, so an unpinned moving checkout can introduce breaking changes without changing this repository.

## Build and test

PowerShell:

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

## Install into a local BotNexus environment

Stop active work before restarting the gateway. Do not overwrite an extension directory while the gateway is using it.

Preview the install:

```powershell
./scripts/Install-Local.ps1 -WhatIf
```

Install to the default `~/.botnexus` home:

```powershell
./scripts/Install-Local.ps1
```

Install to another BotNexus home:

```powershell
./scripts/Install-Local.ps1 -BotNexusHome 'C:/path/to/botnexus-home'
```

The script replaces only `<BotNexusHome>/extensions/botnexus-reference`. Restart the gateway yourself after the copy. The script deliberately does not stop or restart BotNexus.

## Configure an agent

The sample tool has no secrets or extension-specific settings. Add its tool name to the intended agent's `toolIds`, preserving the agent's existing tools:

```json
{
  "agents": {
    "my-agent": {
      "toolIds": [
        "reference_echo"
      ]
    }
  }
}
```

If your extension uses per-agent settings, place them under the manifest ID in the agent's `extensions` object:

```json
{
  "agents": {
    "my-agent": {
      "extensions": {
        "botnexus-reference": {
          "enabled": true
        }
      }
    }
  }
}
```

World-level defaults use `gateway.extensions.defaults.<manifest-id>`. Read [BotNexus extension development](https://sytone.dev/botnexus/extension-development) before adding configuration, endpoints, channels, hooks, or hosted services.

## Verify the installed extension

After restarting BotNexus:

1. Read `GET /api/extensions` and confirm `botnexus-reference` loaded successfully.
2. Read the intended agent's available tools and confirm `reference_echo` appears.
3. Start a new test conversation and ask the agent to call `reference_echo` with `text: hello`.
4. Confirm the tool result is `hello`.
5. Review gateway logs for load, type-identity, or pruned-registration messages.

A directory on disk is not sufficient evidence. The extension must load, the tool must be granted to the agent, and the tool must be present in that conversation.

## Manifest contract

`botnexus-extension.json` is the runtime contract. Required fields are:

- `id`: unique, lowercase, normally `botnexus-<name>`.
- `name`: display name.
- `version`: semantic version by convention.
- `entryAssembly`: bare DLL filename in the extension directory.
- `extensionTypes`: one or more supported singular values such as `tool`, `channel`, `command`, `media-handler`, `endpoint-contributor`, or `api-contributor`.

The gateway discovers immediate child directories of its extension root. Each child must contain its own manifest and entry assembly.

## Security checklist

Before installing an internal extension:

- Review every source and dependency change.
- Use least-privilege credentials and keep secrets out of the repository.
- Treat tool descriptions and schemas as security-sensitive model input.
- Validate arguments before any external effect.
- Apply file, network, and command policy at the real execution boundary.
- Bound time, concurrency, and output size.
- Do not log secrets or return them in tool results.
- Test failure paths and cancellation.

## Known limitations

- There is no stable published BotNexus extension SDK package yet.
- The repository-registration CLI does not yet clone/build/deploy registered repositories.
- Manually deployed external extensions are not protected from current stale-extension pruning.
- Extension unload leaves service registrations until process restart.
- Compiled extensions are trusted in-process code, not a sandbox.

Track the supported repository lifecycle in [BotNexus #3844](https://github.com/sytone/botnexus/issues/3844).
