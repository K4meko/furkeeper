import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/others/notificaton_service.dart';
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

  DateTime _selectedVetDate = DateTime.now();

  bool _changed = false;
  bool _editMode = false;

  bool _savingName = false;
  bool _loggingWalk = false;
  bool _loggingVet = false;
  bool _deleting = false;

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

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
    });
    if (!_editMode) FocusScope.of(context).unfocus();
  }

  // NEW: Method to show the date picker
  Future<void> _pickVetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedVetDate,
      firstDate: DateTime(2000), // Allow past dates for logging history
      lastDate: DateTime(2100),  // Allow future dates for scheduling
    );
    if (picked != null && picked != _selectedVetDate) {
      setState(() {
        _selectedVetDate = picked;
      });
    }
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _savingName = true;
    });

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
      if (!mounted) return;
      setState(() {
        _savingName = false;
      });
    }
  }

  Future<void> _logWalk() async {
    final notes = _walkNotesCtrl.text.trim();

    setState(() {
      _loggingWalk = true;
    });

    try {
      await _walksRef.doc().set({
        'at': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      _changed = true;
      _walkNotesCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Walk added')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed (${e.code}): ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to log walk: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _loggingWalk = false;
      });
    }
  }

    Future<void> _logVetVisit() async {
    final notes = _vetNotesCtrl.text.trim();
    final petName = _nameCtrl.text.trim(); // Grab the pet's name for the alert

    setState(() {
      _loggingVet = true;
    });

    try {
      await _vetRef.doc().set({
        'at': Timestamp.fromDate(_selectedVetDate),
        'notes': notes,
      });

      //final notifyTime = DateTime.now().add(const Duration(seconds: 10));
       final notifyTime = _selectedVetDate.subtract(const Duration(days: 1));

      
      if (notifyTime.isAfter(DateTime.now())) {
       
        final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
        
        await NotificationService.scheduleNotification(
          id: notificationId,
          title: 'Upcoming Vet Visit for ${petName.isEmpty ? 'your pet' : petName}',
          body: 'Reminder: $notes is scheduled for tomorrow!',
          scheduledDate: notifyTime,
        );
      }
      // ----------------------------------

      _changed = true;
      _vetNotesCtrl.clear();
      
      setState(() {
        _selectedVetDate = DateTime.now();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vet visit added & reminder set')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed (${e.code}): ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to log vet visit: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _loggingVet = false;
      });
    }
  }


  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> col, {
    int batchSize = 200,
  }) async {
    while (true) {
      final snap = await col.limit(batchSize).get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deletePet() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pet?'),
        content: const Text('This will delete the pet and its logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _deleting = true;
    });

    try {
      await _deleteSubcollection(_walksRef);
      await _deleteSubcollection(_vetRef);
      await _petRef.delete();

      _changed = true;
      if (!mounted) return;
      Navigator.pop(context, true); 
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed (${e.code}): ${e.message}')),
      ); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _deleting = false;
      });
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
     
      return ts.toDate().toLocal().toString().split('.')[0];
    }
    return '';
  }

  bool get _busy =>
      _savingName || _loggingWalk || _loggingVet || _deleting;

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
          actions: [
            if (_editMode)
              IconButton(
                tooltip: 'Delete pet',
                icon: _deleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete),
                onPressed: (_busy && !_deleting) ? null : () async {
                  if (_deleting) return;
                  await _deletePet();
                },
              ),
            IconButton(
              tooltip: _editMode ? 'Done' : 'Edit',
              icon: Icon(_editMode ? Icons.check : Icons.edit),
              onPressed: _deleting
                  ? null
                  : () async {
                      if (_editMode) {
                        await _saveName();
                        if (!mounted) return;
                      }
                      _toggleEditMode();
                    },
            ),
          ],
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

            if (!_editMode && _nameCtrl.text != name) {
              _nameCtrl.text = name;
            }
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = name;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Type: $type'),
                Text('Age: ${age.toInt()}'),
                const SizedBox(height: 16),

                TextField(
                  controller: _nameCtrl,
                  readOnly: !_editMode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) async {
                    if (!_editMode || _savingName || _deleting) return;
                    await _saveName();
                  },
                ),
                const SizedBox(height: 24),

                const Text('Log a walk', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _walkNotesCtrl,
                  enabled: _editMode && !_deleting,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: (!_editMode || _loggingWalk || _deleting)
                      ? null
                      : () async {
                          await _logWalk();
                        },
                  child: _loggingWalk
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add walk'),
                ),
                const SizedBox(height: 24),

                const Text('Log a vet visit / Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _vetNotesCtrl,
                  enabled: _editMode && !_deleting,
                  decoration: const InputDecoration(
                    labelText: 'Notes (e.g., Upcoming Vaccination)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                
                
                if (_editMode && !_deleting)
                  Row(
                    children: [
                      Text(
                        'Date: ${_selectedVetDate.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickVetDate,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Change Date'),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: (!_editMode || _loggingVet || _deleting)
                      ? null
                      : () async {
                          await _logVetVisit();
                        },
                  child: _loggingVet
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save vet visit'),
                ),
                const SizedBox(height: 24),

                const Text('Recent walks', style: TextStyle(fontWeight: FontWeight.bold)),
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

                const Text('Vet visits (Past & Upcoming)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _vetRef
                      .orderBy('at', descending: true) // Will show future dates at the top
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
                          leading: const Icon(Icons.medical_services_outlined),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
