/// The entrypoint of the obsidian plugin.
///
/// Compiled to JavaScript by `esbuild.config.mjs`, which exports the plugin
/// class registered here to obsidian.
library;

import 'dart:js_interop';

import 'src/api/plugin.dart';
import 'src/lorekeeper_plugin.dart';

@JS('__lorekeeperPluginClass')
external set _lorekeeperPluginClass(JSFunction value);

void main() {
  _lorekeeperPluginClass = createPluginClass(LorekeeperPlugin.new);
}
