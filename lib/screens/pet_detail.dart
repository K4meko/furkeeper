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
  bool _changed = false;
  bool _savingName = false;
  bool _loggingWalk = false;
  bool _loggingVet = false;

  Future<DocumentSnapshot<Map<String, dynamic>>>? _petFuture;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _petRef =>
      db.collection('users').doc(_uid).collection('pets').doc(widget.petDocId);

  CollectionReference<Map<String, dynamic>> get _walksRef =>
      _petRef.collection('walks');

  CollectionReference<Map<String, dynamic>> get _vetRef =>
      _petRef.collection('vetVisits');

  @override
  void initState() {
    super.initState();
    _petFuture = _petRef.get();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _walkNotesCtrl.dispose();
    _vetNotesCtrl.dispose();
    super.dispose();
  }

  void _refreshPet() {
  setState(() {
    _petFuture = _petRef.get();
  });
}


Future<void> _saveName() async {  
  
  final newName = _nameCtrl.text.trim();
  if (newName.isEmpty) return;

  setState(() => _savingName = true);
  try {
    await _petRef.update({'name': newName});
    _changed = true;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _refreshPet();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Name updated')));
  } on FirebaseException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed (${e.code}): ${e.message}')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Failed: $e')));
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

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return ts.toDate().toLocal().toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
  title: const Text('Pet details'),
  leading: BackButton(
    onPressed: () => Navigator.pop(context, _changed),
  ),
),

        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _petFuture,
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

            // Only initialize once; never push Firestore values into the controller during rebuilds.
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = name;

            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result){
               if (didPop && result == null) {
       Navigator.of(context).pop(_changed);
}

                
              },
              child: ListView(
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
                    textInputAction: TextInputAction.done,
                   onSubmitted: (_) async {
                    if (_savingName) return;
                    await _saveName();
              },  
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
                    child: _loggingWalk
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add walk'),
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
                    child: _loggingVet
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add vet visit'),
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
              
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          return ListTile(
                            title: Text((d['notes'] ?? '') as String),
                            subtitle: Text(_formatTimestamp(d['at'])),
                          );
                        },
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
              
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          return ListTile(
                            title: Text((d['notes'] ?? '') as String),
                            subtitle: Text(_formatTimestamp(d['at'])),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
