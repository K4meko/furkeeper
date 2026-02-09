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

  AnimalType? _animalType; // first dropdown
  String? _type; // second dropdown (enum .name), e.g. "dog"

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
    // typeStr is enum name like "dog", "parrot", ...
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

  Future<int> _getNextPetId() async {
    // Same counter-document approach as before (true autoincrement).
    final db = FirebaseFirestore.instance;
    final counterRef = db.collection('meta').doc('pets');

    return db.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);

      if (!snap.exists) {
        // If you already have 1..3, initialize this doc once to nextId=4.
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
    final typeStr = _type!; // already enum name
    final id = await _getNextPetId();

    final pet = Pet(
      id: id,
      name: _nameCtrl.text.trim(),
      type: typeStr.toLowerCase(),
      age: int.parse(_ageCtrl.text.trim()),
      animalType: animalType,
      subType: _subTypeFor(animalType, typeStr),
    );

    setState(() => _saving = true);
    try {
     
      // await FirebaseFirestore.instance
      //     .collection('pets')
      //     .doc(pet.id.toString())
      //     .set(pet.toMap());

      // if (!mounted) return;
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
                      _type = null; // reset subtype when animal type changes
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
                      : (v) => setState(() => _type = v),
                  validator: (v) {
                    if (_animalType == null) return 'Pick animal type first';
                    if (v == null || v.isEmpty) return 'Pick a subtype';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

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