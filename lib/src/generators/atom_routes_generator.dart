import 'dart:async';
import 'dart:convert';
import 'package:atom_generator/src/models/navigation_type.dart';
import 'package:atom_generator/src/models/route_dependency.dart';
import 'package:atom_generator/src/models/route_item.dart';
import 'package:atom_generator/src/models/route_params.dart';
import 'package:atom_generator/src/utils/code_formater.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:glob/glob.dart';

class AtomRoutesGenerator extends Builder {
  List<Directive> _getImports(Set<String> imports) {
    return [
      Directive.import('package:get/get.dart'),
      ...imports.toList().reversed.map(
            (e) => Directive.import(e),
          ),
    ];
  }

  _buildRouteMethod({required RouteItem routeItem}) {
    List<RouteDependency> routeDependencies = routeItem.dependencies;

    return Method(
      (b) => b
        ..name = 'route'
        ..static = true
        ..returns = refer('GetPage')
        ..body = Block.of([
          // ...routeItem.routeParams.map(
          //   (m) => declareFinal(m.name, type: refer(m.type))
          //       .assign(
          //         refer('Get.arguments')
          //             .index(literal(m.name))
          //             .asA(refer(m.type)),
          //       )
          //       .statement,
          // ),
          refer('GetPage')
              .newInstance([], {
                'name': refer('routePath'),
                'page': Method(
                  (m) => m
                    ..lambda = true
                    ..body = refer(
                      routeItem.className,
                    ).call(
                        // Positional arguments
                        [
                          ...routeItem.routeParams
                              .where(
                                  (e) => !e.isNamed) // Unnamed route arguments
                              .map((arg) => refer('Get.arguments')
                                  .index(literal(arg.name))
                                  .asA(refer(arg.type))),
                          ...routeItem.dependencies
                              .where(
                                  (e) => !e.isNamed) // Positional dependencies
                              .map((dep) {
                            return refer('Get.find').call(
                              [],
                              {
                                // Add 'tag' if findByTag is provided
                                if (dep.findByTag != null)
                                  'tag': refer('\'${dep.findByTag}\''),

                                // Add 'tag' as a string if findByTag and findByParam are true
                                if (dep.findByTag != null && dep.findByParam)
                                  'tag': refer('${dep.findByTag}.toString()'),
                              },
                              [refer(dep.type)],
                            );
                          }),
                        ],

                        // Named arguments
                        {
                          // Named route arguments
                          ...Map.fromEntries(routeItem.routeParams
                              .where((e) => e.isNamed)
                              .map((arg) {
                            return MapEntry(
                                arg.name,
                                refer('Get.arguments')
                                    .index(literal(arg.name))
                                    .asA(refer(arg.type)));
                          })),

                          // Named dependencies
                          ...Map.fromEntries(routeItem.dependencies
                              .where((e) => e.isNamed)
                              .map((dep) {
                            return MapEntry(
                                dep.name,
                                refer('Get.find').call(
                                  [],
                                  {
                                    // Handle 'tag' if findByTag is not null
                                    if (dep.findByTag != null)
                                      'tag': refer('\'${dep.findByTag}\''),

                                    // Handle both 'tag' and findByParam
                                    if (dep.findByTag != null &&
                                        dep.findByParam)
                                      'tag':
                                          refer('${dep.findByTag}.toString()'),
                                  },
                                  [refer(dep.type)],
                                ));
                          })),
                        }).code,
                ).closure,
                // 'binding': refer(binding),
                'binding': refer('BindingsBuilder').call(
                  [
                    Method(
                      (m) => m
                        ..body = Block.of(
                          routeDependencies.expand(
                            (e) => putBuilder(
                                routeDependency: e,
                                routeParams: routeItem.routeParams),
                          ),
                        ),
                    ).closure
                  ],
                ),
              })
              .returned
              .statement,
        ]),
    );
  }

