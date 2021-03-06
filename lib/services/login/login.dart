import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();
final CollectionReference usersRef = Firestore.instance.collection('users');

Future<FirebaseUser> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final AuthResult authResult = await _auth.signInWithCredential(credential);
  final FirebaseUser user = authResult.user;

  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);
  assert(await user.displayName != null);
  assert(await user.email != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  final snapShot = await usersRef.document(user.uid).get();

  if (snapShot == null || !snapShot.exists) {
    var userData = {
      'name': user.displayName,
      'email': user.email,
    };

    var categoryData = {'color': 'ff9e9e9e'};

    await usersRef.document(user.uid).setData(userData);
    await usersRef
        .document(user.uid)
        .collection('categories')
        .document('uncategorized')
        .setData(categoryData); // create a default category
  }

  return user;
}

Future<String> signUp(email, password) async {
  try {
    final AuthResult authResult = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final FirebaseUser user = authResult.user;

    assert(user != null);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    var userData = {
      'email': email,
      'password': password,
    };

    var categoryData = {'color': 'ff9e9e9e'};

    await usersRef.document(user.uid).setData(userData);
    await usersRef
        .document(user.uid)
        .collection('categories')
        .document('uncategorized')
        .setData(categoryData); // create a default category

  } catch (error) {
    return error.message;
  }
  return 'success';
}

Future<String> signIn(String email, String password) async {
  try {
    final AuthResult authResult = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final FirebaseUser user = authResult.user;

    assert(user != null);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
  } catch (error) {
    return error.message;
  }
  return 'success';
}

Future<String> sendPasswordResetEmail(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email);
  } catch (error) {
    return error.message;
  }
  return 'success';
}

Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.signOut();
  } catch (error) {
    print(error); // TODO: show dialog with error
  }
}
