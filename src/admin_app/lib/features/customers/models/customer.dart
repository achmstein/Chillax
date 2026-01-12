/// Customer model (from Keycloak user)
class Customer {
  final String id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool enabled;
  final DateTime? createdAt;

  Customer({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.enabled = true,
    this.createdAt,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return username ?? email ?? 'Unknown';
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null) return firstName![0].toUpperCase();
    if (username != null) return username![0].toUpperCase();
    if (email != null) return email![0].toUpperCase();
    return '?';
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: json['createdTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdTimestamp'] as int)
          : null,
    );
  }
}
