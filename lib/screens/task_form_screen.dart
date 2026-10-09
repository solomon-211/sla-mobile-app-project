import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/database_helper.dart';
import '../utils/validators.dart';

/// Create / Edit Task. Pass a [task] to edit it, or null to create a new one.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.task?.title);
  late final _descriptionController = TextEditingController(
    text: widget.task?.description,
  );

  late String _category = widget.task?.category ?? taskCategories.first;
  late int? _assigneeId = widget.task?.assigneeId;
  late DateTime? _dueDate = widget.task?.dueDate;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late TaskStatus _status = widget.task?.status ?? TaskStatus.todo;

  /// Tracks the assignee the form opened with to detect unsaved changes.
  late int? _initialAssigneeId = widget.task?.assigneeId;

  List<Map<String, Object?>> _members = [];
  bool _loadingMembers = true;
  String? _loadError;
  bool _saving = false;

  /// Errors appear only after the first failed submit attempt.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEditing => widget.task != null;

  bool get _hasChanges {
    final task = widget.task;
    return _titleController.text.trim() != (task?.title ?? '') ||
        _descriptionController.text.trim() != (task?.description ?? '') ||
        _category != (task?.category ?? taskCategories.first) ||
        _assigneeId != _initialAssigneeId ||
        _dueDate != task?.dueDate ||
        _priority != (task?.priority ?? TaskPriority.medium) ||
        _status != (task?.status ?? TaskStatus.todo);
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _loadError = null;
    });
    try {
      final rows = await DatabaseHelper.instance.getMembers();
      if (!mounted) return;
      setState(() {
        _members = rows;
        _loadingMembers = false;
        // Default new tasks to the first member.
        if (!_isEditing && _assigneeId == null && rows.isNotEmpty) {
          _assigneeId = rows.first['id'] as int;
          _initialAssigneeId = _assigneeId;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _loadError = 'Could not load team members.';
      });
    }
  }

  /// Date picker followed by time picker, combined into one DateTime.
  Future<void> _pickDueDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _dueDate;
    final initial = current != null && current.isAfter(today)
        ? current
        : now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    setState(() => _dueDate = picked);
    field.didChange(picked);
  }

  /// Asks before discarding unsaved changes.
  Future<void> _confirmLeave() async {
    if (_saving) return;
    if (_hasChanges) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
              'Your changes to this task have not been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    Navigator.pop(context);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    setState(() => _saving = true);
    final existing = widget.task;
    final now = DateTime.now();
    final assigneeName = _members
        .firstWhere((m) => m['id'] == _assigneeId)['name'] as String;

    final task = Task(
      id: existing?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      assigneeId: _assigneeId!,
      dueDate: _dueDate!,
      priority: _priority,
      status: _status,
      createdAt: existing?.createdAt ?? now,
      completedAt: _status == TaskStatus.done
          ? (existing?.completedAt ?? now)
          : null,
    );

    try {
      final db = DatabaseHelper.instance;
      if (existing == null) {
        await db.insertTask(
          task,
          activity: 'Created and assigned to $assigneeName',
        );
      } else {
        await db.updateTask(task, activities: [
          if (task.status != existing.status)
            'Status changed to ${task.status.label}',
          if (task.assigneeId != existing.assigneeId)
            'Reassigned to $assigneeName',
          if (task.dueDate != existing.dueDate)
            'Due date updated',
          if (task.status == existing.status &&
              task.assigneeId == existing.assigneeId &&
              task.dueDate == existing.dueDate)
            'Task details updated',
        ]);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Task updated' : 'Task created')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the task. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_loadingMembers && _loadError == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
        ),
        body: _loadingMembers
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadMembers,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                : _buildForm(),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: _saving || !ready ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create Task'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final statusOptions = [
      for (final s in TaskStatus.values)
        if (_isEditing || s != TaskStatus.done) s,
    ];

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── Title ──────────────────────────────────────────────────────
          const _FieldLabel('Task title'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: Validators.titleMaxLength,
            decoration: const InputDecoration(
              hintText: 'Enter task title',
              counterText: '',
            ),
            validator: Validators.taskTitle,
          ),
          const SizedBox(height: 12),

          // ── Description ────────────────────────────────────────────────
          const _FieldLabel('Description'),
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 4,
            maxLength: Validators.descriptionMaxLength,
            decoration: const InputDecoration(
              hintText: 'Enter task description (optional)',
            ),
          ),
          const SizedBox(height: 12),

          // ── Assignee ───────────────────────────────────────────────────
          const _FieldLabel('Assign to'),
          DropdownButtonFormField<int>(
            value: _members.any((m) => m['id'] == _assigneeId)
                ? _assigneeId
                : null,
            isExpanded: true,
            hint: const Text('Select a team member'),
            items: [
              for (final m in _members)
                DropdownMenuItem(
                  value: m['id'] as int,
                  child: Text(
                    '${m['name']} (${m['role']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            validator: (v) => v == null ? 'Choose who will do this task' : null,
            onChanged: (v) => setState(() => _assigneeId = v),
          ),
          const SizedBox(height: 12),

          // ── Category ───────────────────────────────────────────────────
          const _FieldLabel('Category'),
          DropdownButtonFormField<String>(
            value: _category,
            isExpanded: true,
            items: [
              for (final c in taskCategories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),

          // ── Due date ───────────────────────────────────────────────────
          const _FieldLabel('Due date'),
          FormField<DateTime>(
            initialValue: _dueDate,
            validator: (v) =>
                Validators.dueDate(v, original: widget.task?.dueDate),
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _pickDueDate(field),
                  child: InputDecorator(
                    isEmpty: field.value == null,
                    decoration: InputDecoration(
                      hintText: 'Select date and time',
                      errorText: field.errorText,
                      suffixIcon: const Icon(Icons.calendar_today_outlined,
                          size: 18),
                    ),
                    child: field.value == null
                        ? null
                        : Text(_formatDate(field.value!)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Priority ───────────────────────────────────────────────────
          const _FieldLabel('Priority'),
          _PrioritySelector(
            value: _priority,
            onChanged: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: 12),

          // ── Status ─────────────────────────────────────────────────────
          const _FieldLabel('Status'),
          DropdownButtonFormField<TaskStatus>(
            value: _status,
            isExpanded: true,
            items: [
              for (final s in statusOptions)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $h:$m';
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Low / Medium / High as a custom row of InkWell + AnimatedContainer options.
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  static const _colors = {
    TaskPriority.low: Color(0xFF4C6FD8),
    TaskPriority.medium: Color(0xFFE08A00),
    TaskPriority.high: Color(0xFFE5484D),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final priority in TaskPriority.values)
            Expanded(child: _option(priority)),
        ],
      ),
    );
  }

  Widget _option(TaskPriority priority) {
    final selected = priority == value;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${priority.label} priority',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(priority),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1B1F23) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: _colors[priority],
                ),
                const SizedBox(width: 6),
                Text(
                  priority.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF1B1F23),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
