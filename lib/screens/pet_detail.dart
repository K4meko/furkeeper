import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/viewmodels/db.dart';

class PetDetailScreen extends StatefulWidget {
  final String petDocId;
  const PetDetailScreen({super.key, required this.petDocId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _walkNotesCtrl = TextEditingController();
  final _vetNotesCtrl = TextEditingController();

  bool _savingName = false;
  bool _loggingWalk = false;
  bool _loggingVet = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _petRef =>
      db.collection('users').doc(_uid).collection('pets').doc(widget.petDocId);

  CollectionReference<Map<String, dynamic>> get _walksRef =>
      _petRef.collection('walks');

  CollectionReference<Map<String, dynamic>> get _vetRef =>
      _petRef.collection('vetVisits');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _walkNotesCtrl.dispose();
    _vetNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    setState(() => _savingName = true);
    try {
      await _petRef.update({'name': newName});
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _logWalk() async {
    setState(() => _loggingWalk = true);
    try {
      await _walksRef.doc().set({
        'at': FieldValue.serverTimestamp(),
        'notes': _walkNotesCtrl.text.trim(),
      });
      _walkNotesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to log walk: $e')));
    } finally {
      if (mounted) setState(() => _loggingWalk = false);
    }
  }

  Future<void> _logVetVisit() async {
    setState(() => _loggingVet = true);
    try {
      await _vetRef.doc().set({
        'at': FieldValue.serverTimestamp(),
        'notes': _vetNotesCtrl.text.trim(),
      });
      _vetNotesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to log vet visit: $e')));
    } finally {
      if (mounted) setState(() => _loggingVet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pet details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _petRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Pet not found'));
          }

          final data = snap.data!.data()!;
          final name = (data['name'] ?? '') as String;
          final type = (data['type'] ?? '') as String;
          final age = (data['age'] ?? 0) as num;

          if (_nameCtrl.text.isEmpty) _nameCtrl.text = name;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Type: $type'),
              Text('Age: ${age.toInt()}'),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pet name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _savingName ? null : _saveName,
                child: _savingName
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save name'),
              ),
              const SizedBox(height: 24),
              const Text('Log a walk'),
              const SizedBox(height: 8),
              TextField(
                controller: _walkNotesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loggingWalk ? null : _logWalk,
                child: const Text('Add walk'),
              ),
              const SizedBox(height: 24),
              const Text('Log a vet visit'),
              const SizedBox(height: 8),
              TextField(
                controller: _vetNotesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loggingVet ? null : _logVetVisit,
                child: const Text('Add vet visit'),
              ),
              const SizedBox(height: 24),
              const Text('Recent walks'),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _walksRef
                    .orderBy('at', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, s) {
                  if (s.hasError) return Text('Error: ${s.error}');
                  if (!s.hasData) return const Text('Loading...');
                  final docs = s.data!.docs;
                  if (docs.isEmpty) return const Text('No walks yet');
                  return Column(
                    children: [
                      for (final d in docs)
                        ListTile(
                          title: Text((d.data()['notes'] ?? '') as String),
                          subtitle: Text(d.data()['at']?.toString() ?? ''),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Recent vet visits'),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _vetRef
                    .orderBy('at', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, s) {
                  if (s.hasError) return Text('Error: ${s.error}');
                  if (!s.hasData) return const Text('Loading...');
                  final docs = s.data!.docs;
                  if (docs.isEmpty) return const Text('No vet visits yet');
                  return Column(
                    children: [
                      for (final d in docs)
                        ListTile(
                          title: Text((d.data()['notes'] ?? '') as String),
                          subtitle: Text(d.data()['at']?.toString() ?? ''),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
