class ParamNotRegisteredError extends Error {
  final String paramKey;
  final String? routeName;

  ParamNotRegisteredError({
    required this.routeName,
    required this.paramKey,
  });

  @override
  String toString() {
    return "Param '$paramKey' is not registered for '$routeName'. Make sure to add a `seafarerParam` "
        "for '$paramKey' while registering '$routeName' route.";
  }
}
