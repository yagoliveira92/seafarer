import 'package:flutter/material.dart';
import 'package:seafarer/seafarer.dart';
import 'package:seafarer/src/models/base_arguments.dart';
import 'package:seafarer/src/seafarer.dart';

typedef RouteGuard = Future<bool> Function(
  BuildContext? context,
  BaseArguments? args,
  ParamMap paramMap,
);

abstract class SeafarerRouteGuard {
  SeafarerRouteGuard();

  Future<bool> canOpen(
    BuildContext? context,
    BaseArguments? args,
    ParamMap paramMap,
  );

  factory SeafarerRouteGuard.simple(RouteGuard canOpen) {
    return _SimpleRouteGuard(canOpen);
  }
}

class _SimpleRouteGuard extends SeafarerRouteGuard {
  final RouteGuard routeGuard;

  _SimpleRouteGuard(this.routeGuard) : super();

  @override
  Future<bool> canOpen(
    BuildContext? context,
    BaseArguments? args,
    ParamMap paramMap,
  ) {
    return this.routeGuard(context, args, paramMap);
  }
}
