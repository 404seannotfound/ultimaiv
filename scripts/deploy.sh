#!/usr/bin/env bash
# Stage public assets and deploy to Cloudflare Pages via wrangler.
# Mirrors the ignitionfire_net pattern: env-driven, wrangler over npx, no
# global install required.
#
# usage:  scripts/deploy.sh
#
# Required in .env:
#   CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, PAGES_PROJECT

set -euo pipefail

cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found." >&2; exit 1; }
set -a; source .env; set +a
: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN not set in .env}"
: "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID not set in .env}"
: "${PAGES_PROJECT:?PAGES_PROJECT not set in .env}"

# --- Stage a clean dist/ with only the assets the public site needs ---
DIST="dist"
rm -rf "$DIST"
mkdir -p "$DIST"
cp index.html  "$DIST/"
cp _redirects  "$DIST/"
cp -R cards    "$DIST/"
cp -R scenes   "$DIST/"
cp -R audio    "$DIST/"
cp -R devlog   "$DIST/"

# /cards path needs its own index.html because the assets live under cards/.
# Without this Pages serves a directory listing (or 308s to /).
cp index.html  "$DIST/cards/index.html"

dist_size=$(du -sh "$DIST" | awk '{print $1}')
echo "staged $DIST/ (size: $dist_size)"

# --- Ensure the Pages project exists. wrangler will error out cleanly if it ---
#     already exists; we tolerate that and continue to deploy.
echo "ensuring Pages project '$PAGES_PROJECT' exists…"
npx --yes wrangler@latest pages project create "$PAGES_PROJECT" \
    --production-branch main 2>&1 | sed -E "s/$CLOUDFLARE_API_TOKEN/***REDACTED***/g" || \
  echo "  (project already exists — continuing)"

# --- Deploy ---
echo "deploying…"
npx --yes wrangler@latest pages deploy "$DIST" \
    --project-name "$PAGES_PROJECT" \
    --branch main \
    --commit-dirty=true 2>&1 | sed -E "s/$CLOUDFLARE_API_TOKEN/***REDACTED***/g"

echo "---"
echo "live URL (after DNS): ${PAGES_URL:-https://$PAGES_PROJECT.pages.dev/}"
