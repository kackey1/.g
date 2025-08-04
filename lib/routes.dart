import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';

class Routes {
  static const wrapper = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
}

final Map<String, WidgetBuilder> routes = {
  Routes.login: (_) => const LoginScreen(),
  Routes.signup: (_) => const SignupScreen(),
  Routes.home: (_) => const HomeScreen(),
};