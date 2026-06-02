// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String _userName = '';
  bool _isLoading = true;

  String get userName => _userName;
  bool get isLoading => _isLoading;

  Future<void> loadUserName() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (doc.exists) {
          _userName = doc.data()?['name'] ?? 'Usuário';
        } else {
          final email = FirebaseAuth.instance.currentUser?.email;
          _userName = email?.split('@')[0] ?? 'Usuário';
        }
      }
    } catch (e) {
      _userName = 'Usuário';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}