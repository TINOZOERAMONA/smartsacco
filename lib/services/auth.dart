


// ignore_for_file: prefer_final_fields, avoid_print, duplicate_ignore

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService{
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch(e){
      // ignore: avoid_print
      print("Some error occured");
    }
    return null;
  }

  Future<User?> loginWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch(e){
      print("Some error occured");
    }
    return null;
  }
}

final FirebaseAuthService _authService = FirebaseAuthService();