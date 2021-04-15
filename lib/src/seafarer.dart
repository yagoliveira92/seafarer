import 'package:seafarer/src/errors/param_not_provided.dart';
import 'package:seafarer/src/errors/param_not_registered.dart';
import 'package:seafarer/src/errors/route_not_found.dart';
import 'package:flutter/material.dart';
import 'package:seafarer/src/logger/app_logger.dart';
import 'package:seafarer/src/models/arguments_wrapper.dart';
import 'package:seafarer/src/models/base_arguments.dart';
import 'package:seafarer/src/models/seafarer_options.dart';
import 'package:seafarer/src/models/seafarer_param.dart';
import 'package:seafarer/src/models/seafarer_route.dart';
import 'package:seafarer/src/models/seafarer_route_guard.dart';
import 'package:seafarer/src/navigator_observers/seafarer_stack_observer.dart';
import 'package:seafarer/src/transitions/custom_seafarer_transition.dart';
import 'package:seafarer/src/transitions/seafarer_transition.dart';
import 'package:seafarer/src/transitions/transition_factory.dart';
import 'package:seafarer/src/ui/page_not_found.dart';
import 'models/route_args_pair.dart';

enum NavigationType { push, pushReplace, pushAndRemoveUntil, popAndPushNamed }

/// seafarer manages routing, registering routes with transitions, navigating to
/// routes, closing routes. It is a thin layer on top of [Navigator] to help
/// you encapsulate and manage routing at one place.
class Seafarer {
  Seafarer({
    this.options = const SeafarerOptions(isLoggingEnabled: true),
  }) {
    AppLogger.init(isLoggerEnabled: options.isLoggingEnabled);
    if (options.navigatorKey != null) {
      this._navigatorKey = options.navigatorKey;
    } else {
      this._navigatorKey = GlobalKey<NavigatorState>();
    }
  }

  /// Configuration options for [seafarer].
  ///
  /// Check out [seafarerOptions] for available options.
  final SeafarerOptions options;

  /// Store all the mappings of route names and corresponding [SeafarerRoute]
  /// Used to generate routes
  Map<String, SeafarerRoute> _routeNameMappings = {};

  /// Store all the mappings of route names and corresponding [SeafarerParam]s
  Map<String, Map<String, SeafarerParam>> _routeParamsMappings = {};

  /// A navigator key lets seafarer grab the [NavigatorState] from a [MaterialApp]
  /// or a [CupertinoApp]. All navigation operations (push, pop, etc) are carried
  /// out using this [NavigatorState].
  ///
  /// This is the same [NavigatorState] that is returned by [Navigator.of(context)]
  /// (when there is only a single [Navigator] in Widget tree, i.e. from [MaterialApp]
  /// or [CupertinoApp]).
  GlobalKey<NavigatorState>? _navigatorKey;

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  SeafarerStackObserver _navigationStackObserver = SeafarerStackObserver();

  SeafarerStackObserver get navigationStackObserver => _navigationStackObserver;

  /// Get the registered routes names as a list.
  List<String> getRegisteredRouteNames() {
    return _routeNameMappings.keys.toList();
  }

  /// Retrieves the arguments passed in when calling the [navigate] function.
  ///
  /// Returned arguments are casted with the type provided, the type will always
  /// be a subtype of [BaseArguments].
  ///
  /// Make sure to provide the appropriate type, that is, provide the same type
  /// as the one passed while calling [navigate], else a cast error will be
  /// thrown.
  static T? args<T extends BaseArguments?>(BuildContext context) {
    return (ModalRoute.of(context)!.settings.arguments as ArgumentsWrapper)
        .baseArguments as T?;
  }

  static T? param<T>(BuildContext context, String key) {
    final routeSettings = ModalRoute.of(context)!.settings;
    final argumentsWrapper = (routeSettings.arguments as ArgumentsWrapper);
    final isParamNotRegistered = argumentsWrapper.routeParams == null ||
        !argumentsWrapper.routeParams!.containsKey(key);

    if (isParamNotRegistered) {
      throw ParamNotRegisteredError(
        paramKey: key,
        routeName: routeSettings.name,
      );
    }

    // Check for request paramter type with registered paramter type.
    final paramRegisterdType = argumentsWrapper
        .routeParams![key]!.paramType; // Type with which param was registed
    if (T != paramRegisterdType) {
      AppLogger.instance
        ..warning("========================================")
        ..warning("Mismatching Paramter Type!")
        ..warning(
            "Requested param '$key' with type '$T', but was declared with type '$paramRegisterdType'.\n")
        ..warning(
            "Make sure to pass the type of variable which used when declaring the 'seafarerParam<T>'.")
        ..warning("========================================");
    }

    final defaultParamValue = argumentsWrapper.routeParams![key]!.defaultValue;
    final paramFromNavigationCall =
        argumentsWrapper.params != null ? argumentsWrapper.params![key] : null;
    return (paramFromNavigationCall ?? defaultParamValue) as T?;
  }

