import 'package:flutter/animation.dart';
import 'package:seafarer/src/models/base_arguments.dart';
import 'package:seafarer/src/models/seafarer_param.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';
import 'package:seafarer/src/transitions/seafarer_transition.dart';

class ArgumentsWrapper {
  final BaseArguments? baseArguments;
  final List<SeafarerTransition>? transitions;
  final Duration? transitionDuration;
  final Curve? transitionCurve;
  final Map<String, dynamic>? params;

  /// Route params that are initially defined for the Route.
  /// Note: These are needed here, because user must be able to retrieve
  /// params from within the launched route. Since the only thing available
  /// from inside a launched route are arguments, these paramters are provided
  /// along with the arguments.
  final Map<String, SeafarerParam>? routeParams;

  final CustomSeafarerTransition? customTransition;

  ArgumentsWrapper({
    this.baseArguments,
    this.transitions,
    this.transitionDuration,
    this.transitionCurve,
    this.params,
    this.routeParams,
    this.customTransition,
  });

  ArgumentsWrapper copyWith({
    BaseArguments? baseArguments,
    List<SeafarerTransition>? transitions,
    Duration? transitionDuration,
    Curve? transitionCurve,
    List<SeafarerParam>? params,
    Map<String, SeafarerParam>? routeParams,
    CustomSeafarerTransition? customTransition,
  }) {
    return ArgumentsWrapper(
      baseArguments: baseArguments ?? this.baseArguments,
      transitions: transitions ?? this.transitions,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionCurve: transitionCurve ?? this.transitionCurve,
      params: params as Map<String, dynamic>? ?? this.params,
      routeParams: routeParams ?? this.routeParams,
      customTransition: customTransition ?? this.customTransition,
    );
  }

  @override
  String toString() {
    return 'ArgumentsWrapper{baseArguments: $baseArguments, '
        'transitions: $transitions, '
        'transitionDuration: $transitionDuration, '
        'transitionCurve: $transitionCurve}, '
        'params: $params, '
        'customTransition: $customTransition';
  }
}
