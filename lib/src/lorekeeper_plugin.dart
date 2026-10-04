import 'package:jaspr/client.dart';
import 'package:web/web.dart' hide Plugin;

import 'api/modal.dart';
import 'api/plugin.dart';
import 'demo/app.dart';

class LorekeeperPlugin(super.app, super.manifest) extends Plugin {
  @override
  Future<void> onLoad() async {
    addRibbonIcon('scroll-text', 'Open Lorekeeper', (_) => _openDemo());
  }

  void _openDemo() {
    final modal = Modal(app)..setTitle('Lorekeeper');

    // Renders between two markers, as the content element is not yet part of
    // the document and thus cannot be found by a selector.
    final start = Comment('lorekeeper-start');
    final end = Comment('lorekeeper-end');
    modal.contentEl
      ..append(start)
      ..append(end);
    final binding = ClientAppBinding()
      ..attachRootComponent(const App(), attachBetween: (start, end));

    modal
      ..setCloseCallback(binding.detachRootComponent)
      ..open();
  }
}
