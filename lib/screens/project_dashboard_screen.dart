
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import 'task_form_screen.dart';
import 'task_list_screen.dart';

class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  State<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  List<Task> _tasks = [];
  List<Map<String, Object?>> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getTasks(),
        DatabaseHelper.instance.getMembers(),
      ]);

      if (!mounted) return;

      setState(() {
        _tasks = results[0] as List<Task>;
        _members = results[1] as List<Map<String, Object?>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load dashboard data. Please try again.';
        _loading = false;
      });
    }
  }

  int get _completed =>
      _tasks.where((task) => task.status == TaskStatus.done).length;

  int get _overdue =>
      _tasks.where((task) => _slaStatus(task) == 'Overdue').length;

  int get _atRisk =>
      _tasks.where((task) => _slaStatus(task) == 'At Risk').length;

  int get _onTrack =>
      _tasks.where((task) => _slaStatus(task) == 'On Track').length;

  double get _progress =>
      _tasks.isEmpty ? 0 : _completed / _tasks.length;

  String _slaStatus(Task task) {
    if (task.status == TaskStatus.done) {
      return 'Completed';
    }

    final remaining = task.dueDate.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      return 'Overdue';
    }

    if (remaining <= const Duration(hours: 24)) {
      return 'At Risk';
    }

    return 'On Track';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.info;
      case 'Overdue':
        return AppColors.danger;
      case 'At Risk':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Color _statusTint(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.infoTint;
      case 'Overdue':
        return AppColors.dangerTint;
      case 'At Risk':
        return AppColors.warningTint;
      default:
        return AppColors.primaryTint;
    }
  }

  String get _memberName {
    if (_members.isEmpty) return 'Team Member';
    return (_members.first['name'] as String?) ?? 'Team Member';
  }

  String get _memberRole {
    if (_members.isEmpty) return 'Project Team';
    return (_members.first['role'] as String?) ?? 'Project Team';
  }

  String get _initials {
    final parts = _memberName
        .replaceAll('.', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'TM';
    if (parts.length == 1) {
      return parts.first.substring(0, math.min(2, parts.first.length))
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
  }

  String _deadlineLabel(Task task) {
    if (task.status == TaskStatus.done) {
      if (task.completedAt != null &&
          task.completedAt!.isAfter(task.dueDate)) {
        return 'Completed late';
      }
      return 'Completed';
    }

    final remaining = task.dueDate.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      return 'Deadline passed';
    }

    if (remaining.inHours < 1) {
      return 'Due in ${remaining.inMinutes} min';
    }

    if (remaining.inHours < 24) {
      return 'Due in ${remaining.inHours} hours';
    }

    if (remaining.inDays == 1) {
      return 'Due tomorrow';
    }

    return 'Due ${_formatDate(task.dueDate)}';
  }

  Future<void> _addTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskFormScreen(),
      ),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _openTasks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskListScreen(),
      ),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature navigation is not connected yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Add task',
            onPressed: _addTask,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: _buildDashboardContent(),
                ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDashboard,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildWelcomeCard(),
        const SizedBox(height: 20),
        _buildSectionHeading('Project Progress'),
        const SizedBox(height: 10),
        _buildProgressCard(),
        const SizedBox(height: 20),
        _buildSectionHeading('Task Status'),
        const SizedBox(height: 10),
        _buildStatusGrid(),
        const SizedBox(height: 20),
        _buildSectionHeading('Task Overview'),
        const SizedBox(height: 10),
        _buildOverviewCard(),
        const SizedBox(height: 20),
        _buildSectionHeading(
          'Needs Attention',
          trailing: TextButton(
            onPressed: _openTasks,
            child: const Text('See all'),
          ),
        ),
        const SizedBox(height: 8),
        _buildAttentionList(),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $_memberName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_memberRole · Sprint 3',
                  style: const TextStyle(
                    color: Color(0xFFD7F0E8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Here's what's happening with your project.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white,
            child: Text(
              _initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall completion',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(_progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_completed of ${_tasks.length} tasks',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _StatusCard(
          label: 'On Track',
          count: _onTrack,
          color: AppColors.primary,
          tint: AppColors.primaryTint,
          icon: Icons.check_circle_outline_rounded,
        ),
        _StatusCard(
          label: 'At Risk',
          count: _atRisk,
          color: AppColors.warning,
          tint: AppColors.warningTint,
          icon: Icons.warning_amber_rounded,
        ),
        _StatusCard(
          label: 'Overdue',
          count: _overdue,
          color: AppColors.danger,
          tint: AppColors.dangerTint,
          icon: Icons.error_outline_rounded,
        ),
        _StatusCard(
          label: 'Completed',
          count: _completed,
          color: AppColors.info,
          tint: AppColors.infoTint,
          icon: Icons.task_alt_rounded,
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final total = _tasks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Pie graph',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No tasks to display yet.')),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: _TaskDonutPainter(
                      values: [
                        _onTrack,
                        _atRisk,
                        _overdue,
                        _completed,
                      ],
                      colors: [
                        AppColors.primary,
                        AppColors.warning,
                        AppColors.danger,
                        AppColors.info,
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Total tasks',
                            style: TextStyle(
                              fontSize: 11,
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
                      _LegendRow(
                        label: 'On Track',
                        count: _onTrack,
                        color: AppColors.primary,
                      ),
                      _LegendRow(
                        label: 'At Risk',
                        count: _atRisk,
                        color: AppColors.warning,
                      ),
                      _LegendRow(
                        label: 'Overdue',
                        count: _overdue,
                        color: AppColors.danger,
                      ),
                      _LegendRow(
                        label: 'Completed',
                        count: _completed,
                        color: AppColors.info,
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

  Widget _buildAttentionList() {
    final attentionTasks = _tasks
        .where((task) {
          final status = _slaStatus(task);
          return status == 'Overdue' || status == 'At Risk';
        })
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (attentionTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No tasks need urgent attention. Great work!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: attentionTasks.take(4).map((task) {
        final status = _slaStatus(task);
        final color = _statusColor(status);
        final tint = _statusTint(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _deadlineLabel(task),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _memberName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _memberRole,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              selected: true,
              selectedColor: AppColors.primary,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                _openTasks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Statistics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text('Team Members'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Team Members');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Refresh data'),
              onTap: () {
                Navigator.pop(context);
                _loadDashboard();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Team',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            _openTasks();
            break;
          case 2:
            _showComingSoon('Statistics');
            break;
          case 3:
            _showComingSoon('Team');
            break;
        }
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.tint,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDonutPainter extends CustomPainter {
  _TaskDonutPainter({
    required this.values,
    required this.colors,
  });

  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 17.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final backgroundPaint = Paint()
      ..color = const Color(0xFFEDEFEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      backgroundPaint,
    );

    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return;

    var startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;

      final sweepAngle = (values[i] / total) * math.pi * 2;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _TaskDonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}
