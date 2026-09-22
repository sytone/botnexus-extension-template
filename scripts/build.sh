#!/usr/bin/env bash
set -euo pipefail
: "${BOTNEXUS_REPO_ROOT:?Set BOTNEXUS_REPO_ROOT to a BotNexus checkout}"
configuration="${CONFIGURATION:-Release}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dotnet build "$root/src/BotNexus.Extensions.Reference/BotNexus.Extensions.Reference.csproj" -c "$configuration" -p:BotNexusRepoRoot="$BOTNEXUS_REPO_ROOT"
