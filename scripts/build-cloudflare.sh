#!/usr/bin/env bash
# Cloudflare Pages build entry point.
# Dashboard settings: Build command = bash scripts/build-cloudflare.sh
#                     Output directory = public
#                     Env var HUGO_VERSION = 0.147.9
set -euo pipefail

cd "$(dirname "$0")/.."
bash scripts/install-theme.sh
TZ=America/Los_Angeles hugo --gc --minify -b https://virtualizationgurus.pages.dev/
