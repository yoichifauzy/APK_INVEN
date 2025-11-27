class AppUser {
  final int id;
  final String name;
  final String email;
  final List<String> roles;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    List<String> roles = [];
    if (json['roles'] != null) {
      try {
        roles = List<String>.from(json['roles']);
      } catch (e) {
        // sometimes API sends roles as list of objects
        roles = (json['roles'] as List).map((r) => r.toString()).toList();
      }
    } else if (json['role'] != null) {
      // fallback single role
      roles = [json['role'].toString()];
    }

    return AppUser(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      // backend uses Indonesian field `nama` — fall back to `name` if available
      name: json['nama'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      roles: roles,
    );
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }
}
