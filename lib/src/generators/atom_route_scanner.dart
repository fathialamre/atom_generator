import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:atom_annotations/atom_annotations.dart';
import 'package:atom_generator/src/models/route_dependency.dart';
import 'package:atom_generator/src/models/route_item.dart';
import 'package:atom_generator/src/models/route_params.dart';
import 'package:atom_generator/src/resolvers/injections_resolver.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

// Define TypeChecker for RouteParam
const TypeChecker routeParamChecker = TypeChecker.fromRuntime(RouteParam);
const TypeChecker injectChecker = TypeChecker.fromRuntime(Inject);

class AtomRouteScanner extends Builder {
  void addDependenciesToImports(RouteDependency dep, Set<String> imports) {
    // Add the import URI of the current dependency
    imports.add(dep.importUri);
    if (dep.moduleUri != null) {
      imports.add(dep.moduleUri!);
    }

    // Recursively add the import URIs of nested dependencies
    if (dep.dependencies != null && dep.dependencies!.isNotEmpty) {
      for (var nestedDep in dep.dependencies!) {
        addDependenciesToImports(nestedDep, imports);
      }
    }
  }


  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;

    LibraryElement libraryElement = await buildStep.resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: true,
    );

    LibraryReader libraryReader = LibraryReader(libraryElement);

    for (AnnotatedElement annotatedElement in libraryReader.annotatedWith(
      const TypeChecker.fromRuntime(PageRouter),
      throwOnUnresolved: true,
    )) {
      if (annotatedElement.element is ClassElement) {
        ClassElement classElement = annotatedElement.element as ClassElement;
        final ConstantReader screenAnnotation = annotatedElement.annotation;

        final String routePath = screenAnnotation.read("path").stringValue;
        final bool initialRoute =
            screenAnnotation.read("initialRoute").boolValue;

        Set<String> imports = {};

        List<RouteParams> routeParams = resolveClassParams(
          classElement: classElement,
        );

        List<RouteDependency> pageDependencies =
            InjectionsResolver.resolveInjections(
          classElement: classElement,
        );

        for (RouteDependency dep in pageDependencies) {
          addDependenciesToImports(dep, imports);
        }

        final String? sourcePath =
            annotatedElement.element.source?.fullName.split('/lib/')[1];
        if (sourcePath != null) {
          imports.add("package:${buildStep.inputId.package}/$sourcePath");
        }

        RouteItem item = RouteItem(
          routeName: routePath,
          imports: imports,
          initialRoute: initialRoute,
          routeParams: routeParams,
          className: classElement.name,
          dependencies: pageDependencies,
        );

        print('============ITEMS');
        print(item.toJson());
        print('============ITEMS');

        buildStep.writeAsString(
          buildStep.inputId.changeExtension(
            ".routes.json",
          ),
          jsonEncode(
            item.toJson(),
          ),
        );
      }
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        ".dart": [".routes.json"]
      };

  List<RouteParams> resolveClassParams({
    required ClassElement classElement,
  }) {
    return classElement.constructors.first.parameters
        .where((param) => routeParamChecker.hasAnnotationOf(param))
        .map(
          (param) => RouteParams(
            name: param.name,
            type: param.type.getDisplayString(withNullability: false),
            required: param.isRequired,
            nullable:
                param.type.nullabilitySuffix == NullabilitySuffix.question,
            isNamed: param.isNamed,
          ),
        )
        .toList();
  }
}
