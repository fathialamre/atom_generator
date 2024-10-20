import 'package:atom_generator/src/models/route_params.dart';

class RouteDependency {
  final String name;
  final String type;
  final String importUri;
  final List<RouteDependency>? dependencies;
  final bool singleton;
  final bool isLazyPut;
  final String? tag;
  final String? findByTag;
  final bool findByParam;
  final String? module;
  final String? moduleUri;
  final List<RouteParams>? routeParams;
  final bool isNamed;
  final bool isGlobal;
  final bool ignoreInjection;

  RouteDependency({
    required this.name,
    required this.type,
    required this.importUri,
    this.dependencies,
    this.singleton = false,
    this.isLazyPut = true,
    this.tag,
    this.findByTag,
    this.findByParam = false,
    this.module,
    this.moduleUri,
    this.routeParams,
    this.isGlobal = false,
    required this.isNamed,
    this.ignoreInjection = false,
  });

  factory RouteDependency.withDependencies({
    required String name,
    required String type,
    required String importUri,
    required List<RouteDependency> deps,
    required bool singleton,
    required bool isLazyPut,
    required String? tag,
    required String? findByTag,
    required bool findByParam,
    required String? module,
    required String? moduleUri,
    required List<RouteParams> routeParams,
    required bool isNamed,
    required bool isGlobal,
    required bool ignoreInjection,
  }) {
    return RouteDependency(
      name: name,
      type: type,
      importUri: importUri,
      dependencies: deps,
      singleton: singleton,
      isLazyPut: isLazyPut,
      tag: tag,
      findByTag: findByTag,
      findByParam: findByParam,
      module: module,
      moduleUri: moduleUri,
      routeParams: routeParams,
      isNamed: isNamed,
      isGlobal: isGlobal,
      ignoreInjection: ignoreInjection,
    );
  }

  factory RouteDependency.fromJson(Map<String, dynamic> json) {
    return RouteDependency(
      name: json['name'],
      type: json['type'],
      importUri: json['importUri'],
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => RouteDependency.fromJson(e as Map<String, dynamic>))
          .toList(),
      routeParams: (json['routeParams'] as List<dynamic>)
          .map((e) => RouteParams.fromJson(e as Map<String, dynamic>))
          .toList(),
      singleton: json['singleton'] as bool,
      isLazyPut: json['isLazyPut'] as bool,
      tag: json['tag'],
      findByTag: json['findByTag'],
      findByParam: json['findByParam'],
      module: json['module'],
      moduleUri: json['moduleUri'],
      isNamed: json['isNamed'],
      isGlobal: json['isGlobal'] as bool,
      ignoreInjection: json['ignoreInjection'] as bool,
    );
  }

  toJson() {
    return {
      'name': name,
      'type': type,
      'importUri': importUri,
      'dependencies': dependencies != null
          ? dependencies?.map((e) => e.toJson()).toList()
          : [],
      'routeParams': routeParams != null
          ? routeParams?.map((e) => e.toJson()).toList()
          : [],
      'singleton': singleton,
      'isLazyPut': isLazyPut,
      'tag': tag,
      'findByTag': findByTag,
      'findByParam': findByParam,
      'module': module,
      'moduleUri': moduleUri,
      'isNamed': isNamed,
      'isGlobal': isGlobal,
      'ignoreInjection': ignoreInjection,
    };
  }

  String get injectionType {
    if (singleton) {
      return 'Get.put';
    } else if (isLazyPut) {
      return 'Get.lazyPut';
    }
    return 'Get.put';
  }

  get dependencyType {
    if (module != null) {
      return '$module.instance';
    }
    return type;
  }
}
