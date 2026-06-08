#!/usr/bin/env bash
# Mirror plugin CI locally. Run from repo root: ./tool/ci_local.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Resolve dependencies"
dart pub get
for dir in plugins/LibreLink plugins/Nightscout plugins/MockCGM; do
  (cd "$dir" && dart pub get)
done

echo "==> Verify formatting"
dart format --output=none --set-exit-if-changed .

echo "==> Build plugins"
for plugin in MockCGM LibreLink Nightscout; do
  dart run tool/glucose_plugin.dart build --no-package "plugins/$plugin"
done

echo "==> Run tests"
dart test

resolve_platform_id() {
  case "$(uname -s)" in
    Linux) echo linux-x64 ;;
    Darwin)
      if [[ "$(uname -m)" == arm64 ]]; then
        echo darwin-arm64
      else
        echo darwin-x64
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*) echo windows-x64 ;;
    *) return 1 ;;
  esac
}

PLATFORM_ID="$(resolve_platform_id || true)"
if [[ -n "${PLATFORM_ID:-}" ]]; then
  echo "==> Protocol smoke (getPluginInfo) on $PLATFORM_ID"
  echo '{"command":"getPluginInfo"}' | "plugins/MockCGM/bin/$PLATFORM_ID/mock-cgm" | head -1 | grep -q '"success":true'
  echo '{"command":"getPluginInfo"}' | "plugins/LibreLink/bin/$PLATFORM_ID/librelink-plugin" | head -1 | grep -q '"librelink"'
  echo '{"command":"getPluginInfo"}' | "plugins/Nightscout/bin/$PLATFORM_ID/nightscout-plugin" | head -1 | grep -q '"nightscout"'
else
  echo "==> Protocol smoke skipped (unknown host OS)"
fi

echo "==> Plugin CI local checks passed"
