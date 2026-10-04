import 'package:jaspr/dom.dart';

// As your CSS styles are defined using just Dart, you can simply
// use global variables or methods for common things like colors.
const primaryColor = Color('#01589B');

// Defines the global CSS styles for this project.
//
// The styles are scoped to the app, as they are loaded globally into obsidian.
@css
List<StyleRule> get styles => [
  css('.main h1').styles(margin: .unset, fontSize: 4.rem),
];
