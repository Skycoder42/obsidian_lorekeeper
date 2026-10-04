# obsidian_lorekeeper
An obisidian plugin to improve taking notes for and planning DnD sessions

## Building the project

Install the build tools with `npm install`, then build the plugin using
`npm run build`. Use `npm run dev` to rebuild automatically on changes.

The plugin is built to `main.js`, which together with `manifest.json` is
installed into a vault's `.obsidian/plugins/lorekeeper/` folder.

## Testing the plugin

Run `npm run test-vault` to create a test vault in `testing/PluginTestVault`
with the plugin installed and enabled. As the plugin files are symlinked, a
rebuild is picked up after reloading the plugin in obsidian.
