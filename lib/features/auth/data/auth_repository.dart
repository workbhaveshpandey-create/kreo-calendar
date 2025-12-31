import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_model.dart';

/// Authentication Repository
/// Handles Google Sign-In and user data management in Firestore
/// Each user gets their own private space - data is isolated by user ID
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: [
               'email',
               'https://www.googleapis.com/auth/calendar',
               'https://www.googleapis.com/auth/calendar.events',
             ],
           );

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get Google Sign-In account (for Calendar API access)
  GoogleSignInAccount? get googleAccount => _googleSignIn.currentUser;

  /// Sign in with Google
  /// Creates a new user space in Firestore if first time
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled sign-in
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to get user after sign-in');
      }

      // Create or update user in Firestore
      final userModel = await _createOrUpdateUser(firebaseUser);

      return userModel;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Create or update user document in Firestore
  Future<UserModel> _createOrUpdateUser(User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      // Update last login time
      await userDoc.update({
        'lastLoginAt': Timestamp.now(),
        'displayName': firebaseUser.displayName,
        'photoUrl': firebaseUser.photoURL,
      });
      return UserModel.fromFirestore(await userDoc.get());
    } else {
      // Create new user - this is their private space
      final newUser = UserModel.fromFirebaseUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
      );
      await userDoc.set(newUser.toFirestore());

      // Create default calendar for new user
      await _createDefaultCalendar(firebaseUser.uid);

      return newUser;
    }
  }

  /// Create a default calendar for new users
  Future<void> _createDefaultCalendar(String userId) async {
    final calendarRef = _firestore.collection('calendars').doc();
    await calendarRef.set({
      'userId': userId,
      'name': 'My Calendar',
      'color': 0xFF6C5CE7,
      'isDefault': true,
      'isGoogleSync': false,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Get Google authentication headers for Calendar API
  Future<Map<String, String>?> getGoogleAuthHeaders() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;

    final auth = await account.authentication;
    return {'Authorization': 'Bearer ${auth.accessToken}'};
  }

  /// Silently sign in (for app restart)
  Future<UserModel?> silentSignIn() async {
    try {
      // Try to sign in silently with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently();

      if (googleUser == null) {
        // Check if already signed in to Firebase
        if (currentUser != null) {
          return getCurrentUserData();
        }
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return getCurrentUserData();
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  /// Delete user account and all their data
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // Delete user's calendars
    final calendars = await _firestore
        .collection('calendars')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final calendar in calendars.docs) {
      // Delete events in each calendar
      final events = await _firestore
          .collection('events')
          .where('calendarId', isEqualTo: calendar.id)
          .get();

      for (final event in events.docs) {
        await event.reference.delete();
      }
      await calendar.reference.delete();
    }

    // Delete user settings
    await _firestore.collection('settings').doc(user.uid).delete();

    // Delete user document
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete Firebase Auth account
    await user.delete();

    // Sign out from Google
    await _googleSignIn.signOut();
  }
}
