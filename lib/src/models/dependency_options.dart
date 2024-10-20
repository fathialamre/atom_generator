class InjectionOptions {
  final bool singleton;
  final bool lazyPut;
  final bool ignoreInjection;
  final bool isGlobal;
  final String? tag;

  InjectionOptions({
    this.singleton = false,
    this.lazyPut = true,
    this.isGlobal = false,
    this.ignoreInjection = false,
    this.tag,
  });
}
