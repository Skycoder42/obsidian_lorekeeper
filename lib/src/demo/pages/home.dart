import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/counter.dart';
import '../logo.dart';

class const Home({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => section([
    img(src: logoDataUri, width: 80),
    const h1([.text('Welcome')]),
    const p([.text('You successfully create a new Jaspr site.')]),
    div(styles: Styles(height: 100.px), const []),
    const Counter(),
  ]);
}
