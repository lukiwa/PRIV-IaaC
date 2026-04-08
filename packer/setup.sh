#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v op &>/dev/null; then
  echo "Error: 1Password CLI (op) not found." >&2
  exit 1
fi

echo "Injecting secrets from 1Password..."

while IFS= read -r -d '' example; do
  target="${example%.example}"
  echo "  ${example#"$SCRIPT_DIR/"} -> ${target#"$SCRIPT_DIR/"}"
  op inject -i "$example" -o "$target"
done < <(find "$SCRIPT_DIR" -name "secrets.pkr.hcl.example" -print0 | sort -z)

echo "Done."
