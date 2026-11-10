#!/usr/bin/env bash
# Build the launcher with the local toolchain in tc/ (JDK 17, Android SDK 34, Gradle 8.9) and install it
# on this TV as Home. Run from the repo root:  TV_HOST=192.168.1.8 bash work/build-and-install-this-tv.sh
# The Zeasn launcher is already disabled, so STOCK_LAUNCHER=none: nothing else gets disabled.
# (tools/docker-build.sh also works, but its SDK download kept arriving corrupted on this connection.)
set -euo pipefail
cd "$(dirname "$0")/.."
: "${TV_HOST:?set TV_HOST to the TV IP, e.g. TV_HOST=192.168.1.8}"
export TV_HOST
ROOT="$(pwd -W 2>/dev/null || pwd)"
export JAVA_HOME="$ROOT/tc/jdkx/jdk-17.0.21+9" ANDROID_HOME="$ROOT/tc/sdk" ANDROID_SDK_ROOT="$ROOT/tc/sdk"
export PATH="$JAVA_HOME/bin:$PATH"
cd launcher
"$ROOT/tc/gradle-8.9/bin/gradle" --no-daemon --console=plain assembleRelease
SKIP_BUILD=1 STOCK_LAUNCHER="${STOCK_LAUNCHER:-none}" bash build-and-install.sh
