@JS('__obsidian')
library;

import 'dart:js_interop';

import 'package:web/web.dart';

import 'app.dart';
import 'js_subclass.dart';
import 'plugin_manifest.dart';

typedef PluginFactory = Plugin Function(App app, PluginManifest manifest);

@JS('Plugin')
external JSFunction get _pluginClass;

/// Creates a JS constructor that can be default-exported as obsidian plugin.
///
/// When obsidian instantiates it, [create] is called to construct the Dart
/// [Plugin] and its JS instance is returned.
JSFunction createPluginClass(PluginFactory create) =>
    ((App app, PluginManifest manifest) => create(app, manifest).js).toJS;

/// The JS instance of an obsidian `Plugin`.
@JS('Plugin')
extension type JSPlugin._(JSObject _) implements JSObject {
  external final App app;
  external final PluginManifest manifest;

  external HTMLElement addRibbonIcon(
    String icon,
    String title,
    JSFunction callback,
  );
}

/// Base class for obsidian plugins implemented in Dart.
///
/// Constructing a plugin creates a JS subclass instance of the obsidian
/// `Plugin`, available as [js], whose lifecycle methods call [onLoad] and
/// [onUnload].
abstract class Plugin(App app, PluginManifest manifest) {
  late final JSPlugin _js;

  this {
    _js = constructJSSubclass(_pluginClass, [
      app,
      manifest,
    ], (prototype) => createJSInteropWrapper<Plugin>(this, prototype));
  }

  JSPlugin get js => _js;

  App get app => _js.app;

  PluginManifest get manifest => _js.manifest;

  Future<void> onLoad() async {}

  @JSExport('onload')
  // ignore: unused_element called from JS via the export
  JSPromise<JSAny?> _onLoad() => onLoad().toJS;

  void onUnload() {}

  @JSExport('onunload')
  // ignore: unused_element called from JS via the export
  void _onUnload() => onUnload();

  HTMLElement addRibbonIcon(
    String icon,
    String title,
    void Function(MouseEvent evt) callback,
  ) => _js.addRibbonIcon(icon, title, callback.toJS);
}
