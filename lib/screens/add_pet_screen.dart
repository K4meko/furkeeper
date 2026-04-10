import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/models/pet.dart';
import 'package:furkeeper/models/petservice.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final petService = PetService();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  AnimalType? _animalType;
  String? _type;
  String? _breed; // ← new

  // Common dog breeds — extend as needed
  static const _dogBreeds = [
    'Labrador Retriever',
    'German Shepherd',
    'Golden Retriever',
    'French Bulldog',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Dachshund',
    'Siberian Husky',
    'Shih Tzu',
    'Chihuahua',
    'Boxer',
    'Border Collie',
    'Mixed / Other',
  ];

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  List<String> _typesFor(AnimalType? a) {
    if (a == null) return const [];
    switch (a) {
      case AnimalType.mammal:
        return MammalType.values.map((e) => e.name).toList();
      case AnimalType.bird:
        return BirdType.values.map((e) => e.name).toList();
      case AnimalType.reptile:
        return ReptileType.values.map((e) => e.name).toList();
      case AnimalType.fish:
        return FishType.values.map((e) => e.name).toList();
    }
  }

  dynamic _subTypeFor(AnimalType animalType, String typeStr) {
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

  bool get _isDog => _type == 'dog';

  Future<int> _getNextPetId() async {
    final db = FirebaseFirestore.instance;
    final counterRef = db.collection('meta').doc('pets');

    return db.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      if (!snap.exists) {
        tx.set(counterRef, {'nextId': 5}, SetOptions(merge: true));
        return 4;
      }
      final current = (snap.data()!['nextId'] as num).toInt();
      tx.update(counterRef, {'nextId': current + 1});
      return current;
    });
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final animalType = _animalType!;
    final typeStr = _type!;
    final id = await _getNextPetId();

    final pet = Pet(
      id: id,
      name: _nameCtrl.text.trim(),
      type: typeStr.toLowerCase(),
      age: int.parse(_ageCtrl.text.trim()),
      animalType: animalType,
      subType: _subTypeFor(animalType, typeStr),
      breed: _isDog ? _breed : null, // ← pass breed only for dogs
    );

    setState(() => _saving = true);
    try {
      await petService.savePetForCurrentUser(pet.toMap());
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtypeItems = _typesFor(_animalType);

    return Scaffold(
      appBar: AppBar(title: const Text('Add pet')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final txt = (v ?? '').trim();
                    if (txt.isEmpty) return 'Enter a name';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _ageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final txt = (v ?? '').trim();
                    if (txt.isEmpty) return 'Enter age';
                    final age = int.tryParse(txt);
                    if (age == null) return 'Age must be a number';
                    if (age < 0 || age > 80) return 'Enter a realistic age';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<AnimalType>(
                  value: _animalType,
                  decoration: const InputDecoration(
                    labelText: 'Animal type',
                    border: OutlineInputBorder(),
                  ),
                  items: AnimalType.values
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _animalType = v;
                      _type = null;
                      _breed = null; // reset breed when animal type changes
                    });
                  },
                  validator: (v) => v == null ? 'Pick an animal type' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Subtype',
                    border: OutlineInputBorder(),
                  ),
                  items: subtypeItems
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: _animalType == null
                      ? null
                      : (v) => setState(() {
                            _type = v;
                            _breed = null; // reset breed if subtype changes
                          }),
                  validator: (v) {
                    if (_animalType == null) return 'Pick animal type first';
                    if (v == null || v.isEmpty) return 'Pick a subtype';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

               AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: _isDog
                    ? Column(
                        key: const ValueKey('breed-field'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4), // breathing room for the floating label
                          DropdownButtonFormField<String>(
                            value: _breed,
                            decoration: const InputDecoration(
                              labelText: 'Breed',
                              border: OutlineInputBorder(),
                            ),
                            items: _dogBreeds
                                .map((b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _breed = v),
                            validator: (v) {
                              if (!_isDog) return null;
                              if (v == null || v.isEmpty) return 'Pick a breed';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('no-breed')),
              ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}