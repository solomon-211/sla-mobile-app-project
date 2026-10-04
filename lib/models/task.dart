enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.label);
  final String label;
}

enum TaskStatus {
  toDo('To Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);
  final String label;
}

class TeamMember {
  const TeamMember({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  String get displayName => '$name ($role)';

  @override
  bool operator ==(Object other) => other is TeamMember && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const List<TeamMember> kTeamMembers = [
  TeamMember(id: 'AK', name: 'Amina K.', role: 'Project Manager'),
  TeamMember(id: 'BO', name: 'Brian O.', role: 'Backend Developer'),
  TeamMember(id: 'CM', name: 'Chloé M.', role: 'UI/UX Designer'),
  TeamMember(id: 'DA', name: 'Deng A.', role: 'Mobile Developer'),
];

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final TeamMember assignee;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
}
