#!/usr/bin/env bash
# Installs the PaperMod theme at a pinned commit (themes/PaperMod is gitignored).
# Used by both the Cloudflare Pages build and the GitHub Actions build, so a
# breaking upstream change can never fail a deploy. To upgrade the theme on
# purpose: change PAPERMOD_COMMIT, build locally, then push.
set -euo pipefail

PAPERMOD_COMMIT="d3768854d00ad003b0a8dbdba254ce9224377a01"
PAPERMOD_REPO="https://github.com/adityatelange/hugo-PaperMod.git"

cd "$(dirname "$0")/.."
rm -rf themes/PaperMod
mkdir -p themes/PaperMod
git -C themes/PaperMod init -q
git -C themes/PaperMod remote add origin "$PAPERMOD_REPO"
git -C themes/PaperMod fetch -q --depth 1 origin "$PAPERMOD_COMMIT"
git -C themes/PaperMod checkout -q FETCH_HEAD
echo "PaperMod pinned at $(git -C themes/PaperMod rev-parse --short HEAD)"
