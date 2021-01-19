import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  GoogleSignIn googleSignIn = GoogleSignIn();

  AuthenticationService(this._firebaseAuth);

  Stream<User> get authStateChanges => _firebaseAuth.authStateChanges();

  void signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String> signinWithGoogle() async {
    try {
      GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      // final User user = authResult.user;

      // Create user in Firestore
      // 1) check if user exists in firestore
      final GoogleSignInAccount user = googleSignIn.currentUser;
      DocumentSnapshot doc = await usersRef.doc(user.id).get();

      if (!doc.exists) {
        // 3) get username from account and make user document in users collection
        usersRef.doc(user.id).set({
          'id': user.id,
          'photoUrl': user.photoUrl,
          'email': user.email,
          'displayName': user.displayName,
          'timestamp': DateTime.now()
        });
      }
      return 'Signed in with Google';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
