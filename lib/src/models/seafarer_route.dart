import 'package:seafarer/seafarer.dart';
import 'package:seafarer/src/models/base_arguments.dart';
import 'package:flutter/widgets.dart';
import 'package:seafarer/src/models/seafarer_param.dart';
import 'package:seafarer/src/models/seafarer_route_guard.dart';
import 'package:seafarer/src/seafarer.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';
import 'package:seafarer/src/transitions/seafarer_transition.dart';

typedef SeafarerRouteBuilder = Widget Function(
  BuildContext context,
  BaseArguments? args,
  ParamMap paramMap,
);

class SeafarerRoute {
  final String name;
  final SeafarerRouteBuilder builder;
  final BaseArguments? defaultArgs;
  final List<SeafarerTransition>? defaultTransitions;
  final Duration? defaultTransitionDuration;
  final Curve? defaultTransitionCurve;
  final List<SeafarerParam>? params;

  /// Ran before opening the route itself.
  /// If every route guard returns [true], the route is approvied and opened.
  /// Anything else will result in the route being rejected and not open.
  final List<SeafarerRouteGuard>? routeGuards;

  /// Provide a custom transition to seafarer instead of using
  /// inbuilt transitions, if not provided, seafarer will revert
  /// to use its default transitions or delegate to systems own
  /// transitions.
  final CustomSeafarerTransition? customTransition;

  const SeafarerRoute({
    required this.name,
    required this.builder,
    this.defaultArgs,
    this.defaultTransitions,
    this.defaultTransitionDuration,
    this.defaultTransitionCurve,
    this.params,
    this.customTransition,
    this.routeGuards,
  });
}
