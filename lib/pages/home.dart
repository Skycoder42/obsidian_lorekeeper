import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/counter.dart';

class const Home({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => section([
    const img(src: 'images/logo.svg', width: 80),
    const h1([.text('Welcome')]),
    const p([.text('You successfully create a new Jaspr site.')]),
    div(styles: Styles(height: 100.px), const []),
    const Counter(),
  ]);
}
