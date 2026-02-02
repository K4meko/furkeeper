class Pet {
  final int id;
  final String name;
  final String type;
  final int age;

  final AnimalType animalType;
  final dynamic subType;

  const Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.animalType,
    this.subType,
  });

  factory Pet.fromMap(Map<String, dynamic> data) {
    final typeStr = (data['type'] as String).toLowerCase();
    final animalType = _animalTypeFromType(typeStr);
    final subType = _subTypeFromType(animalType, typeStr);

    return Pet(
      id: (data['id'] as num).toInt(),
      name: data['name'] as String,
      type: typeStr,
      age: (data['age'] as num).toInt(),
      animalType: animalType,
      subType: subType,
    );
  }
  static dynamic _subTypeFromType(AnimalType animalType, String typeStr) {
    switch (animalType) {
      case AnimalType.mammal:
        return MammalType.values.byName(typeStr);
      case AnimalType.bird:
        return BirdType.values.byName(typeStr);
      case AnimalType.reptile:
        return ReptileType.values.byName(typeStr);
      case AnimalType.fish:
        return FishType.values.byName(typeStr);
    }
  }
    static AnimalType _animalTypeFromType(String type) {
    switch (type) {
      case 'dog':
      case 'cat':
        return AnimalType.mammal;
      // add the rest...
      default:
        throw ArgumentError('Unknown pet type "$type"');
    }
  }
}

enum AnimalType {
  mammal,
  bird,
  reptile,
  fish,
}

// Subtypes for Mammals
enum MammalType{
  dog,
  cat,
  rabbit,
  hamster,
  gunineaPig,
  mouse,

}
// Subtypes for Birds
enum BirdType {
  parrot,
  canary,
  finch,
  budgie,
}

// Subtypes for Reptiles
enum ReptileType {
  turtle,
  gecko,
  snake,
  iguana,

}

// Subtypes for Fish
enum FishType {
  goldfish,
  betta,
  guppy,
  tetra,
}

