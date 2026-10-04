# obsidian_lorekeeper
An obisidian plugin to improve taking notes for and planning DnD sessions

## Building the project

Install the build tools with `npm install` and run the dart code generation via
`dart run build_runner watch`. Then build the plugin using `npm run build`, or
use `npm run dev` to rebuild automatically on changes.

The plugin is built to `main.js` and `styles.css`, which together with
`manifest.json` are
installed into a vault's `.obsidian/plugins/lorekeeper/` folder.

## Testing the plugin

Run `npm run test-vault` to create a test vault in `testing/PluginTestVault`
with the plugin installed and enabled. As the plugin files are symlinked, a
rebuild is picked up after reloading the plugin in obsidian.
