#!/usr/bin/env bash
# Creates an Obsidian vault for manual testing with this plugin installed and
# enabled. The plugin files are symlinked, so rebuilds are picked up after
# reloading the plugin in Obsidian.
#
# Usage: tool/create-test-vault.sh [vault-dir]
# Default vault-dir: <repo>/testing/PluginTestVault
set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vault_dir="${1:-$plugin_dir/testing/PluginTestVault}"
plugin_id="$(node -p 'require(process.argv[1]).id' "$plugin_dir/manifest.json")"

if [[ ! -f "$plugin_dir/main.js" ]]; then
  echo "main.js not found, building plugin..."
  (cd "$plugin_dir" && npm run build)
fi

mkdir -p "$vault_dir"
vault_dir="$(cd "$vault_dir" && pwd)"
config_dir="$vault_dir/.obsidian"
install_dir="$config_dir/plugins/$plugin_id"
mkdir -p "$install_dir"

for file in main.js manifest.json styles.css; do
  if [[ -f "$plugin_dir/$file" ]]; then
    ln -sfn "$plugin_dir/$file" "$install_dir/$file"
  fi
done

# Enables the plugin. Existing configuration is kept so the script can be rerun.
if [[ ! -f "$config_dir/community-plugins.json" ]]; then
  printf '[\n  "%s"\n]\n' "$plugin_id" > "$config_dir/community-plugins.json"
fi

if [[ ! -f "$vault_dir/Welcome.md" ]]; then
  cat > "$vault_dir/Welcome.md" << 'EOF'
# Plugin test vault

Click the scroll icon in the left ribbon to check the plugin is loaded.
EOF
fi

echo "Test vault ready: $vault_dir"
echo "Open it in Obsidian via 'Open folder as vault' and choose 'Trust author and enable plugins'."
