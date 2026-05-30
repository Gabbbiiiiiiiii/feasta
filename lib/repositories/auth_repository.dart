import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/status_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Failed to create customer account.');
    }

    final uid = user.uid;
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    final userRef = _db.collection(FirestoreCollections.users).doc(uid);
    final customerRef = _db.collection(FirestoreCollections.customers).doc(uid);

    batch.set(userRef, {
      'uid': uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': UserRoles.customer,
      'profileImageUrl': null,
      'isEmailVerified': user.emailVerified,
      'isPhoneVerified': false,
      'isActive': true,
      'isBlocked': false,
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
    });

    batch.set(customerRef, {
      'userId': uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'address': '',
      'city': 'Ormoc City',
      'province': 'Leyte',
      'profileImageUrl': null,
      'totalBookings': 0,
      'completedBookings': 0,
      'cancelledBookings': 0,
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> registerProvider({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String businessName,
    required String businessPhone,
    required String businessEmail,
    required String businessAddress,
    required String city,
    required String province,
    required String description,
    required List<String> serviceAreas,
    required List<String> eventTypesSupported,
    required String providerServiceType,
    required String providerCategory,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Failed to create provider account.');
    }

    final uid = user.uid;
    final now = FieldValue.serverTimestamp();

    final providerRef = _db.collection(FirestoreCollections.providers).doc();
    final verificationRef =
        _db.collection(FirestoreCollections.providerVerifications).doc();

    final batch = _db.batch();

    final userRef = _db.collection(FirestoreCollections.users).doc(uid);

    batch.set(userRef, {
      'uid': uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': UserRoles.provider,
      'profileImageUrl': null,
      'isEmailVerified': user.emailVerified,
      'isPhoneVerified': false,
      'isActive': true,
      'isBlocked': false,
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
    });

    batch.set(providerRef, {
      'ownerId': uid,
      'businessName': businessName.trim(),
      'businessEmail': businessEmail.trim(),
      'businessPhone': businessPhone.trim(),
      'ownerFirstName': firstName.trim(),
      'ownerLastName': lastName.trim(),
      'description': description.trim(),
      'location': '$city, $province',
      'address': businessAddress.trim(),
      'city': city.trim(),
      'province': province.trim(),
      'coverImageUrl': null,
      'logoUrl': null,
      'serviceAreas': serviceAreas,
      'eventTypesSupported': eventTypesSupported,
      'providerServiceType': providerServiceType,
      'providerCategory': providerCategory,
      'minPrice': 0,
      'maxPrice': 0,
      'ratingAverage': 0,
      'reviewCount': 0,
      'totalCompletedBookings': 0,
      'totalViews': 0,
      'favoriteCount': 0,
      'verificationStatus': ProviderVerificationStatus.pending,
      'businessPermitUrl': null,
      'validIdUrl': null,
      'birDocumentUrl': null,
      'dtiDocumentUrl': null,
      'maxEventsPerDay': 1,
      'availableStaffCount': 0,
      'availableEquipmentCount': 0,
      'acceptsMultipleEventsPerDay': false,
      'isActive': true,
      'isFeatured': false,
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(verificationRef, {
      'providerId': providerRef.id,
      'ownerId': uid,
      'businessName': businessName.trim(),
      'providerServiceType': providerServiceType,
      'businessPermitUrl': null,
      'validIdUrl': null,
      'birDocumentUrl': null,
      'dtiDocumentUrl': null,
      'status': ProviderVerificationRequestStatus.pending,
      'submittedAt': now,
      'reviewedAt': null,
      'reviewedBy': null,
      'rejectionReason': null,
      'createdAt': now,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user != null) {
      await _db.collection(FirestoreCollections.users).doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}