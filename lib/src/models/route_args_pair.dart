import 'package:flutter/animation.dart';
import 'package:seafarer/seafarer.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';

class RouteArgsPair {
  final String name;
  final BaseArguments? args;
  final List<SeafarerTransition>? transitions;
  final Duration? transitionDuration;
  final Curve? transitionCurve;
  final CustomSeafarerTransition? customTransition;

  RouteArgsPair(
    this.name, {
    this.args,
    this.transitions,
    this.transitionDuration,
    this.transitionCurve,
    this.customTransition,
  });
}
