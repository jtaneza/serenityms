class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;

  final String businessName;
  final String tenantId;
  final String status;

  final int branches;
  final bool isActive;

  final bool mustChangePassword;
  final bool profileCompleted;

  final String businessLogo;
  final String businessAddress;
  final String businessPhone;

  final Map<String, dynamic> operatingHours;
  final Map<String, dynamic> bookingPolicy;
  final Map<String, dynamic> paymentPolicy;

  final String gcashNumber;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.businessName,
    required this.tenantId,
    required this.status,
    required this.branches,
    required this.isActive,
    required this.mustChangePassword,
    required this.profileCompleted,
    required this.businessLogo,
    required this.businessAddress,
    required this.businessPhone,
    required this.operatingHours,
    required this.bookingPolicy,
    required this.paymentPolicy,
    required this.gcashNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',

      businessName: map['businessName'] ?? '',
      tenantId: map['tenantId'] ?? '',
      status: map['status'] ?? '',

      branches: map['branches'] ?? 0,
      isActive: map['isActive'] ?? true,

      mustChangePassword: map['mustChangePassword'] ?? false,
      profileCompleted: map['profileCompleted'] ?? true,

      businessLogo: map['businessLogo'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      businessPhone: map['businessPhone'] ?? '',

      operatingHours: Map<String, dynamic>.from(map['operatingHours'] ?? {}),
      bookingPolicy: Map<String, dynamic>.from(map['bookingPolicy'] ?? {}),
      paymentPolicy: Map<String, dynamic>.from(map['paymentPolicy'] ?? {}),

      gcashNumber: map['gcashNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'businessName': businessName,
      'tenantId': tenantId,
      'status': status,
      'branches': branches,
      'isActive': isActive,
      'mustChangePassword': mustChangePassword,
      'profileCompleted': profileCompleted,
      'businessLogo': businessLogo,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'operatingHours': operatingHours,
      'bookingPolicy': bookingPolicy,
      'paymentPolicy': paymentPolicy,
      'gcashNumber': gcashNumber,
    };
  }
}