  List<Code> putBuilder({
    required RouteDependency routeDependency,
    Set<String>? addedDependencies, // Track added dependencies
    List<RouteParams> routeParams = const [],
  }) {
    addedDependencies ??= {}; // Initialize if not provided
    List<Code> dependenciesTree = [];

    // Recursively ensure that dependencies are added before the current component
    routeDependency.dependencies?.forEach((dep) {
      if (!addedDependencies!.contains(dep.type)) {
        dependenciesTree.addAll(
          putBuilder(
              routeDependency: dep, addedDependencies: addedDependencies),
        );
      }
    });

    // Only add the current dependency if it's not already added
    if (!addedDependencies.contains(routeDependency.type)) {
      if (!routeDependency.ignoreInjection) {
        Code code = refer(routeDependency.injectionType).call(
          [
            Method(
              (m) => m
                ..body = refer(routeDependency.dependencyType).call(
                    // Positional Arguments
                    [
                      ...routeDependency.routeParams!
                          .where(
                              (e) => !e.isNamed) // Unnamed positional arguments
                          .map((arg) => refer('Get.arguments')
                              .index(literal(arg.name))
                              .asA(refer(arg.type))),
                      ...routeDependency.dependencies!
                          .where(
                              (dep) => !dep.isNamed) // Positional dependencies
                          .map((dep) =>
                              refer('Get.find').call([], {}, [refer(dep.type)]))
                    ],

                    // Named Arguments
                    {
                      ...Map.fromEntries(routeDependency.routeParams!
                          .where((e) => e.isNamed) // Named routeParams
                          .map((arg) {
                        return MapEntry(
                            arg.name,
                            refer('Get.arguments')
                                .index(literal(arg.name))
                                .asA(refer(arg.type)));
                      })),
                      ...Map.fromEntries(routeDependency.dependencies!
                          .where((dep) => dep.isNamed) // Named dependencies
                          .map((dep) {
                        return MapEntry(dep.name,
                            refer('Get.find').call([], {}, [refer(dep.type)]));
                      })),
                    }).code,
            ).closure
          ],
          {
            if (routeDependency.singleton) 'permanent': literalTrue,
            if (routeDependency.findByTag != null)
              'tag': refer('\'${routeDependency.findByTag}\''),
            if (routeDependency.findByTag != null &&
                routeDependency.findByParam)
              'tag': refer('${routeDependency.findByTag}.toString()'),
          },
        ).statement;

        dependenciesTree.add(code);
        addedDependencies.add(routeDependency.type);
      }
    }

    return dependenciesTree;
  }

// Function to get all global dependencies from a list of dependencies.
  Set<RouteDependency> getGlobalDependenciesFromList(
      List<RouteDependency> dependencies) {
    Set<RouteDependency> globalDeps = {};

    // Iterate over the list of dependencies.
    for (var dep in dependencies) {
      // If the current dependency is global, add it to the list.
      if (dep.isGlobal) {
        globalDeps.add(dep);
      }

      // Recursively collect global dependencies from nested dependencies.
      if (dep.dependencies != null) {
        globalDeps.addAll(getGlobalDependenciesFromList(dep.dependencies!));
      }
    }
    return globalDeps;
  }

  _buildGlobalBinding({required Map<String, RouteItem> routesMap}) {
    var globalDependencies = getGlobalDependenciesFromList(
      routesMap.values.expand((e) => e.dependencies).toList(),
    );

    return Class(
      (c) => c
        ..name = 'GlobalBindings'
        ..methods.addAll(
          [
            Method(
              (b) => b
                ..static = true
                ..name = 'bindings'
                ..returns = refer('Bindings')
                ..body = refer('BindingsBuilder').call(
                  [
                    Method(
                      (m) {
                        // Use a Set to track added dependencies by their unique identifier (e.g., name or type).
                        final Set<String> addedDeps = {};

                        // Generate the code block without duplication.
                        final List<Code> depCodes = globalDependencies
                            .where(
                                (e) => addedDeps.add(e.module!)) // Add if new.
                            .map(
                              (e) => Code(
                                '${e.injectionType}(() => ${e.module}.instance());',
                              ),
                            )
                            .toList();
                        m.body = Block.of(depCodes);
                      },
                    ).closure,
                  ],
                ).code,
            ),
          ],
        ),
    );
  }

