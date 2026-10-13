#!/usr/bin/env bash
# Encrypts a new portfolio build with the custom login page and writes it to portfolio/index.html.
# The light front page (index.html at the root) carries the link-preview tags and forwards visitors there.
#
# Usage (from the repository folder):
#   ./update-portfolio.sh ~/Downloads/portfolio-systems.html
#
# The password is asked for when you run it (or read from STATICRYPT_PASSWORD if set).
# The salt in .staticrypt.json is reused, so visitors who chose "Remember me" stay unlocked.
set -euo pipefail

SRC="${1:-}"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Give the unencrypted portfolio file, e.g. ./update-portfolio.sh ~/Downloads/portfolio-systems.html" >&2
  exit 1
fi
if [[ ! -f password_template.html ]]; then
  echo "password_template.html not found. Run this from the repository folder." >&2
  exit 1
fi

# StatiCrypt keeps the input's file name, so stage the build as index.html in a temporary folder.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$SRC" "$TMP/index.html"

npx --yes staticrypt@3.5.4 "$TMP/index.html" \
  --directory portfolio \
  --template password_template.html \
  --template-title "Pekka Puhakka · Portfolio" \
  --template-instructions "This portfolio includes client work shared in confidence. Enter the password you received with the link." \
  --template-button "Open portfolio" \
  --template-placeholder "Password" \
  --template-remember "Remember me on this device" \
  --template-error "That password didn't work. Check it and try again." \
  --template-toggle-show "Show" \
  --template-toggle-hide "Hide"

echo
echo "Done: portfolio/index.html is encrypted. Review, then commit and push:"
echo "  git add portfolio/index.html .staticrypt.json && git commit -m \"Portfolio update\" && git push"
