import 'package:flutter/material.dart';

class AppConfigScope extends InheritedWidget {
  final String appName;

  const AppConfigScope({
    super.key,
    required this.appName,
    required super.child,
  });

  static AppConfigScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfigScope>();
  }

  @override
  bool updateShouldNotify(AppConfigScope oldWidget) {
    return appName != oldWidget.appName;
  }
}
