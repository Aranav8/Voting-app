import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isEmailVerified() async {
    try {
      String? userId = getCurrentUserId();
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return data?['isEmailVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  Future<bool> isPanVerified() async {
    try {
      String? userId = getCurrentUserId();
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return data?['isPanVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking PAN verification: $e');
      return false;
    }
  }

  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      String? userId = getCurrentUserId();
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();

        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      String? userId = getCurrentUserId();
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update(data);
      }
    } catch (e) {
      print('Error updating user data: $e');
      throw e;
    }
  }
}
