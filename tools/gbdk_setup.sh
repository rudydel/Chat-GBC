#!/usr/bin/env bash
# Download GBDK-2020 into tools/gbdk (Linux x86_64 by default).
# Usage: tools/gbdk_setup.sh [version] [platform]   e.g. 4.4.0 linux64 | macos | win64
set -euo pipefail
VERSION="${1:-4.4.0}"
PLATFORM="${2:-linux64}"
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -x "$DIR/gbdk/bin/lcc" ]; then
  echo "GBDK already installed at $DIR/gbdk"
  exit 0
fi
URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/${VERSION}/gbdk-${PLATFORM}.tar.gz"
echo "Downloading $URL"
curl -sSL -o "$DIR/gbdk.tar.gz" "$URL"
tar -xzf "$DIR/gbdk.tar.gz" -C "$DIR"
rm -f "$DIR/gbdk.tar.gz"
echo "GBDK installed at $DIR/gbdk"