  /// Add a new route to [seafarer].
  ///
  /// Route is stored in [_routeNameMappings].
  ///
  /// If a route is provided with a name that was previously added, it will
  /// override the old one.
  void addRoute(SeafarerRoute route) {
    if (_routeNameMappings.containsKey(route.name)) {
      AppLogger.instance.warning(
          "'${route.name}' has already been registered before. Overriding it!");
    }

    // Prepare route params
    final routeParams = <String, SeafarerParam>{};

    if (route.params != null) {
      route.params!.forEach((seafarerParam) {
        if (routeParams.containsKey(seafarerParam.name)) {
          AppLogger.instance.warning(
              "'${seafarerParam.name}' param has already been specified for route $route. Overriding it!");
        }

        routeParams[seafarerParam.name] = seafarerParam;
      });
    }

    _routeNameMappings[route.name] = route;
    _routeParamsMappings[route.name] = routeParams;
  }

  /// Add a list of routes at once.
  ///
  /// Calls [addRoute] for each route in the list.
  void addRoutes(List<SeafarerRoute> routes) {
    if (routes.isNotEmpty) {
      routes.forEach((route) => this.addRoute(route));
    }
  }

  /// Makes this a callable class. Delegates to [navigate].
  Future<T> call<T>(
    String name, {
    BaseArguments? args,
    NavigationType navigationType = NavigationType.push,
    dynamic result,
    bool Function(Route<dynamic> route)? removeUntilPredicate,
    List<SeafarerTransition>? transitions,
    Duration? transitionDuration,
    Map<String, dynamic>? params,
    CustomSeafarerTransition? customTransition,
  }) {
    assert(navigationType != NavigationType.pushAndRemoveUntil ||
        removeUntilPredicate != null);

    _checkAndThrowRouteNotFound(name, args, navigationType);

    return navigate<T>(
      name,
      navigationType: navigationType,
      result: result,
      removeUntilPredicate: removeUntilPredicate,
      args: args,
      transitions: transitions,
      transitionDuration: transitionDuration,
      params: params,
      customTransition: customTransition,
    );
  }

  /// Function used to navigate pages.
  ///
  /// [name] is the route name that was registered using [addRoute].
  ///
  /// [args] are optional arguments that can be passed to the next page.
  /// To retrieve these arguments use [args] method on [seafarer].
  ///
  /// [navigationType] can be specified to choose from various navigation
  /// strategies such as [NavigationType.push], [NavigationType.pushReplace],
  /// [NavigationType.pushAndRemoveUntil].
  ///
  /// [removeUntilPredicate] should be provided if using
  /// [NavigationType.pushAndRemoveUntil] strategy.
  ///
  /// [transitions] is a list of transitions to be used when switching between
  /// pages. [transitionDuration] and [transitionCurve] are duration and curve
  /// used for these transitions.
  ///
  /// [params] are key pair values that can be passed when navigating to a route.
  ///
  /// Provide a custom transition with [customTransition] to seafarer instead of using
  /// inbuilt transitions, if not provided, seafarer will revert to use its default
  /// transitions or delegate to system's own transitions.
  Future<T> navigate<T>(
    String name, {
    BaseArguments? args,
    NavigationType navigationType = NavigationType.push,
    dynamic result,
    bool Function(Route<dynamic> route)? removeUntilPredicate,
    List<SeafarerTransition>? transitions,
    Duration? transitionDuration,
    Curve? transitionCurve,
    Map<String, dynamic>? params,
    CustomSeafarerTransition? customTransition,
  }) {
    assert(navigationType != NavigationType.pushAndRemoveUntil ||
        removeUntilPredicate != null);

    _checkAndThrowRouteNotFound(name, args, navigationType);

    return _navigate(
      name,
      args,
      navigationType,
      result,
      removeUntilPredicate,
      transitions,
      transitionDuration,
      transitionCurve,
      params,
      customTransition,
    ).then((value) => value as T);
  }

  /// Push multiple routes at the same time.
  ///
  /// [routeArgsPairs] is a list of [RouteArgsPair]. Each [RouteArgsPair]
  /// contains the name of a route and its corresponding argument (if any).
  Future<List> navigateMultiple(
    List<RouteArgsPair> routeArgsPairs,
  ) {
    assert(routeArgsPairs.isNotEmpty);

    final pageResponses = routeArgsPairs.map((routeArgs) {
      _checkAndThrowRouteNotFound(
        routeArgs.name,
        routeArgs.args,
        // TODO(gurleensethi): Give user the ability to use any type of NavigationType
        NavigationType.push,
      );

      return _navigate(
        routeArgs.name,
        routeArgs.args,
        // TODO(gurleensethi): Give user the ability to use any type of NavigationType
        NavigationType.push,
        null,
        null,
        routeArgs.transitions,
        routeArgs.transitionDuration,
        routeArgs.transitionCurve,
        null,
        routeArgs.customTransition,
      );
    });

    // For each route check if it exists.
    // Push the route.

    return Future.wait(pageResponses);
  }

