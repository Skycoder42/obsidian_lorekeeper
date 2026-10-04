import 'dart:js_interop';

@JS()
extension type PluginManifest._(JSObject _) implements JSObject {
  external final String? dir;
  external final String id;
  external final String name;
  external final String author;
  external final String version;
  external final String minAppVersion;
  external final String description;
  external final String? authorUrl;
  external final bool? isDesktopOnly;
}
