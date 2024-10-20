import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:atom_annotations/atom_annotations.dart';
import 'package:atom_generator/src/models/dependency_options.dart';
import 'package:atom_generator/src/models/route_dependency.dart';
import 'package:atom_generator/src/models/route_params.dart';
import 'package:atom_generator/src/utils/helpers.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker injectChecker = TypeChecker.fromRuntime(Inject);
const TypeChecker routeParamChecker = TypeChecker.fromRuntime(RouteParam);

class InjectionsResolver {
  static List<RouteDependency> resolveInjections({
    required ClassElement classElement,
  }) {
    List<RouteDependency> dependencies = [];

    var constructor = classElement.unnamedConstructor;
    throwIf(
      constructor == null,
      'Class ${classElement.name} must have a default constructor',
    );

    var classInjections = constructor?.parameters.where((
      param,
    ) {
      return injectChecker.hasAnnotationOf(param);
    }).toList();

    if (classInjections != null) {
      for (var injectedPram in classInjections) {
        var injectAnnotation = injectedPram.metadata.firstWhere(
          (item) {
            return item
                    .computeConstantValue()
                    ?.type
                    ?.getDisplayString(withNullability: false) ==
                'Inject';
          },
        );

        var findByTag = injectAnnotation
            .computeConstantValue()
            ?.getField('findByTag')
            ?.toStringValue();
        var findByParam = injectAnnotation
            .computeConstantValue()
            ?.getField('findByParam')
            ?.toBoolValue();

        var module = injectAnnotation
            .computeConstantValue()
            ?.getField('module')
            ?.toTypeValue()
            ?.element2;

        var moduleName = module?.name;

        var moduleUri = injectAnnotation
            .computeConstantValue()
            ?.getField('module')
            ?.toTypeValue()
            ?.element2
            ?.library
            ?.source
            .uri
            .toString();

        throwIf(
          !shouldInjectable(injectedPram, isModule: module != null),
          'This class is not has Injectable annotation ${injectedPram.type}',
        );

        InjectionOptions injectionOption =
            injectionOptions(injectedPram, module);
        var classElement = injectedPram.type.element2 as ClassElement;

        dependencies.add(RouteDependency(
            name: injectedPram.displayName,
            singleton: injectionOption.singleton,
            module: moduleName,
            ignoreInjection: injectionOption.ignoreInjection,
            moduleUri: moduleUri,
            isGlobal: injectionOption.isGlobal,
            importUri:
                injectedPram.type.element2?.library?.source.uri.toString() ??
                    '',
            type: injectedPram.type.getDisplayString(
              withNullability: false,
            ),
            tag: injectionOption.tag,
            findByTag: findByTag,
            findByParam: findByParam ?? false,
            dependencies: resolveInjections(
              classElement: classElement,
            ),
            isNamed: injectedPram.isNamed,
            routeParams: classElement.unnamedConstructor != null
                ? classElement.unnamedConstructor?.parameters
                    .where((param) => routeParamChecker.hasAnnotationOf(param))
                    .map(
                      (param) => RouteParams(
                        name: param.name,
                        type:
                            param.type.getDisplayString(withNullability: false),
                        required: param.isRequired,
                        nullable: param.type.nullabilitySuffix ==
                            NullabilitySuffix.question,
                        isNamed: param.isNamed,
                      ),
                    )
                    .toList()
                : []));
      }
    }
    //
    // if (classElement.isAbstract) {
    //
    // } else {
    //   dependencies.add(
    //     RouteDependency(
    //       name: classElement.displayName,
    //       importUri: classElement.library.source.uri.toString(),
    //       type: classElement.thisType.getDisplayString(withNullability: false),
    //       tag: null,
    //       isNamed: false,
    //     ),
    //   );
    // }

    return dependencies;
  }

  static shouldInjectable(ParameterElement parameter, {bool isModule = false}) {
    if (isModule) {
      return true;
    }
    ClassElement classElement = parameter.type.element2 as ClassElement;

    ElementAnnotation? annotation;
    try {
      annotation = classElement.metadata.firstWhere(
        (item) {
          return item
                  .computeConstantValue()
                  ?.type
                  ?.getDisplayString(withNullability: false) ==
              'Injectable';
        },
      );
    } catch (e) {
      annotation = null; // No annotation found
    }

    if (annotation != null) {
      return true;
    }
    return false;
  }

  static InjectionOptions injectionOptions(
      VariableElement param, Element? module) {
    ClassElement classElement = param.type.element2 as ClassElement;

    if (module != null) {
      classElement = module as ClassElement;
    }

    ElementAnnotation? annotation;
    try {
      annotation = classElement.metadata.firstWhere(
        (item) {
          return item
                  .computeConstantValue()
                  ?.type
                  ?.getDisplayString(withNullability: false) ==
              'Injectable';
        },
      );
    } catch (e) {
      annotation = null; // No annotation found
    }

    if (annotation != null) {
      var annotationObject = annotation.computeConstantValue();

      return InjectionOptions(
        singleton:
            annotationObject?.getField('singleton')?.toBoolValue() ?? false,
        lazyPut: annotationObject?.getField('lazyPut')?.toBoolValue() ?? true,
        isGlobal:
            annotationObject?.getField('isGlobal')?.toBoolValue() ?? false,
        tag: annotationObject?.getField('tag')?.toStringValue(),
        ignoreInjection:
            annotationObject?.getField('ignoreInjection')?.toBoolValue() ??
                false,
      );
    }
    return InjectionOptions();
  }
}
