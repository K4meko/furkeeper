class Pet {
  static int _idCounter = 0;
  final String name;
  final String type;
  final int age;
  final AnimalType animalType;
  final dynamic subType;
  final int id;

    Pet({
    required this.name,
    required this.type,
    required this.age,
    required this.animalType,
    this.subType,
  }) : id = ++_idCounter;
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

