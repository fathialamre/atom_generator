class RouteParams {
  final String name;
  final String type;
  final bool required;

  final bool nullable;
  final bool isNamed;

  RouteParams({
    required this.name,
    required this.type,
    required this.required,
    required this.nullable,
    required this.isNamed,
  });

  // fromJson: Create an instance from a JSON map
  factory RouteParams.fromJson(Map<String, dynamic> json) {
    return RouteParams(
      name: json['name'],
      type: json['type'],
      required: json['required'],
      nullable: json['nullable'],
      isNamed: json['isNamed'],
    );
  }

  // toJson: Convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'nullable': nullable,
      'isNamed': isNamed,
    };
  }

  // toMap: Convert the object to a Map (same as toJson in this case)
  Map<String, dynamic> toMap() {
    return toJson();
  }
}
