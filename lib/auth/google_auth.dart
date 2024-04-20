import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart' as main;
import 'package:flutter_application_1/analytics/analytics_service.dart';

class GoogleAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  String? name;
  String? email;
  String? imageUrl;
  String errorMsg = "";
  bool isLoggedIn = false;
  bool isLoading = false;

  Future<String> signInWithGoogle() async {
    isLoading = true;
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult = await _auth.signInWithCredential(credential);
    final User? user = authResult.user;
    if (user != null) {
      name = user.displayName;
      email = user.email;
      
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: user.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      if (documents.isEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'id': user.uid,
          'createdAt': DateTime.now().toIso8601String(),
          'premium': false,
        });
      }
      
      await main.prefs.setString('id', user.uid);
      await main.prefs.setString('name', user.displayName ?? "");
      await main.prefs.setString('email', user.email ?? "");
      await main.prefs.setString('logged', "true");
      await main.prefs.setBool('premium', documents.isNotEmpty && documents[0]['premium'] ?? false);
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('googlename', user.displayName ?? "");
      prefs.setString('googleemail', user.email ?? "");
      prefs.setString('googleimage', user.photoURL ?? "");
      
      analytics.logLogin();
      isLoading = false;
      
      return 'signInWithGoogle succeeded: $user';
    } else {
      isLoading = false;
      return 'signInWithGoogle failed';
    }
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('googlename', "");
    prefs.setString('googleemail', "");
    prefs.setString('googleimage', "");
    prefs.setString('id', "");
    prefs.setString('name', "");
    prefs.setString('email', "");
    prefs.setString('logged', "false");
    prefs.setBool('premium', false);
    
    print("User Sign Out");
  }

  Future<bool> isSignedIn() async {
    return await googleSignIn.isSignedIn();
  }
}
