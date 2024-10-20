import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

class CodeFormatter {
  static String format(
      {required Spec classBuilder, List<Directive> directives = const []}) {
    // Create the library and add the imports and class
    final library = Library((b) {
      b.body.addAll(directives);
      b.body.add(classBuilder);
    });

    // Generate the Dart code
    final emitter = DartEmitter();
    final code = DartFormatter().format('${library.accept(emitter)}');

    return code;
  }

  static formatAndBuild({
    required List<Spec> specs,
    required BuildStep buildStep,
  }) async {
    final Library routeLibrary = Library((builder) {
      builder.body.addAll(specs);
    });

    String formattedCode = CodeFormatter.format(classBuilder: routeLibrary);
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        p.join('lib', "generated", 'app_routes.dart'),
      ),
      formattedCode,
    );
  }
}
