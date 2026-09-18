import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String currencyCode;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.currencyCode = 'USD',
  });

  AppUser copyWith({String? displayName, String? currencyCode}) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'currencyCode': currencyCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AppUser.fromSnapshot(DocumentSnapshot doc) {
    return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
