# Contributing

## Development contract

1. Point `BOTNEXUS_REPO_ROOT` at the BotNexus revision this change targets.
2. Add or update tests before changing behavior.
3. Run `./scripts/Build.ps1` and `./scripts/Test.ps1`.
4. Run `./scripts/Package.ps1` and inspect `artifacts/extensions/botnexus-reference`.
5. Keep the manifest ID, entry assembly, project name, and namespace aligned.
6. Do not commit credentials, BotNexus binaries, build output, or local installation paths.

Compiled extensions run with full gateway trust. Changes that add filesystem, process, network, credential, or write behavior must document their permissions and failure boundaries in the README.
