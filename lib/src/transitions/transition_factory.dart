import 'package:flutter/material.dart';
import 'package:seafarer/seafarer.dart';
import 'package:seafarer/src/transitions/base_transition_page_route.dart';
import 'package:seafarer/src/transitions/concrete_transition_component.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';
import 'package:seafarer/src/transitions/decorators/fade_in_transition_decorator.dart';
import 'package:seafarer/src/transitions/decorators/slide_bottom_transition_decorator.dart';
import 'package:seafarer/src/transitions/decorators/slide_left_transition_decorator.dart';
import 'package:seafarer/src/transitions/decorators/slide_right_transition_decorator.dart';
import 'package:seafarer/src/transitions/decorators/slide_top_transition_decorator.dart';
import 'package:seafarer/src/transitions/decorators/zoom_in_transition_decorator.dart';
import 'package:seafarer/src/transitions/seafarer_transition.dart';
import 'package:seafarer/src/transitions/transition_component.dart';

class TransitionFactory {
  static PageRoute buildTransition({
    RouteSettings? settings,
    WidgetBuilder? builder,
    Duration? duration,
    Curve? curve,
    List<SeafarerTransition>? transitions,
    CustomSeafarerTransition? customTransition,
  }) {
    TransitionComponent transitionComponent = ConcreteTransitionComponent();

    transitions?.forEach((transition) {
      switch (transition) {
        case SeafarerTransition.slide_from_left:
          transitionComponent = SlideLeftTransitionDecorator(
              transitionComponent: transitionComponent);
          break;
        case SeafarerTransition.slide_from_bottom:
          transitionComponent = SlideDownTransitionDecorator(
              transitionComponent: transitionComponent);
          break;
        case SeafarerTransition.slide_from_top:
          transitionComponent = SlideTopTransitionDecorator(
              transitionComponent: transitionComponent);
          break;
        case SeafarerTransition.slide_from_right:
          transitionComponent = SlideRightTransitionDecorator(
              transitionComponent: transitionComponent);
          break;
        case SeafarerTransition.zoom_in:
          transitionComponent = ZoomInTransitionDecorator(
              transitionComponent: transitionComponent);
          break;
        case SeafarerTransition.fade_in:
          transitionComponent = FadeInTransitionDecorator(
              transitionComponent: transitionComponent);
          break;
      }
    });

    return BaseTransitionPageRoute(
      settings: settings,
      builder: builder,
      transitionComponent: transitionComponent,
      duration: duration,
      curve: curve,
      useDefaultPageTransition: transitions == null || transitions.isEmpty,
      customTransition: customTransition,
    );
  }
}
