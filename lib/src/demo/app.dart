import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'pages/about.dart';
import 'pages/home.dart';

// The main component of your application.
class const App({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) =>
      const div(classes: 'main', [Home(), About()]);

  // Defines the CSS styles for this component.
  @css
  static List<StyleRule> get styles => [
    css('.main', [
      // The '&' refers to the parent selector of a nested style rules.
      css('&').styles(display: .flex, flexDirection: .row, flexWrap: .wrap),
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
