# CLAUDE.md

## Project

Obsidian Lorekeeper is an [Obsidian](https://obsidian.md) plugin written in
Dart. Its goal is to enhance Obsidian with improved handling of campaign
planning and session notes for tabletop RPGs.

Custom UI is rendered with [Jaspr](https://jaspr.site). Jaspr is only used as
a rendering library: there is no jaspr CLI, builder or `web/` folder. Apps are
mounted on demand into obsidian elements via `ClientAppBinding`, and component
styles are not collected via `@css` but must be rendered with a `Style`
component.

## Architecture

- `lib/main.dart` is the entry point. It registers the plugin class, which is
  exported to obsidian.
- `lib/src/api/` contains the JS interop bindings for the obsidian API. All
  bindings go there.
- `esbuild.config.mjs` compiles `lib/main.dart` with dart2js and bundles it as
  `main.js`. Its banner and footer provide the JS glue: they expose the
  obsidian module as `globalThis.__obsidian` (which the bindings use via
  `@JS('__obsidian')`) and export the plugin class.
- Build with `npm run build` (or `npm run dev` to watch).
  `npm run test-vault` creates a vault in `testing/` with the plugin installed.

## Obsidian API

The [Obsidian TypeScript API docs](https://docs.obsidian.md/Reference/TypeScript+API/Plugin)
are the source of truth for what plugins can do. The exact typings are in
`node_modules/obsidian/obsidian.d.ts` after `npm install`.

The bindings in `lib/src/api/` only cover what the plugin currently uses. Extend
them whenever you need more of the API, instead of working around missing
bindings. To subclass obsidian classes (e.g. `Plugin`), use
`constructJSSubclass` from `lib/src/api/js_subclass.dart`.

## Rules

- Use Dart dot-shorthands wherever possible, i.e. omit the type name when the
  context type is known: `.instance` instead of `EnumType.instance`.
- Prefer the dart MCP server whenever possible, especially `analyze_files` and
  `lsp` for source analysis and `read_package_uris`, `rip_grep_packages` and
  `pub_dev_search` for package introspection.
- When you're done, always format and analyze your changes: run `dart format .`
  from the repository root, then analyze via the dart MCP server's
  `analyze_files` — never the `dart analyze` CLI.
- Make use of the dart and jaspr specific skills to perform complex operations
  they can support.
