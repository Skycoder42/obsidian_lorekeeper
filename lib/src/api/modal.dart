@JS('__obsidian')
library;

import 'dart:js_interop';

import 'package:web/web.dart';

import 'app.dart';

@JS()
extension type Modal._(JSObject _) implements JSObject {
  external factory(App app);

  external final App app;
  external final HTMLElement containerEl;
  external final HTMLElement modalEl;
  external final HTMLElement titleEl;
  external final HTMLElement contentEl;

  external void open();

  external void close();

  external Modal setTitle(String title);

  Modal setCloseCallback(void Function() callback) =>
      _setCloseCallback(callback.toJS);
  @JS('setCloseCallback')
  external Modal _setCloseCallback(JSFunction callback);
}
