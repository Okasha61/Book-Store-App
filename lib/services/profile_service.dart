import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _profileDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to view your profile.');
    }

    final snapshot = await _profileDocument(user.uid).get();
    return snapshot.data();
  }

  Future<void> saveProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to update your profile.');
    }

    final trimmedName = name.trim();

    await _profileDocument(user.uid).set({
      'name': trimmedName,
      'phone': phone.trim(),
      'address': address.trim(),
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updateDisplayName(trimmedName);
    await user.reload();
  }
}
