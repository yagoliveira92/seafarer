<p align="center">
  <a>
    <img src="https://raw.githubusercontent.com/yagoliveira92/seafarer/main/images/seafarer-logo.png" alt="Logo">
  </a>

  <h1 align="center">Seafarer</h3>
  <p align="center">
    A Flutter package for easy navigation management.
   <br>
    <p align="center">
      <img src="https://img.shields.io/badge/flutter-2.0.4-blue" />
      <img src="https://img.shields.io/badge/dart-%3E=2.2.2%20%3C3.0.0-blue" />
      <img src="https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fatrox%2Fsync-dotenv%2Fbadge" />
      <img src="https://img.shields.io/badge/License-MIT-yellow.svg" />
    </p>
  </p>
</p>

[![pub_package](https://img.shields.io/pub/vpre/seafarer.svg)](https://pub.dev/packages/seafarer)

#### Warning: Package is still under development, there might be breaking changes in future.

#### Warning 2: This package is a Null Safety migration to another package [Sailor](https://pub.dev/packages/sailor). All of content is a fork for this.

## Index

- [Setup and Usage](#setup-and-usage)
- [Passing Parameters](#passing-parameters)
- [Passing Arguments](#passing-arguments)
- [Route Guards (Experimental)](#route-guards-experimental)
- [Transitions](#transitions)
- [Pushing Multiple Routes](#pushing-multiple-routes)
- [Log Navigation](#log-navigation)
- [Support](#support)

## Setup and Usage

1. Create an instance of `Seafarer` and add routes.

```dart
// Routes class is created by you.
class Routes {
  static final seafarer = Seafarer();

  static void createRoutes() {
    seafarer.addRoute(seafarerRoute(
        name: "/secondPage",
        builder: (context, args, params) {
          return SecondPage();
        },
      ));
  }
}
```

2. Register the routes in `onGenerateRoute` using the `generate` function of `seafarer` and also `seafarer`'s `navigatorKey`.

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seafarer Example',
      home: Home(),
      navigatorKey: Routes.seafarer.navigatorKey,  // important
      onGenerateRoute: Routes.seafarer.generator(),  // important
    );
  }
}
```

3. Make sure to create routes before starting the application.

```dart
void main() async {
  Routes.createRoutes();
  runApp(App());
}
```

4. Use the instance of `seafarer` to navigate.

```dart
Routes.seafarer.navigate("/secondPage");
```

- TIP: `seafarer` is a callable class, so you can omit `navigate` and directly call the method.

```dart
Routes.seafarer("/secondPage");
```

## Passing Parameters

`seafarer` allows you to pass parameters to the page that you are navigating to.

- Before passing the parameter itself, you need to declare it while declaring your route. Let's declare a parameter named `id` that has a default value of `1234`.

```dart
seafarer.addRoutes([
  SeafarerRoute(
    name: "/secondPage",
    builder: (context, args, params) => SecondPage(),
    params: [
      SeafarerParam<int>(
        name: 'id',
        defaultValue: 1234,
      ),
    ],
  ),
);
```

- Pass the actual parameter when navigating to the new route.

```dart
Routes.seafarer.navigate<bool>("/secondPage", params: {
  'id': 4321,
});
```

- Parameters can be retrieved from two places, first, the route builder and second, the opened page itself.

**Route Builder:**

```dart
Seafarer.addRoutes([
  SeafarerRoute(
    name: "/secondPage",
    builder: (context, args, params) {
      // Getting a param
      final id = params.param<int>('id');
      return SecondPage();
    },
    params: [
      SeafarerParam(
        name: 'id',
        defaultValue: 1234,
      ),
    ],
  ),
);
```

**Opened page:**

```dart
class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final id = Seafarer.param<int>(context, 'id');

    ...

  }
}
```

Make sure to specify the type of paramter when declaring `seafarerParam<T>`. This type is used to make sure when the route is being opened, it is passed the correct param type. Right now `seafarer` logs a warning if the type of declared and passed param is not same. In future version this might throw an error.

## Passing Arguments

`Seafarer` allows you to pass arguments to the page that you are navigating to.

- Create a class that extends from `BaseArguments`.

```dart
class SecondPageArgs extends BaseArguments {
  final String text;

  SecondPageArgs(this.text);
}
```

- When calling the `navigate` method pass these arguments.

```dart
final response = Routes.seafarer.navigate(
  "/secondPage",
  args: SecondPageArgs('Hey there'),
);
```

- When in the SecondPage, use `seafarer.args` to get the passed arguments.

```dart
class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Seafarer.args<SecondPageArgs>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Compass Example'),
      ),
      body: Center(
        child: Text(args.text),
      ),
    );
  }
}
```

## Route Guards (Experimental)

Routes can be protected from being opened when `navigate` is called using `route guard`.

A route guard can be added when declaring a `seafarerRoute`.

```dart
Seafarer.addRoutes([
  SeafarerRoute(
    name: "/secondPage",
    builder: (context, args, params) => SecondPage(),
    routeGuards: [
      SeafarerRouteGuard.simple((context, args, params) async {
        // Can open logic goes here.
        if (sharedPreferences.getToken() != null) {
          return true;
        }
        return false;
      }),
    ],
  ),
);
```

`routeGuards` takes an array of `seafarerRouteGuard`.

There are two ways to create a route guard:

- Using `seafarerRouteGuard.simple`, as shown above.
```dart
SeafarerRouteGuard.simple((context, args, params) async {
  // Can open logic goes here.
  if (sharedPreferences.getToken() != null) {
    return true;
  }
  return false;
});
```
- Extending `SeafarerRouteGuard` class.
```dart
class CustomRouteGuard extends SeafarerRouteGuard {
  @override
  Future<bool> canOpen(
    BuildContext context,
    BaseArguments args,
    ParamMap paramMap,
  ) async {
    return false;
  }
}
```

The result from each route guard is `Future<bool>`. If the value returned __by each route__ is `true` the route is accepted and opened, anything else will result in route being rejected and not being opened.

## Transitions

seafarer has inbuilt support for page transitions. A transition is specified using `SeafarerTransition`.

Transition can be specified at 3 levels (ordered in priority from highest to lowest):

- When Navigating (using `Seafarer.navigate`).
- While adding routes (`SeafarerRoute`).
- Global transitions (`SeafarerOptions`).

### When navigating

Specify which transitions to use when calling the `navigate` method.

```dart
Routes.seafarer.navigate(
  "/secondPage",
  transitions: [SeafarerTransition.fade_in],
);
```

More than one transition can be provided when navigating a single route. These transitions are composed on top of each other, so in some cases changing the order will change the animation.

```dart
Routes.seafarer.navigate(
  "/secondPage",
  transitions: [
    SeafarerTransition.fade_in,
    SeafarerTransition.slide_from_right,
  ],
  transitionDuration: Duration(milliseconds: 500),
  transitionCurve: Curves.bounceOut,
);
```

`Duration` and `Curve` can be provided using `transitionDuration` and `transitionCurve` respectively.

```dart
Routes.seafarer.navigate(
  "/secondPage",
  transitions: [
    SeafarerTransition.fade_in,
    SeafarerTransition.slide_from_right,
  ],
  transitionDuration: Duration(milliseconds: 500),
  transitionCurve: Curves.bounceOut,
);
```

In the above example the page will slide in from right with a fade in animation. You can specify as many transitions as you want.

### When adding routes

You can specify the default transition for a route, so you don't have to specify it again and again when navigating.

```dart
Seafarer.addRoute(SeafarerRoute(
  name: "/secondPage",
  defaultTransitions: [
    SeafarerTransition.slide_from_bottom,
    SeafarerTransition.zoom_in,
  ],
  defaultTransitionCurve: Curves.decelerate,
  defaultTransitionDuration: Duration(milliseconds: 500),
  builder: (context, args) => SecondPage(),
));
```

Priority: Transitions provided in `Seafarer.navigate` while navigating to this route, will override these transitions.

### Global transitions

You can specify default transition to be used for all routes in `seafarer`.

```dart
SeafarerOptions(
  defaultTransitions: [
    SeafarerTransition.slide_from_bottom,
    SeafarerTransition.zoom_in,
  ],
  defaultTransitionCurve: Curves.decelerate,
  defaultTransitionDuration: Duration(milliseconds: 500),
)
```

Priority: Transitions provided while adding a route or when navigating using `navigate`, will override these transitions.

### Custom Transitions

Although `seafarer` provides you with a number of out of the box transitions, you can still provide your own custom transitions.

- To create a custom transition, extend the class `CustomSeafarerTransition` and implement `buildTransition` method.

```dart
class MyCustomTransition extends CustomSeafarerTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
```

This transition can now be provided at 3 places:

- While calling `navigate`.

```dart
Routes.seafarer.navigate<bool>(
  "/secondPage",
  customTransition: MyCustomTransition(),
);
```

- When declaring a `seafarerRoute`.

```dart
SeafarerRoute(
  name: "/secondPage",
  builder: (context, args, params) => SecondPage(),
  customTransition: MyCustomTransition(),
),
```

- In `SeafarerOptions`:

```dart
static final seafarer = Seafarer(
  options: SeafarerOptions(
    customTransition: MyCustomTransition(),
  ),
);
```

#### Custom Transition Priority

_NOTE: Custom transitions have the highest priority, if you provide a custom transition, they will be used over seafarer's inbuilt transitions._

The same priority rules apply to custom transitions as inbuilt seafarer transitions, with the added rule that at any step if both transitions are provided (i.e. seafarer's inbuilt transitions and a CustomSeafarerTransition), the custom transition will be used over inbuilt one.

For example, in the below code, `MyCustomTransition` will be used instead of `SeafarerTransition.slide_from_top`.

```dart
Routes.seafarer.navigate<bool>(
  "/secondPage",
  transitions: [
    SeafarerTransition.slide_from_top,
  ],
  customTransition: MyCustomTransition(),
);
```

## Pushing Multiple Routes

seafarer allows you to push multiple pages at the same time and get collected response from all.

```dart
final responses = await Routes.seafarer.navigateMultiple(context, [
  RouteArgsPair("/secondPage", SecondPageArgs("Multi Page!")),
  RouteArgsPair("/thirdPage", ThirdPageArgs(10)),
]);

print("Second Page Response ${responses[0]}");
print("Third Page Response ${responses[1]}");
```

## Log Navigation

Use `SeafarerLoggingObserver` to log the `push`/`pop` navigation inside the application.
Add the `SeafarerLoggingObserver` to the `navigatorObservers` list inside your `MaterialApp`.

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compass Example',
      home: Home(),
      onGenerateRoute: Routes.seafarer.generator(),
      navigatorObservers: [
        SeafarerLoggingObserver(),
      ],
    );
  }
}
```

Once added, start navigating in your app and check the logs. You will see something like this.

```
flutter: [seafarer] Route Pushed: (Pushed Route='/', Previous Route='null', New Route Args=null, Previous Route Args=null)
flutter: [seafarer] Route Pushed: (Pushed Route='/secondPage', Previous Route='/', New Route Args=Instance of 'SecondPageArgs', Previous Route Args=null)
flutter: [seafarer] Route Popped: (New Route='/', Popped Route='/secondPage', New Route Args=null, Previous Route Args=Instance of 'SecondPageArgs')
```

## Support

If you face any issue or want a new feature to be added to the package, please [create an issue](https://github.com/gurleensethi/seafarer/issues/new).
I will be more than happy to resolve your queries.