  /// Actual navigation is delegated by [navigate] method to this method.
  ///
  /// [name] is the route name that was registered using [addRoute].
  ///
  /// [args] are optional arguments that can be passed to the next page.
  /// To retrieve these arguments use [arguments] method on [seafarer].
  ///
  /// [navigationType] can be specified to choose from various navigation
  /// strategies such as [NavigationType.push], [NavigationType.pushReplace],
  /// [NavigationType.pushAndRemoveUntil].
  ///
  /// [removeUntilPredicate] should be provided is using
  /// [NavigationType.pushAndRemoveUntil] strategy.
  ///
  /// [transitions] is a list of transitions to be used when switching between
  /// pages. [transitionDuration] and [transitionCurve] are duration and curve
  /// used for these transitions.
  ///
  /// [params] are key pair values that can be passed when navigating to a route.
  Future<dynamic> _navigate(
    String name,
    BaseArguments? args,
    NavigationType navigationType,
    dynamic result,
    bool Function(Route<dynamic> route)? removeUntilPredicate,
    List<SeafarerTransition>? transitions,
    Duration? transitionDuration,
    Curve? transitionCurve,
    Map<String, dynamic>? params,
    CustomSeafarerTransition? customTransition,
  ) async {
    final routeParams = _routeParamsMappings[name];
    if (routeParams != null) {
      routeParams.forEach((key, value) {
        // Type of paramter passed should be the same
        // when type is declared.
        if (params != null &&
            params.containsKey(value.name) &&
            params[value.name] != null) {
          final passedParamType = params[value.name].runtimeType;
          if (passedParamType != value.paramType) {
            AppLogger.instance.warning("Invalid Parameter Type! "
                "'${value.name}' is declared with a type '${value.paramType}', "
                "but a '$passedParamType' was passed!");
          }
        }

        // All paramters that are 'required' should be passed.
        bool isMissingRequiredParam = value.isRequired &&
            !(params != null && params.containsKey(value.name));

        if (isMissingRequiredParam) {
          AppLogger.instance.warning(ParameterNotProvidedError(
            paramKey: value.name,
            routeName: name,
          ).toString());
        }
      });
    }

    final argsWrapper = ArgumentsWrapper(
      baseArguments: args,
      transitions: transitions,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      params: params,
      routeParams: _routeParamsMappings[name],
      customTransition: customTransition,
    );

    // Evaluate if the route can be opend using route guard.
    final route = _routeNameMappings[name];

    if (route != null &&
        route.routeGuards != null &&
        route.routeGuards!.isNotEmpty) {
      bool canOpen = true;
      for (SeafarerRouteGuard routeGuard in route.routeGuards!) {
        final result = await routeGuard.canOpen(
          navigatorKey!.currentContext,
          argsWrapper.baseArguments,
          ParamMap(name, routeParams, params),
        );
        if (result != true) {
          canOpen = false;
          break;
        }
      }
      if (canOpen != true) {
        AppLogger.instance.warning("'$name' route rejected by route guard!");
        return null;
      }
    }

    switch (navigationType) {
      case NavigationType.push:
        return this
            .navigatorKey!
            .currentState!
            .pushNamed(name, arguments: argsWrapper);
      case NavigationType.pushReplace:
        return this
            .navigatorKey!
            .currentState!
            .pushReplacementNamed(name, result: result, arguments: argsWrapper);
      case NavigationType.pushAndRemoveUntil:
        return this.navigatorKey!.currentState!.pushNamedAndRemoveUntil(
            name, removeUntilPredicate!,
            arguments: argsWrapper);
      case NavigationType.popAndPushNamed:
        return this
            .navigatorKey!
            .currentState!
            .popAndPushNamed(name, result: result, arguments: argsWrapper);
    }
  }

  /// If the route is not registered throw an error
  /// Make sure to use the correct name while calling navigate.
  void _checkAndThrowRouteNotFound(
    String name,
    BaseArguments? args,
    NavigationType navigationType,
  ) {
    if (!_routeNameMappings.containsKey(name)) {
      if (this.options.handleNameNotFoundUI) {
        this.navigatorKey!.currentState!.push(
          MaterialPageRoute(builder: (BuildContext context) {
            return PageNotFound(
              routeName: name,
              args: args,
              navigationType: navigationType,
            );
          }),
        );
      }
      throw RouteNotFoundError(name: name);
    }
  }

