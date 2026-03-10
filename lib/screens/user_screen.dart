import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/screens/auth/login_screen.dart';

import 'package:furkeeper/screens/home_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _saving = false;
  bool _dirty = false; // user started editing

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    setState(() => _saving = true);
    try {
      await _userDocRef(user.uid).set(
        {
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // upsert/merge [web:129]
      );

      if (!mounted) return;
      setState(() => _dirty = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${e.code}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _backToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _signOutToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    final docStream = _userDocRef(user.uid).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User'),
        actions: [
          TextButton(
            onPressed: (_saving || !_dirty) ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          // IMPORTANT: Prefill controllers ONLY when user hasn't started editing.
          if (!_dirty) {
            final first = (data?['firstName'] as String?) ?? '';
            final last = (data?['lastName'] as String?) ?? '';
            if (_firstNameController.text != first) _firstNameController.text = first;
            if (_lastNameController.text != last) _lastNameController.text = last;
          }

          final firstShown = (data?['firstName'] as String?) ?? '';
          final lastShown = (data?['lastName'] as String?) ?? '';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Email: ${user.email ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Saved in Firestore: $firstShown $lastShown'),
                const SizedBox(height: 16),

                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _dirty = true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _dirty = true),
                  onSubmitted: (_) => (_saving || !_dirty) ? null : _saveProfile(),
                ),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _backToHome,
                  child: const Text('Back to Home'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _signOutToLogin,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          );
        },
      ), // users/{uid} doc in a users collection is standard Firestore structure [web:134]
    );
  }
}
