import 'package:flutter/material.dart';

/// Extend this class to provide seafarer with a custom transtion.
abstract class CustomSeafarerTransition {
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}
