import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';
import 'package:seafarer/src/transitions/seafarer_transition.dart';

/// Options to configure a seafarer instance.
class SeafarerOptions {
  final bool handleNameNotFoundUI;

  /// Should display logs in console. seafarer prints some useful logs
  /// which can be helpful during development.
  ///
  /// By default logs are disabled i.e. value is set to [false].
  final bool isLoggingEnabled;

  /// Default transitions for all the routes.
  /// Whatever transitions are provided in this list will be
  /// applied to every page launched using seafarer.
  ///
  /// These transitions are overridden by default route transitions and
  /// transitions provided when routing using seafarer's navigate method.
  final List<SeafarerTransition>? defaultTransitions;

  /// Default duration for all the transitions.
  ///
  /// This duration is overridden by default route duration and duration
  /// provided when routing using seafarer's navigate method.
  final Duration? defaultTransitionDuration;

  /// Default curve for all the transitions.
  ///
  /// This curve is overridden by default route curve and curve
  /// provided when routing using seafarer's navigate method.
  final Curve? defaultTransitionCurve;

  /// Provide a custom transition to seafarer instead of using
  /// inbuilt transitions, if not provided, seafarer will revert
  /// to use its default transitions or delegate to system's own
  /// transitions.
  final CustomSeafarerTransition? customTransition;

  /// A navigator key lets seafarer grab the [NavigatorState] from a [MaterialApp]
  /// or a [CupertinoApp]. All navigation operations (push, pop, etc) are carried
  /// out using this [NavigatorState].
  ///
  /// This is the same [NavigatorState] that is returned by [Navigator.of(context)]
  /// (when there is only a single [Navigator] in Widget tree, i.e. from [MaterialApp]
  /// or [CupertinoApp]).
  final GlobalKey<NavigatorState>? navigatorKey;

  const SeafarerOptions({
    this.handleNameNotFoundUI = false,
    this.isLoggingEnabled = false,
    this.defaultTransitions,
    this.defaultTransitionDuration,
    this.defaultTransitionCurve,
    this.customTransition,
    this.navigatorKey,
  });
}
