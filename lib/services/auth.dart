import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _log = Logger('FirebaseAuthService');

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _log.warning("Registration failed: ${e.code} - ${e.message}");
    } catch (e) {
      _log.warning("Unexpected registration error: $e");
    }
    return null;
  }

  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _log.warning("Login failed: ${e.code} - ${e.message}");
    } catch (e) {
      _log.warning("Unexpected login error: $e");
    }
    return null;
  }
}