  /// Delegation for [Navigator.pop].
  void pop([dynamic result]) {
    this.navigatorKey!.currentState!.pop(result);
  }

  /// Delegation for [Navigator.popUntil].
  void popUntil(void Function(Route<dynamic>) predicate) {
    this
        .navigatorKey!
        .currentState!
        .popUntil(predicate as bool Function(Route<dynamic>));
  }

  /// Generates the [RouteFactory] which builds a [Route] on request.
  ///
  /// These routes are built using the [seafarerRoute]s provided using
  /// [addRoute] method.
  RouteFactory generator() {
    return (settings) {
      final route = _routeNameMappings[settings.name!];

      if (route == null) return null;

      // TODO(gurleensethi): Check if this is a seafarer route or a normal route.
      ArgumentsWrapper? argsWrapper = settings.arguments as ArgumentsWrapper?;

      // If for some reason the arguments passed themself are null.
      if (argsWrapper == null) {
        argsWrapper = ArgumentsWrapper();
      }

      final BaseArguments? baseArgs = argsWrapper.baseArguments;

      // Select which transitions to use.
      // Priority:
      //   1. Transitions provided when route is called.
      //   2. Default transitions when route was registered.
      //   3. Default transition from seafarerOptions.
      final List<SeafarerTransition> transitions = [];

      final bool areTransitionsProvidedInNavigate =
          argsWrapper.transitions != null &&
              argsWrapper.transitions!.isNotEmpty;
      final bool areTransitionsProvidedInRouteDeclaration =
          route.defaultTransitions != null &&
              route.defaultTransitions!.isNotEmpty;
      final bool areTransitionsProvidedInseafarerOptions =
          this.options.defaultTransitions != null;

      if (areTransitionsProvidedInNavigate) {
        transitions.addAll(argsWrapper.transitions!);
      } else if (areTransitionsProvidedInRouteDeclaration) {
        transitions.addAll(route.defaultTransitions!);
      } else if (areTransitionsProvidedInseafarerOptions) {
        transitions.addAll(this.options.defaultTransitions!);
      }

      final transitionDuration = argsWrapper.transitionDuration ??
          route.defaultTransitionDuration ??
          this.options.defaultTransitionDuration;

      final transitionCurve = argsWrapper.transitionCurve ??
          route.defaultTransitionCurve ??
          this.options.defaultTransitionCurve;

      final customTransition = argsWrapper.customTransition ??
          route.customTransition ??
          this.options.customTransition;

      bool shouldUseCustomTransition = customTransition != null;
      if (argsWrapper.customTransition != null) {
        shouldUseCustomTransition = true;
      } else if (areTransitionsProvidedInNavigate) {
        shouldUseCustomTransition = false;
      } else if (route.customTransition != null) {
        shouldUseCustomTransition = true;
      } else if (areTransitionsProvidedInRouteDeclaration) {
        shouldUseCustomTransition = false;
      } else if (this.options.customTransition != null) {
        shouldUseCustomTransition = true;
      } else if (areTransitionsProvidedInseafarerOptions) {
        shouldUseCustomTransition = false;
      }

      RouteSettings routeSettings = RouteSettings(
        name: settings.name,
        arguments: argsWrapper.copyWith(
          baseArguments: baseArgs != null ? baseArgs : route.defaultArgs,
        ),
      );

      return TransitionFactory.buildTransition(
        transitions: transitions,
        duration: transitionDuration,
        curve: transitionCurve,
        settings: routeSettings,
        customTransition: shouldUseCustomTransition ? customTransition : null,
        builder: (context) => route.builder(
          context,
          baseArgs ?? route.defaultArgs,
          ParamMap(
            route.name,
            argsWrapper!.routeParams,
            argsWrapper.params,
          ),
        ),
      );
    };
  }

  static RouteFactory unknownRouteGenerator() {
    return (settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (BuildContext context) {
          return PageNotFound(
            routeName: settings.name!,
            args: settings.arguments as BaseArguments?,
          );
        },
      );
    };
  }
}

class ParamMap {
  final String _routeName;
  final Map<String, SeafarerParam>? _routeParams;
  final Map<String, dynamic>? _params;

  ParamMap(this._routeName, this._routeParams, this._params);

  T? param<T>(String key) {
    final isParamNotRegistered =
        _routeParams == null || !_routeParams!.containsKey(key);

    if (isParamNotRegistered) {
      throw ParamNotRegisteredError(
        paramKey: key,
        routeName: this._routeName,
      );
    }

    final defaultParamValue = _routeParams![key]!.defaultValue;
    final paramFromNavigationCall = _params != null ? _params![key] : null;
    return (paramFromNavigationCall ?? defaultParamValue) as T?;
  }
}
