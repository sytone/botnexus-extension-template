#!/usr/bin/env bash
set -euo pipefail
: "${BOTNEXUS_REPO_ROOT:?Set BOTNEXUS_REPO_ROOT to a BotNexus checkout}"
configuration="${CONFIGURATION:-Release}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dotnet test "$root/tests/BotNexus.Extensions.Reference.Tests/BotNexus.Extensions.Reference.Tests.csproj" -c "$configuration" -p:BotNexusRepoRoot="$BOTNEXUS_REPO_ROOT" --nologo
