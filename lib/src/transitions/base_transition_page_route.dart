import 'package:flutter/material.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';
import 'package:seafarer/src/transitions/transition_component.dart';

class BaseTransitionPageRoute extends PageRouteBuilder {
  final TransitionComponent transitionComponent;
  final Duration? duration;
  final Curve? curve;
  final bool useDefaultPageTransition;
  final CustomSeafarerTransition? customTransition;

  BaseTransitionPageRoute({
    required this.transitionComponent,
    required WidgetBuilder? builder,
    required RouteSettings? settings,
    this.duration,
    this.curve,
    this.useDefaultPageTransition = false,
    this.customTransition,
  })  : super(
            pageBuilder: (context, anim1, anim2) => builder!(context),
            settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (this.customTransition != null) {
      return this
          .customTransition!
          .buildTransition(context, animation, secondaryAnimation, child);
    }

    if (this.useDefaultPageTransition) {
      return Theme.of(context).pageTransitionsTheme.buildTransitions(
          this, context, animation, secondaryAnimation, child);
    }

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: this.curve ?? Curves.linear,
    );

    return transitionComponent.buildChildWithTransition(
        context, curvedAnimation, secondaryAnimation, child);
  }

  @override
  Duration get transitionDuration =>
      this.duration ?? Duration(milliseconds: 300);
}
