import '../models/task.dart';

/// Demo data inserted the first time the database is created.
const seedProjectName = 'Mobile Banking v2 · Sprint 3';

/// The four demo team members seeded on first launch.
const seedMembers = [
  _SeedMember(id: 1, name: 'Amina K.',  role: 'Project Manager',   email: 'amina@devteam.app',  colorIndex: 0),
  _SeedMember(id: 2, name: 'Brian O.',  role: 'Backend Developer',  email: 'brian@devteam.app',  colorIndex: 1),
  _SeedMember(id: 3, name: 'Chloé M.', role: 'UI/UX Designer',     email: 'chloe@devteam.app',  colorIndex: 2),
  _SeedMember(id: 4, name: 'Deng A.',  role: 'Mobile Developer',   email: 'deng@devteam.app',   colorIndex: 3),
];

/// Lightweight struct used only during seeding so seed_data.dart stays
/// independent of the full TeamMember model.
class _SeedMember {
  final int id;
  final String name;
  final String role;
  final String email;
  final int colorIndex;

  const _SeedMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.colorIndex,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'email': email,
        'color_index': colorIndex,
      };
}
