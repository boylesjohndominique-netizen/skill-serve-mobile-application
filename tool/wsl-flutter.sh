#!/usr/bin/env bash
# Run Flutter from WSL using the Windows Flutter SDK.
#
# The Windows SDK's shell entry point (bin/internal/shared.sh) has CRLF line
# endings, so calling `flutter` directly from WSL fails with
# "$'\r': command not found". Handing the command to Windows' cmd.exe runs the
# SDK the way it expects, from this project's directory.
#
# Usage: tool/wsl-flutter.sh analyze
#        tool/wsl-flutter.sh test test/booking_test.dart
#        tool/wsl-flutter.sh pub get
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v cmd.exe >/dev/null 2>&1; then
  echo "cmd.exe not found — this script is only for WSL. Use 'flutter' directly." >&2
  exit 1
fi

# Windows paths use backslashes; flutter accepts either, but test file paths
# read more naturally converted.
args=()
for arg in "$@"; do
  args+=("${arg//\//\\}")
done

exec cmd.exe /c "flutter ${args[*]}"
