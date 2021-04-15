import 'package:flutter/material.dart';
import 'package:seafarer/seafarer.dart';

void main() async {
  Routes.createRoutes();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compass Example',
      home: Home(),
      onGenerateRoute: Routes.seafarer.generator(),
      navigatorKey: Routes.seafarer.navigatorKey,
      navigatorObservers: [
        SeafarerLoggingObserver(),
        Routes.seafarer.navigationStackObserver,
      ],
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('First Page'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              child: Text('Open Second Page'),
              onPressed: () async {
                final response = await Routes.seafarer.navigate<bool>(
                  "/secondPage",
                  transitions: [
                    SeafarerTransition.slide_from_top,
                  ],
                  customTransition: MyCustomTransition(),
                  params: {
                    'id': null,
                  },
                );

                print("Response from SecondPage: $response");
              },
            ),
            ElevatedButton(
              child: Text('Open Multi Page (Second and Third)'),
              onPressed: () async {
                final responses = await Routes.seafarer.navigateMultiple([
                  RouteArgsPair(
                    "/secondPage",
                    args: SecondPageArgs("Multi Page!"),
                  ),
                  RouteArgsPair(
                    "/thirdPage",
                    args: ThirdPageArgs(10),
                  ),
                ]);

                print("Second Page Response ${responses[0]}");
                print("Third Page Response ${responses[1]}");
              },
            ),
            ElevatedButton(
              child: Text('Push Replace Page'),
              onPressed: () async {
                Routes.seafarer.navigate("/pushReplacePage");
              },
            ),
            ElevatedButton(
              child: Text('Print navigation stack!'),
              onPressed: () {
                Routes.seafarer.navigationStackObserver.prettyPrintStack();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPageArgs extends BaseArguments {
  final String text;

  SecondPageArgs(this.text);
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Seafarer.args<SecondPageArgs>(context);
    final id = Seafarer.param<String>(context, 'id');

    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(args?.text ?? 'Second Page'),
            Text("Param('id'): $id"),
            ElevatedButton(
              child: Text('Close Page'),
              onPressed: () {
                Routes.seafarer.pop(true);
              },
            ),
            ElevatedButton(
              child: Text('Print navigation stack!'),
              onPressed: () {
                Routes.seafarer.navigationStackObserver.prettyPrintStack();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdPageArgs extends BaseArguments {
  final int count;

  ThirdPageArgs(this.count);
}

class ThirdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Seafarer.args<ThirdPageArgs>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Third Page'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text("Count from args is :${args?.count}"),
            ElevatedButton(
              child: Text('Close Page'),
              onPressed: () {
                Routes.seafarer.pop(10);
              },
            ),
            ElevatedButton(
              child: Text('Print navigation stack!'),
              onPressed: () {
                Routes.seafarer.navigationStackObserver.prettyPrintStack();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PushReplacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PushReplacePage'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ElevatedButton(
              child: Text('Push Replace'),
              onPressed: () {
                Routes.seafarer.navigate(
                  "/secondPage",
                  navigationType: NavigationType.pushReplace,
                );
              },
            ),
            ElevatedButton(
              child: Text('Push Unitl First and Replace'),
              onPressed: () {
                Routes.seafarer.navigate(
                  "/thirdPage",
                  navigationType: NavigationType.pushAndRemoveUntil,
                  removeUntilPredicate: (route) => route.isFirst,
                );
              },
            ),
            ElevatedButton(
              child: Text('Print navigation stack!'),
              onPressed: () {
                Routes.seafarer.navigationStackObserver.prettyPrintStack();
              },
            ),
            Text(Routes.seafarer.navigationStackObserver
                .getRouteStack()[0]
                .toString())
          ],
        ),
      ),
    );
  }
}

class Routes {
  static final seafarer = Seafarer(
    options: SeafarerOptions(
      handleNameNotFoundUI: true,
      isLoggingEnabled: true,
      customTransition: MyCustomTransition(),
      defaultTransitions: [
        SeafarerTransition.slide_from_bottom,
        SeafarerTransition.zoom_in,
      ],
      defaultTransitionCurve: Curves.decelerate,
      defaultTransitionDuration: Duration(milliseconds: 500),
    ),
  );

  static void createRoutes() {
    seafarer.addRoutes(
      [
        SeafarerRoute(
          name: "/secondPage",
          builder: (context, args, params) => SecondPage(),
          defaultArgs: SecondPageArgs('From default arguments!'),
          customTransition: MyCustomTransition(),
          params: [
            SeafarerParam<String>(
              name: 'id',
            ),
          ],
          defaultTransitions: [
            SeafarerTransition.slide_from_bottom,
            SeafarerTransition.zoom_in,
          ],
          routeGuards: [
            SeafarerRouteGuard.simple((context, args, params) async {
              return true;
            }),
          ],
        ),
        SeafarerRoute(
          name: "/thirdPage",
          builder: (context, args, params) => ThirdPage(),
          defaultTransitions: [SeafarerTransition.slide_from_left],
        ),
        SeafarerRoute(
          name: "/pushReplacePage",
          builder: (context, args, params) => PushReplacePage(),
          routeGuards: [
            SeafarerRouteGuard.simple(
              (context, args, params) => Future.value(true),
            )
          ],
        ),
      ],
    );
  }
}

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