  _buildAppRoutes({required Map<String, RouteItem> routesMap}) {
    return Class((c) => c
      ..name = 'AppRoutes'
      ..methods.addAll([
        Method(
          (b) => b
            ..static = true
            ..name = "initialRoute"
            ..lambda = true
            ..type = MethodType.getter
            ..body = Code(
              "'${routesMap.values.firstWhere((e) => e.initialRoute).routeName}'",
            ),
        ),
        Method(
          (b) => b
            ..static = true
            ..name = "routes"
            ..returns = refer("List<GetPage>")
            ..body = Code(
              "return [${routesMap.values.map((e) => "${e.className}Route.route()").join(",")}];",
            ),
        )
      ]));
  }

  _buildRouteClass({required RouteItem routeItem}) {
    return Class(
      (b) => b
        ..name = "${routeItem.className}Route"
        ..fields.addAll(
          [
            Field(
              (b) => b
                ..static = true
                ..modifier = FieldModifier.constant
                ..name = 'routePath'
                ..type = refer('String')
                ..assignment = literal(routeItem.routeName).code,
            ),
          ],
        )
        ..methods.addAll(
          [
            _buildRouteMethod(routeItem: routeItem),
            _buildNavigationMethods(
              routeItem: routeItem,
              navigatorType: NavigationType.toNamed,
            ),
            _buildNavigationMethods(
              routeItem: routeItem,
              navigatorType: NavigationType.offAndToNamed,
            ),
            _buildNavigationMethods(
              routeItem: routeItem,
              navigatorType: NavigationType.offAllNamed,
            ),
          ],
        ),
    );
  }

  _buildNavigationMethods({
    required RouteItem routeItem,
    required NavigationType navigatorType,
  }) {
    String routeArgs = "";
    List<Parameter> openMethodParams = [];
    for (RouteParams e in routeItem.routeParams) {
      routeArgs += "'${e.name}': ${e.name},";
      openMethodParams.add(
        Parameter(
          (b) => b
            ..name = e.name
            ..required = e.required
            ..named = true
            ..type = refer(e.type),
        ),
      );
    }

    return Method(
      (b) => b
        ..name = navigatorType.name
        ..returns = refer("void")
        ..static = true
        ..optionalParameters.addAll(openMethodParams)
        ..body = refer('Get.${navigatorType.name}').call(
          [refer('routePath')],
          {
            'arguments': refer('{$routeArgs}'),
          },
        ).code,
    );
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final Map<String, RouteItem> routesMap = <String, RouteItem>{};
    Set<String> imports = {};

    await for (final asset in buildStep.findAssets(Glob("**.routes.json"))) {
      RouteItem routeItem = RouteItem.fromJson(
        jsonDecode(
          await buildStep.readAsString(asset),
        ),
      );
      imports.addAll(routeItem.imports);
      routesMap[routeItem.routeName] = routeItem;
    }

    if (routesMap.isEmpty) {
      return;
    }

    if (routesMap.values.where((e) => e.initialRoute).length != 1) {
      throw Exception("There should be only one initial route");
    }

    List<Class> classes = [];

    routesMap.forEach((String key, RouteItem routeItem) {
      Class classItem = _buildRouteClass(routeItem: routeItem);
      classes.add(classItem);
    });

    List<Directive> importDirective = _getImports(imports);
    final Class appRoutesClass = _buildAppRoutes(routesMap: routesMap);
    final Class buildGlobalBinding = _buildGlobalBinding(routesMap: routesMap);

    String comments = '''
    // GENERATED CODE - DO NOT MODIFY BY HAND
    // **************************************************************************
    // This code was generated by Atom Generator tool.
    // **************************************************************************
    
    ''';

    CodeFormatter.formatAndBuild(
      specs: [
        Code(comments),
        ...importDirective,
        buildGlobalBinding,
        appRoutesClass,
        ...classes
      ],
      buildStep: buildStep,
    );
    return;
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['/generated/app_routes.dart'],
    };
  }

  getRouteArgs({required RouteParams routeParams}) {
    return "${routeParams.name}: Get.arguments['${routeParams.name}'] as ${routeParams.type}";
  }
}
