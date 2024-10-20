import 'package:atom_generator/src/generators/atom_repository_generator.dart';
import 'package:atom_generator/src/generators/atom_routes_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/atom_route_scanner.dart';

Builder atomRepositoryGenerator(BuilderOptions options) =>
    PartBuilder([AtomRepositoryGenerator()], '.repo.dart');

Builder atomRoutesBuilder(BuilderOptions options) {
  return AtomRoutesGenerator();
}

Builder atomRouteScanner(BuilderOptions options) {
  return AtomRouteScanner();
}
