import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MyUser {
  String? _displayName;
  String? _photoURL;

  Future<UserResult?> loadUserData() async {
    // Note: The method is named loadUserData, not _loadUserData
    final firebase_auth.User? user =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        _displayName = userDoc.data()?['displayName'];
        _photoURL = userDoc.data()?['photoURL'];

        return UserResult(_displayName!, _photoURL!);
      }
    }
    return null;
  }
}

class UserResult {
  final String displayName;
  final String photoURL;

  UserResult(this.displayName, this.photoURL);
}
