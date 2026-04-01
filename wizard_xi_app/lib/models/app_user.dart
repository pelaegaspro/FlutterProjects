class AppUser {
  const AppUser({
    required this.id,
    required this.isAnonymous,
    this.displayName,
    this.email,
  });

  final String id;
  final bool isAnonymous;
  final String? displayName;
  final String? email;

  String get shortName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.contains('@')) {
      return email!.split('@').first;
    }
    return 'Strategist';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isAnonymous': isAnonymous,
        'displayName': displayName,
        'email': email,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      isAnonymous: json['isAnonymous'] == true,
      displayName: json['displayName']?.toString(),
      email: json['email']?.toString(),
    );
  }
}
