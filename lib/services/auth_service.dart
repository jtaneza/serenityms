import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // LOGIN
  // ============================================
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User profile not found.',
      );
    }

    final data = userDoc.data()!;

    if (data['isActive'] == false) {
      throw FirebaseAuthException(
        code: 'inactive-user',
        message: 'This account is deactivated.',
      );
    }

    return UserModel.fromMap(data);
  }

  // ============================================
  // CREATE CLIENT ADMIN (Created by Super Admin)
  // ============================================
  static Future<void> createClientAdmin({
    required String businessName,
    required String adminName,
    required String email,
    required String password,
    required String status,
    required int branches,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

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
      'archivedAt': null,
    });

    await _auth.signOut();
  }

  // ============================================
  // CREATE SUPER ADMIN
  // ============================================
  static Future<void> createSuperAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'tenantId': 'SYSTEM',

      'fullName': name,
      'email': email,

      'businessName': 'Serenity System',
      'status': 'active',
      'branches': 0,

      'role': 'super_admin',
      'isActive': true,

      'mustChangePassword': false,
      'profileCompleted': true,

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

    await _auth.signOut();
  }

  // ============================================
  // AUTO SEED SUPER ADMIN
  // ============================================
  static Future<void> seedSuperAdmin() async {
    const email = 'admin@serenity.com';
    const password = 'Admin123';

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _auth.signOut();
    } catch (_) {
      try {
        await createSuperAdmin(
          name: 'Super Admin',
          email: email,
          password: password,
        );
      } catch (e) {
        print('Seed Error: $e');
      }
    }
  }

  // ============================================
  // CLIENT FIRST SETUP SAVE
  // ============================================
  static Future<void> completeClientFirstSetup({
    required UserModel user,
    required String newPassword,
    required String businessAddress,
    required String businessPhone,
    required String gcashNumber,
  }) async {
    await userCredentialUpdatePassword(newPassword);

    await _firestore.collection('users').doc(user.uid).update({
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'gcashNumber': gcashNumber,
      'mustChangePassword': false,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> userCredentialUpdatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  // ============================================
  // CURRENT USER
  // ============================================
  static User? get currentFirebaseUser => _auth.currentUser;

  // ============================================
  // LOGOUT
  // ============================================
  static Future<void> logout() async {
    await _auth.signOut();
  }
}