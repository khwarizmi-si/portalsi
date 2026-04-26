// lib/url_strategy_web.dart
// Web-only: removes the '#' hash from Flutter web URLs.
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void configureApp() {
  setUrlStrategy(PathUrlStrategy());
}
