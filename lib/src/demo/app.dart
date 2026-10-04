import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'components/counter.dart';
import 'constants/theme.dart' as theme;
import 'pages/about.dart';
import 'pages/home.dart';

// The main component of your application.
class const App({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => div(classes: 'main', [
    Style(
      styles: [
        ...theme.styles,
        ...styles,
        ...CounterState.styles,
        ...About.styles,
      ],
    ),
    const Home(),
    const About(),
  ]);

  // Defines the CSS styles for this component.
  //
  // Without the jaspr builder, the styles are not collected automatically, but
  // rendered by the [Style] component above instead.
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
