/// Entrypoint for the jaspr builder to collect the `@css` styles of the plugin.
///
/// The builder generates a runner for all styles reachable from this library,
/// which is used by the esbuild config to create the `styles.css` loaded by
/// obsidian.
library;

export 'main.dart';
