
import 'package:flutter/material.dart';
import 'package:trashtagger/core/shared_widgets/home_screen.dart';
import 'package:trashtagger/main.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const AuthGate(),
  '/home': (context) => const HomeScreen(),
};
