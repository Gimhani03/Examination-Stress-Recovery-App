import 'package:flutter/material.dart';

/// Root [Navigator] key so notification taps can push routes without a [BuildContext].
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
