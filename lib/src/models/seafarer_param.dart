class SeafarerParam<T> {
  final String name;
  final T? defaultValue;
  final bool isRequired;
  final Type paramType;

  SeafarerParam({
    required this.name,
    this.defaultValue,
    this.isRequired = false,
  })  : paramType = T;

  @override
  operator ==(Object other) =>
      identical(other, this) || other is SeafarerParam && other.name == this.name;

  @override
  int get hashCode => name.hashCode;
}
