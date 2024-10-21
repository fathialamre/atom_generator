import 'package:atom_generator/src/models/route_dependency.dart';
import 'package:atom_generator/src/models/route_params.dart';

class RouteItem {
  String routeName;
  bool initialRoute;
  Set<String> imports;
  String className;
  List<RouteParams> routeParams;
  List<RouteDependency> dependencies;
  List<dynamic> middlewares;

  RouteItem({
    this.routeName = '',
    this.imports = const {},
    this.className = '',
    this.initialRoute = false,
    this.routeParams = const [],
    this.dependencies = const [],
    this.middlewares = const [],
  });

// fromJson: Create an instance from a JSON map
  factory RouteItem.fromJson(Map<String, dynamic> json) {
    return RouteItem(
      routeName: json['routeName'],
      initialRoute: json['initialRoute'],
      imports:
      (json['imports'] as List<dynamic>).map((e) => e as String).toSet(),
      className: json['className'],
      routeParams: (json['routeParams'] as List<dynamic>)
          .map((e) => RouteParams.fromJson(e as Map<String, dynamic>))
          .toList(),
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => RouteDependency.fromJson(e as Map<String, dynamic>))
          .toList(),
      middlewares: json['middlewares'].map((e) => e as String).toList(),
    );
  }

  // toJson: Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'initialRoute': initialRoute,
      'imports': imports.toList(),
      'className': className,
      'routeParams': routeParams.map((e) => e.toJson()).toList(),
      'dependencies': dependencies.map((e) => e.toJson()).toList(),
      'middlewares': middlewares.map((e) => e.toString()).toList(),
    };
  }

  // toMap: Convert the object to a Map (same as toJson in this case)
  Map<String, dynamic> toMap() {
    return toJson();
  }
}
