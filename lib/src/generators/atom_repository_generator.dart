import 'package:analyzer/dart/element/element.dart';
import 'package:atom_annotations/atom_annotations.dart';
import 'package:atom_generator/src/utils/code_formater.dart';
import 'package:atom_generator/src/utils/helpers.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

class AtomRepositoryGenerator extends GeneratorForAnnotation<Repository> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.displayName}`.',
      );
    }

    final clazz = element;

    final methods = clazz.methods;

    final m = getMethod(clazz: clazz);

    final factoryParams = clazz.constructors
        .where((e) => e.isFactory)
        .first
        .parameters
        .map((e) => e)
        .toList();

    final clazzMethods = clazz.methods;

    var repository = Class((b) => b
      ..implements.add(refer(clazz.name))
      ..fields.addAll(factoryParams.map((e) => Field((f) => f
        ..name = '_${e.name}'
        ..type = refer(e.type.getDisplayString(withNullability: false))
        ..modifier = FieldModifier.final$)))
      ..constructors.add(Constructor((c) => c
        ..requiredParameters.addAll(
          clazz.constructors.first.parameters.map(
            (e) => Parameter(
              (p) => p
                ..name = '_${e.name}'
                ..annotations.add(refer('Inject').call([]))
                ..toThis = true,
            ),
          ),
        )))
      ..methods.addAll(m)
      ..name = '_${element.name}');

    final libraryBuilder = Library((b) => b..body.addAll([repository]));

    return CodeFormatter.format(classBuilder: libraryBuilder);
  }

  List<Method> getMethod({required ClassElement clazz}) {
    List<Method> allMethods = [];
    for (var element in clazz.methods) {
      allMethods.add(_createMethod(clazz, element));
    }

    return allMethods;
  }

  /// Creates a Method instance for the given element name and method.
  Method _createMethod(ClassElement clazz, MethodElement method) {
    return Method((m) => m
      ..name = method.name
      ..annotations.add(refer('override')) // Mark method as override
      ..returns =
          refer('${method.type.returnType}') // Future Either return type
      ..modifier = MethodModifier.async // Mark method as async
      ..optionalParameters.addAll(
          _createOptionalParameters(method.parameters)) // Add parameters
      ..body = _createMethodBody(clazz, method)); // Create method body
  }

  /// Creates a list of optional parameters from the method parameters.
  Iterable<Parameter> _createOptionalParameters(
      List<ParameterElement> parameters) {
    return parameters.map((param) => Parameter((p) => p
      ..name = param.name
      ..named = true
      ..required = true
      ..type = refer(param.type.toString())));
  }

  /// Creates the method body for the generated method.
  Block _createMethodBody(ClassElement clazz, MethodElement method) {
    final parameterAssignments =
        method.parameters.map((e) => '${e.name}: ${e.name}').join(', ');

    throwIf(method.metadata.isEmpty,
        'Method must have a Trigger annotation to be generated.');

    final methodAnnotation = method.metadata.firstWhere((e) =>
        e
            .computeConstantValue()
            ?.type
            ?.getDisplayString(withNullability: false) ==
        'Trigger');

    var serviceClazz = methodAnnotation
        .computeConstantValue()
        ?.getField('service')
        ?.toTypeValue()
        ?.element;

    //TODO: Check if service has Injectable annotation
    var serviceName = '';
    clazz.constructors.where((e) => e.isFactory).first.parameters.forEach((e) {
      if (serviceClazz?.name.toString() == e.type.toString()) {
        serviceName = e.name;
      }
    });

    return Block((b) => b.statements.addAll([
          const Code('try {'),
          // Await the async call and assign to a variable
          refer('final response')
              .assign(
                refer(
                    'await _$serviceName.${method.name}($parameterAssignments)'),
              )
              .statement,
          // Wrap the response in Either.right
          refer('right').call([refer('response')]).returned.statement,
          const Code('} on Exception catch (error) {'),
          // Handle exception and wrap in Either.left
          refer('left')
              .call([refer('ExceptionHandler.handleError(error)')])
              .returned
              .statement,
          const Code('}'),
        ]));
  }
}
