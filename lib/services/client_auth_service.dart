import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'ClientCreator_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _firestore.collection('clients').doc(uid).set({
        'uid': uid,
        'tenantId': uid,
        'businessName': businessName,
        'adminName': adminName,
        'fullName': adminName,
        'email': email,
        'status': status,
        'branches': branches,
        'role': 'client_admin',
        'isActive': true,
        'mustChangePassword': true,
        'profileCompleted': false,
        'businessLogo': '',
        'businessAddress': '',
        'businessPhone': '',
        'operatingHours': {},
        'gcashNumber': '',
        'bookingPolicy': {},
        'paymentPolicy': {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'archivedAt': null,
      });

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'tenantId': uid,
        'businessName': businessName,
        'fullName': adminName,
        'email': email,
        'status': status,
        'branches': branches,
        'role': 'client_admin',
        'isActive': true,
        'mustChangePassword': true,
        'profileCompleted': false,
        'businessLogo': '',
        'businessAddress': '',
        'businessPhone': '',
        'operatingHours': {},
        'gcashNumber': '',
        'bookingPolicy': {},
        'paymentPolicy': {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  static Future<UserCredential> loginClient({
    required String email,
    required String password,
  }) async {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getClientData(
      String uid,
      ) async {
    return _firestore.collection('clients').doc(uid).get();
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}