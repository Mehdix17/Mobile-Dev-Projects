import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      
      // Create user document for anonymous user
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }
      
      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    bool sendVerificationEmail = true,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName.trim());

      // Send email verification
      if (sendVerificationEmail && credential.user != null) {
        await credential.user!.sendEmailVerification();
      }

      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign in aborted';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create user document if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Convert anonymous account to permanent account OR create new account
  Future<UserCredential> linkAnonymousToEmailPassword({
    required String email,
    required String password,
    required String displayName,
    bool sendVerificationEmail = true,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      
      // If user is anonymous, link the account
      if (currentUser != null && currentUser.isAnonymous) {
        // Create email credential
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );

        // Link the anonymous account with email/password
        final userCredential = await currentUser.linkWithCredential(credential);

        // Update display name
        await userCredential.user?.updateDisplayName(displayName.trim());

        // Send email verification
        if (sendVerificationEmail && userCredential.user != null) {
          await userCredential.user!.sendEmailVerification();
        }

        // Update user document
        await _updateUserDocument(userCredential.user!);

        return userCredential;
      } else {
        // If not anonymous, create a new account
        return await signUpWithEmailPassword(
          email: email,
          password: password,
          displayName: displayName,
          sendVerificationEmail: sendVerificationEmail,
        );
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Convert anonymous account to Google account OR sign in with Google
  Future<UserCredential> linkAnonymousToGoogle() async {
    try {
      final currentUser = _auth.currentUser;
      
      // Trigger Google sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign in aborted';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // If user is anonymous, link the account
      if (currentUser != null && currentUser.isAnonymous) {
        // Link the anonymous account with Google
        final userCredential = await currentUser.linkWithCredential(credential);

        // Update user document
        await _updateUserDocument(userCredential.user!);

        return userCredential;
      } else {
        // If not anonymous, just sign in with Google
        final userCredential = await _auth.signInWithCredential(credential);
        
        // Create user document if new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserDocument(userCredential.user!);
        }
        
        return userCredential;
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user signed in';
      if (user.emailVerified) throw 'Email already verified';
      await user.sendEmailVerification();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      // After signing out, sign in anonymously
      await signInAnonymously();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user signed in';

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete the user account
      await user.delete();

      // Sign in anonymously after deletion
      await signInAnonymously();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSignInAt': FieldValue.serverTimestamp(),
      'isAnonymous': user.isAnonymous,
    }, SetOptions(merge: true),);
  }

  // Update user document
  Future<void> _updateUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSignInAt': FieldValue.serverTimestamp(),
      'isAnonymous': user.isAnonymous,
    }, SetOptions(merge: true),);
  }

  // Delete user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    // Delete user document and all subcollections
    final userDoc = _firestore.collection('users').doc(userId);

    // Delete decks and their cards
    final decksSnapshot = await userDoc.collection('decks').get();
    for (var deckDoc in decksSnapshot.docs) {
      // Delete cards in this deck
      final cardsSnapshot = await deckDoc.reference.collection('cards').get();
      for (var cardDoc in cardsSnapshot.docs) {
        await cardDoc.reference.delete();
      }
      await deckDoc.reference.delete();
    }

    // Delete study sessions
    final sessionsSnapshot = await userDoc.collection('studySessions').get();
    for (var sessionDoc in sessionsSnapshot.docs) {
      await sessionDoc.reference.delete();
    }

    // Delete statistics
    final dataSnapshot = await userDoc.collection('data').get();
    for (var dataDoc in dataSnapshot.docs) {
      await dataDoc.reference.delete();
    }

    // Delete user document
    await userDoc.delete();
  }

  // Handle auth exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak (min 6 characters)';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email';
        case 'invalid-credential':
          return 'Invalid credentials provided';
        case 'credential-already-in-use':
          return 'This credential is already associated with another account';
        default:
          return e.message ?? 'Authentication error occurred';
      }
    }
    return e.toString();
  }
}
