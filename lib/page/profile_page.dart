import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void initState() {
    refresh();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final String? googleClientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? "";
    final GoogleSignIn googleSignIn = GoogleSignIn(clientId: googleClientId);

    // print(googleClientId);

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        // Get user details
        final User? user = userCredential.user;
        if (user != null) {
          // Save user data to Firestore
          final FirebaseFirestore firestore = FirebaseFirestore.instance;

          final uid = user.uid;
          final userDoc = await firestore.collection('users').doc(uid).get();

          final chatHistoryJson =
              userDoc.data()?['chatHistory'] as String? ?? "";

          try {
            await firestore.collection('users').doc(user.uid).set({
              'chatHistory': chatHistoryJson,
              'uid': user.uid,
              'displayName': user.displayName,
              'email': user.email,
              'photoURL': user.photoURL,
              'providerData': user.providerData
                  .map((info) => {
                        'providerId': info.providerId,
                        'uid': info.uid,
                        'displayName': info.displayName,
                        'email': info.email,
                        'photoURL': info.photoURL,
                      })
                  .toList(),
            });
            // print("User data saved to Firestore");
            // const ChatScreen();
            Navigator.pushReplacementNamed(context, '/');
          } catch (e) {
            // print("Error saving user data to Firestore: $e");
          }
        } else {
          // print("User is null after Google sign-in");
        }
      }
    } catch (e) {
      // print("Error during Google sign-in: $e");
    }
  }

  void refresh() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // print(user);
    }
  }

  // Future<void> _signInAnonymously(BuildContext context) async {
  //   try {
  //     final userCredential = await FirebaseAuth.instance.signInAnonymously();
  //     // print("Signed in with temporary account.");
  //     Navigator.pushReplacementNamed(context, '/chat');
  //   } on FirebaseAuthException catch (e) {
  //     switch (e.code) {
  //       case "operation-not-allowed":
  //         // print("Anonymous auth hasn't been enabled for this project.");
  //         break;
  //       default:
  //         // print("Error during anonymous sign-in: ${e.message}");
  //     }
  //   }
  // }

  // Fungsi untuk menampilkan dialog konfirmasi sebelum menghapus chat history
  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text('Are you sure you want to Logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _logout(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(50, 0, 0, 0)
              : const Color.fromARGB(50, 255, 255, 255),
          // title: const Text('Profile'),
          actions: user != null
              ? [
                  const Text("Logout"),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _confirmLogout(context),
                    tooltip: "Logout",
                  ),
                ]
              : null,
        ),
        body: Center(
          child: user != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user.photoURL != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(user.photoURL!),
                        radius: 50,
                      ),
                    const SizedBox(height: 16),
                    Text('Name: ${user.displayName ?? 'Anonymous'}'),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email ?? 'Anonymous'}'),
                    const SizedBox(height: 8),
                    Text('User ID: ${user.uid}'),
                    const SizedBox(height: 8),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Login to save your chat history and access additional features!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _signInWithGoogle(context),
                      icon: SvgPicture.asset(
                        'images/google_logo.svg', // Ensure you have this image in your assets
                        height: 40,
                        color: // Theme.of(context).brightness == Brightness.dark
                            Colors.white70,
                        // : Colors.black87,
                      ),
                      label: Text(
                        'Login with Google',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(150, 255, 255, 255)
                              : const Color.fromARGB(150, 0, 0, 0),
                          fontSize: 18,
                        ),
                      ),
                      // style: ElevatedButton.styleFrom(
                      //   // primary: Colors.white,
                      //   // onPrimary: Colors.black,
                      //   side: BorderSide(
                      //     color: Theme.of(context).brightness == Brightness.dark
                      //         ? Colors.black45
                      //         : Colors.white70,
                      //   ),
                      //   elevation: 2,
                      // ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
