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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'age': age,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> data) {
    final id = (data['id'] as num).toInt();
    final name = (data['name'] as String?) ?? '';
    final typeRaw = (data['type'] as String?) ?? '';
    final age = (data['age'] as num).toInt();

    final typeKey = _normalizeTypeKey(typeRaw);
    final animalType = _animalTypeFromType(typeKey);
    final subType = _subTypeFromType(animalType, typeKey);

    return Pet(
      id: id,
      name: name,
      type: typeKey,
      age: age,
      animalType: animalType,
      subType: subType,
    );
  }

  static String _normalizeTypeKey(String input) {
    final s = input.trim();
    if (s.isEmpty) throw ArgumentError('Pet type is empty');

    final lower = s.toLowerCase();

    const aliases = <String, String>{
      'guinea pig': 'gunineaPig',
      'guineapig': 'gunineaPig',
      'gunineapig': 'gunineaPig',
      'guninea pig': 'gunineaPig',
    };

    if (aliases.containsKey(lower)) return aliases[lower]!;
    return s;
  }

  static final Map<String, MammalType> _mammalByName =
      MammalType.values.asNameMap();
  static final Map<String, BirdType> _birdByName = BirdType.values.asNameMap();
  static final Map<String, ReptileType> _reptileByName =
      ReptileType.values.asNameMap();
  static final Map<String, FishType> _fishByName = FishType.values.asNameMap();

  static dynamic _subTypeFromType(AnimalType animalType, String typeKey) {
    switch (animalType) {
      case AnimalType.mammal:
        final v = _mammalByName[typeKey];
        if (v == null) throw ArgumentError('Unknown mammal type "$typeKey"');
        return v;
      case AnimalType.bird:
        final v = _birdByName[typeKey];
        if (v == null) throw ArgumentError('Unknown bird type "$typeKey"');
        return v;
      case AnimalType.reptile:
        final v = _reptileByName[typeKey];
        if (v == null) throw ArgumentError('Unknown reptile type "$typeKey"');
        return v;
      case AnimalType.fish:
        final v = _fishByName[typeKey];
        if (v == null) throw ArgumentError('Unknown fish type "$typeKey"');
        return v;
    }
  }

  static AnimalType _animalTypeFromType(String typeKey) {
    final t = typeKey.toLowerCase();

    switch (t) {
      case 'dog':
      case 'cat':
      case 'rabbit':
      case 'hamster':
      case 'gunineapig':
      case 'mouse':
        return AnimalType.mammal;

      case 'parrot':
      case 'canary':
      case 'finch':
      case 'budgie':
        return AnimalType.bird;

      case 'turtle':
      case 'gecko':
      case 'snake':
      case 'iguana':
        return AnimalType.reptile;

      case 'goldfish':
      case 'betta':
      case 'guppy':
      case 'tetra':
        return AnimalType.fish;

      default:
        if (_mammalByName.containsKey(typeKey)) return AnimalType.mammal;
        if (_birdByName.containsKey(typeKey)) return AnimalType.bird;
        if (_reptileByName.containsKey(typeKey)) return AnimalType.reptile;
        if (_fishByName.containsKey(typeKey)) return AnimalType.fish;
        throw ArgumentError('Unknown pet type "$typeKey"');
    }
  }
}

enum AnimalType { mammal, bird, reptile, fish }

enum MammalType {
  dog,
  cat,
  rabbit,
  hamster,
  gunineaPig,
  mouse,
}

enum BirdType {
  parrot,
  canary,
  finch,
  budgie,
}

enum ReptileType {
  turtle,
  gecko,
  snake,
  iguana,
}

enum FishType {
  goldfish,
  betta,
  guppy,
  tetra,
}
