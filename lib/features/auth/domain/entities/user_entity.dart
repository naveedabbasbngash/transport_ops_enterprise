/// WHY:
/// Pure domain entity.
/// No JSON, no Flutter imports.
/// JWT claims map cleanly later.
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role; // owner_view | admin
  final bool isReadOnly;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isReadOnly,
  });

  bool get isOwnerReadOnly => role == 'owner_view';
}
