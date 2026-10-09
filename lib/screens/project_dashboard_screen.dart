import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({
    super.key,
    this.tasks,
  });

  final List<Task>? tasks;

  @override
  State<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();

    _tasks = widget.tasks ?? _demoTasks();
  }

  // ============================================================
  // DEMO TASKS
  // ============================================================

  List<Task> _demoTasks() {
    final now = DateTime.now();

    return [
      Task(
        id: '1',
        title: 'Design Login Screen',
        description: 'Design the login screen for the application.',
        assignee: kTeamMembers[2],
        dueDate: now.add(const Duration(days: 4)),
        priority: TaskPriority.high,
        status: TaskStatus.done,
      ),
      Task(
        id: '2',
        title: 'Implement Local Storage',
        description: 'Implement local task storage.',
        assignee: kTeamMembers[3],
        dueDate: now.add(const Duration(hours: 20)),
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
      ),
      Task(
        id: '3',
        title: 'Create Task Model',
        description: 'Create the task model.',
        assignee: kTeamMembers[1],
        dueDate: now.subtract(const Duration(days: 1)),
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
      ),
      Task(
        id: '4',
        title: 'Test Application',
        description: 'Test the main application workflow.',
        assignee: kTeamMembers[1],
        dueDate: now.add(const Duration(days: 3)),
        priority: TaskPriority.medium,
        status: TaskStatus.toDo,
      ),
      Task(
        id: '5',
        title: 'Prepare Demo',
        description: 'Prepare the project demonstration.',
        assignee: kTeamMembers[0],
        dueDate: now.add(const Duration(days: 5)),
        priority: TaskPriority.medium,
        status: TaskStatus.toDo,
      ),
      Task(
        id: '6',
        title: 'Build Dashboard',
        description: 'Build the project dashboard.',
        assignee: kTeamMembers[0],
        dueDate: now.add(const Duration(days: 3)),
        priority: TaskPriority.high,
        status: TaskStatus.done,
      ),
      Task(
        id: '7',
        title: 'Create Task List',
        description: 'Create the task list screen.',
        assignee: kTeamMembers[3],
        dueDate: now.add(const Duration(days: 4)),
        priority: TaskPriority.medium,
        status: TaskStatus.done,
      ),
      Task(
        id: '8',
        title: 'Review User Interface',
        description: 'Review the application interface.',
        assignee: kTeamMembers[2],
        dueDate: now.add(const Duration(days: 5)),
        priority: TaskPriority.low,
        status: TaskStatus.toDo,
      ),
    ];
  }

  // ============================================================
  // SLA LOGIC
  //
  // Group rules:
  // Completed = status is Done
  // Overdue   = not Done and deadline has passed
  // At Risk   = not Done and deadline is less than 48 hours away
  // On Track  = everything else
  // ============================================================

  String getSlaStatus(Task task) {
    if (task.status == TaskStatus.done) {
      return 'Completed';
    }

    final now = DateTime.now();

    if (task.dueDate.isBefore(now)) {
      return 'Overdue';
    }

    final remainingTime = task.dueDate.difference(now);

    if (remainingTime < const Duration(hours: 48)) {
      return 'At Risk';
    }

    return 'On Track';
  }

  // ============================================================
  // DASHBOARD COUNTS
  // ============================================================

  int get totalTasks => _tasks.length;

  int get completedTasks =>
      _tasks.where((task) => getSlaStatus(task) == 'Completed').length;

  int get overdueTasks =>
      _tasks.where((task) => getSlaStatus(task) == 'Overdue').length;

  int get atRiskTasks =>
      _tasks.where((task) => getSlaStatus(task) == 'At Risk').length;

  int get onTrackTasks =>
      _tasks.where((task) => getSlaStatus(task) == 'On Track').length;

  double get projectProgress {
    if (totalTasks == 0) {
      return 0;
    }

    return completedTasks / totalTasks;
  }

  // ============================================================
  // MAIN DASHBOARD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),

      drawer: _buildDrawer(),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showMessage('No new notifications');
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          children: [
            _buildGreeting(),

            const SizedBox(height: 20),

            _buildProjectProgress(),

            const SizedBox(height: 18),

            _buildStatusCards(),

            const SizedBox(height: 24),

            _buildTaskOverview(),

            const SizedBox(height: 24),

            _buildNeedsAttention(),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'AK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, Amina',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Here's what's happening with your project.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROJECT PROGRESS
  // ============================================================

  Widget _buildProjectProgress() {
    final percentage = (projectProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '$completedTasks of $totalTasks tasks completed',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: projectProgress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SLA STATUS CARDS
  // ============================================================

  Widget _buildStatusCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _statusCard(
          title: 'On Track',
          count: onTrackTasks,
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
          backgroundColor: AppColors.primaryTint,
        ),

        _statusCard(
          title: 'At Risk',
          count: atRiskTasks,
          icon: Icons.warning_amber_outlined,
          color: AppColors.warning,
          backgroundColor: AppColors.warningTint,
        ),

        _statusCard(
          title: 'Overdue',
          count: overdueTasks,
          icon: Icons.error_outline,
          color: AppColors.danger,
          backgroundColor: AppColors.dangerTint,
        ),

        _statusCard(
          title: 'Completed',
          count: completedTasks,
          icon: Icons.task_alt,
          color: AppColors.info,
          backgroundColor: AppColors.infoTint,
        ),
      ],
    );
  }

  Widget _statusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASK OVERVIEW
  // ============================================================

  Widget _buildTaskOverview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              SizedBox(
                width: 145,
                height: 145,
                child: CustomPaint(
                  painter: _TaskDonutPainter(
                    onTrack: onTrackTasks,
                    atRisk: atRiskTasks,
                    overdue: overdueTasks,
                    completed: completedTasks,
                    total: totalTasks,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalTasks',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  children: [
                    _legendItem(
                      'On Track',
                      onTrackTasks,
                      AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _legendItem(
                      'At Risk',
                      atRiskTasks,
                      AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    _legendItem(
                      'Overdue',
                      overdueTasks,
                      AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    _legendItem(
                      'Completed',
                      completedTasks,
                      AppColors.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    String title,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),

        Text(
          '$count',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NEEDS ATTENTION
  // ============================================================

  Widget _buildNeedsAttention() {
    final attentionTasks = _tasks.where((task) {
      final status = getSlaStatus(task);

      return status == 'At Risk' || status == 'Overdue';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Needs Attention',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            TextButton(
              onPressed: () {
                _showMessage(
                  'Task List navigation will be connected by the team.',
                );
              },
              child: const Text('See all'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (attentionTasks.isEmpty)
          _emptyAttentionCard()
        else
          ...attentionTasks.take(4).map(_attentionTaskCard),
      ],
    );
  }

  Widget _emptyAttentionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 36,
            color: AppColors.primary,
          ),
          SizedBox(height: 8),
          Text(
            'Everything is on track!',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'There are no tasks that need attention.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionTaskCard(Task task) {
    final slaStatus = getSlaStatus(task);

    final bool overdue = slaStatus == 'Overdue';

    final Color statusColor =
        overdue ? AppColors.danger : AppColors.warning;

    final Color backgroundColor =
        overdue ? AppColors.dangerTint : AppColors.warningTint;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              overdue
                  ? Icons.error_outline
                  : Icons.warning_amber_outlined,
              color: statusColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Assigned to ${task.assignee.name}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _deadlineText(task),
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              slaStatus,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _deadlineText(Task task) {
    final now = DateTime.now();

    if (task.dueDate.isBefore(now)) {
      final difference = now.difference(task.dueDate);

      if (difference.inDays > 0) {
        return '${difference.inDays} day(s) overdue';
      }

      return 'Deadline has passed';
    }

    final difference = task.dueDate.difference(now);

    if (difference.inHours < 1) {
      return 'Due in less than 1 hour';
    }

    if (difference.inHours < 24) {
      return 'Due in ${difference.inHours} hours';
    }

    return 'Due in ${difference.inDays} days';
  }

  // ============================================================
  // SIMPLE DRAWER NAVIGATION
  // ============================================================

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      'AK',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Amina K.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Project Manager',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            _drawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              selected: true,
            ),

            _drawerItem(
              icon: Icons.task_outlined,
              title: 'Tasks',
            ),

            _drawerItem(
              icon: Icons.bar_chart_outlined,
              title: 'Statistics',
            ),

            _drawerItem(
              icon: Icons.people_outline,
              title: 'Team Members',
            ),

            const Spacer(),

            const Divider(),

            _drawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected
            ? AppColors.primary
            : AppColors.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected
              ? AppColors.primary
              : AppColors.textPrimary,
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primaryTint,
      onTap: () {
        Navigator.pop(context);

        if (!selected) {
          _showMessage(
            '$title navigation will be connected by the team.',
          );
        }
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: 0,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primaryTint,
      height: 68,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home,
            color: AppColors.primary,
          ),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.task_outlined),
          selectedIcon: Icon(
            Icons.task,
            color: AppColors.primary,
          ),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(
            Icons.bar_chart,
            color: AppColors.primary,
          ),
          label: 'Stats',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(
            Icons.people,
            color: AppColors.primary,
          ),
          label: 'Team',
        ),
      ],
      onDestinationSelected: (index) {
        if (index == 0) {
          return;
        }

        final screenNames = [
          'Dashboard',
          'Tasks',
          'Statistics',
          'Team Members',
        ];

        _showMessage(
          '${screenNames[index]} screen will be connected by the team.',
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ================================================================
// DONUT CHART
// ================================================================

class _TaskDonutPainter extends CustomPainter {
  const _TaskDonutPainter({
    required this.onTrack,
    required this.atRisk,
    required this.overdue,
    required this.completed,
    required this.total,
  });

  final int onTrack;
  final int atRisk;
  final int overdue;
  final int completed;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 8;

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = AppColors.border;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    if (total == 0) {
      return;
    }

    final values = [
      onTrack,
      atRisk,
      overdue,
      completed,
    ];

    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.danger,
      AppColors.info,
    ];

    double startAngle = -1.5708;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) {
        continue;
      }

      final sweepAngle =
          (values[i] / total) * 6.283185307179586;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(
    covariant _TaskDonutPainter oldDelegate,
  ) {
    return oldDelegate.onTrack != onTrack ||
        oldDelegate.atRisk != atRisk ||
        oldDelegate.overdue != overdue ||
        oldDelegate.completed != completed ||
        oldDelegate.total != total;
  }
}