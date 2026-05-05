import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ClientAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createClientAccount({
    required String businessName,
    required String adminName,
    required String email,
    required String password,
    required String status,
    required int branches,
  }) async {

    // create secondary isolated firebase app
    final secondaryApp = await Firebase.initializeApp(
      name: 'ClientCreator',
      options: Firebase.app().options,
    );

    final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      UserCredential credential =
      await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // save in clients collection
      await _firestore.collection('clients').doc(uid).set({
        'uid': uid,
        'businessName': businessName,
        'adminName': adminName,
        'email': email,
        'status': status,
        'branches': branches,
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'archivedAt': null,
      });

      // save in users collection for global auth role management
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': adminName,
        'email': email,
        'role': 'client',
        'clientBusiness': businessName,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  static Future<UserCredential> loginClient({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getClientData(String uid) async {
    return await _firestore.collection('clients').doc(uid).get();
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}