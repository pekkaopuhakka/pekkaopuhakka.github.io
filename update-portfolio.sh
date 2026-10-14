#!/usr/bin/env bash
# Encrypts one lens of the portfolio with its own password, and registers it with the front page.
#
# Usage (from the repository folder):
#   bash update-portfolio.sh systems  ~/Downloads/portfolio-systems.html
#   bash update-portfolio.sh services ~/Downloads/portfolio-services.html
#
# Each lens gets its own folder (systems/, services/) and its own password. The front page (index.html)
# sends each visitor to the lens their password opens. The salt in .staticrypt.json is shared by all lenses.
set -euo pipefail

LENS="${1:-}"; SRC="${2:-}"
if [[ ! "$LENS" =~ ^[a-z0-9-]+$ || -z "$SRC" || ! -f "$SRC" ]]; then
  echo "Usage: bash update-portfolio.sh <lens> <unencrypted file>   e.g. bash update-portfolio.sh systems ~/Downloads/portfolio-systems.html" >&2
  exit 1
fi
for f in password_template.html lens-fingerprint.js index.html; do
  [[ -f "$f" ]] || { echo "$f not found. Run this from the repository folder." >&2; exit 1; }
done

if [[ -z "${STATICRYPT_PASSWORD:-}" ]]; then
  # IFS= keeps the password exactly as typed or pasted, including any leading or trailing spaces
  IFS= read -r -s -p "Password for the '$LENS' lens: " STATICRYPT_PASSWORD; echo
  IFS= read -r -s -p "Once more: " AGAIN; echo
  [[ "$STATICRYPT_PASSWORD" == "$AGAIN" ]] || { echo "The passwords didn't match." >&2; exit 1; }
fi
export STATICRYPT_PASSWORD

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SRC" "$TMP/index.html"

npx --yes staticrypt@3.5.4 "$TMP/index.html" --short \
  --directory "$LENS" \
  --template password_template.html \
  --template-title "Pekka Puhakka · Portfolio" \
  --template-instructions "This portfolio includes client work shared in confidence. Enter the password you received with the link." \
  --template-button "Open portfolio" \
  --template-placeholder "Password" \
  --template-remember "Remember me on this device" \
  --template-error "That password didn't work. Check it and try again." \
  --template-toggle-show "Show" \
  --template-toggle-hide "Hide"

node lens-fingerprint.js "$LENS"

# Old links to /portfolio/ keep working: they forward to the front page.
mkdir -p portfolio
cat > portfolio/index.html <<'HTML'
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Pekka Puhakka · Portfolio</title>
<meta name="googlebot" content="noindex, nofollow"><meta name="bingbot" content="noindex, nofollow">
<script>location.replace("../" + location.hash);</script></head>
<body><p><a href="../">Open Pekka Puhakka’s portfolio</a></p></body></html>
HTML

echo
echo "Done: $LENS/index.html is encrypted and registered. Review, then commit and push in GitHub Desktop:"
echo "  $LENS/index.html, lenses.json, portfolio/index.html (and index.html, .staticrypt.json if new)"
