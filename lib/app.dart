import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'pages/about.dart';
import 'pages/home.dart';

// The main component of your application.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) =>
      const div(classes: 'main', [Home(), About()]);

  // Defines the CSS styles for this component.
  //
  // By using the @css annotation, these will be rendered automatically to CSS
  // and included in your page.
  // Must be a variable or getter of type [List<StyleRule>].
  @css
  static List<StyleRule> get styles => [
    css('.main', [
      // The '&' refers to the parent selector of a nested style rules.
      css('&').styles(
        display: .flex,
        height: 100.vh,
        flexDirection: .row,
        flexWrap: .wrap,
      ),
      css('section').styles(
        display: .flex,
        flexDirection: .column,
        justifyContent: .center,
        alignItems: .center,
        flex: Flex(grow: 1, shrink: 0, basis: 400.px),
      ),
    ]),
  ];
}
