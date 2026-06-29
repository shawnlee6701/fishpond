#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

rm -rf web
mkdir -p web
godot --headless --log-file /private/tmp/fish_pool_web_export.log --path . --export-release Web web/index.html
