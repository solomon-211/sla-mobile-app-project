import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Create / Edit Task screen.
///
/// Pass [task] to edit an existing task; leave it null to create a new one.
/// The saved [Task] is returned through `Navigator.pop`.
class CreateEditTaskScreen extends StatefulWidget {
  const CreateEditTaskScreen({super.key, this.task});

  final Task? task;

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  TeamMember? _assignee;
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.toDo;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    if (task != null) {
      _assignee = task.assignee;
      _dueDate = task.dueDate;
      _priority = task.priority;
      _status = task.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  String? _validateTitle(String? value) {
    final length = (value ?? '').trim().length;
    if (length < 3 || length > 60) {
      return 'Title is required (3–60 characters)';
    }
    return null;
  }

  String? _validateDueDate(DateTime? value) {
    if (value == null) return 'Due date is required';
    // An unchanged due date on an existing task may already be in the past.
    if (_isEditing && value == widget.task!.dueDate) return null;
    if (!value.isAfter(DateTime.now())) return 'Due date must be in the future';
    return null;
  }

  Future<void> _pickDueDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final initial = _dueDate ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _dueDate = picked);
    field.didChange(picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    final task = Task(
      id: widget.task?.id ?? 'T-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assignee: _assignee!,
      dueDate: _dueDate!,
      priority: _priority,
      status: _status,
    );
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(task);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Task "${task.title}" updated'
              : 'Task "${task.title}" created',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Task title'),
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Enter task title',
                        ),
                        validator: _validateTitle,
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Enter task description',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _IconField(
                        label: 'Assign to',
                        icon: Icons.person_outline,
                        color: AppColors.primary,
                        tint: AppColors.primaryTint,
                        child: DropdownButtonFormField<TeamMember>(
                          initialValue: _assignee,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          hint: const Text('Select team member'),
                          items: [
                            for (final member in kTeamMembers)
                              DropdownMenuItem(
                                value: member,
                                child: Text(
                                  member.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _assignee = value),
                          validator: (value) =>
                              value == null ? 'Assignee is required' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _IconField(
                        label: 'Due date',
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.danger,
                        tint: AppColors.dangerTint,
                        child: FormField<DateTime>(
                          initialValue: _dueDate,
                          validator: _validateDueDate,
                          builder: (field) => InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _pickDueDate(field),
                            child: InputDecorator(
                              isEmpty: field.value == null,
                              decoration: InputDecoration(
                                hintText: 'Select date and time',
                                errorText: field.errorText,
                                suffixIcon: const Icon(
                                  Icons.event_outlined,
                                  size: 20,
                                ),
                              ),
                              child: field.value == null
                                  ? null
                                  : Text(
                                      _formatDate(field.value!),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _IconField(
                        label: 'Priority',
                        icon: Icons.flag_outlined,
                        color: AppColors.warning,
                        tint: AppColors.warningTint,
                        child: _PrioritySelector(
                          value: _priority,
                          onChanged: (value) =>
                              setState(() => _priority = value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _IconField(
                        label: 'Status',
                        icon: Icons.format_list_bulleted,
                        color: AppColors.info,
                        tint: AppColors.infoTint,
                        child: DropdownButtonFormField<TaskStatus>(
                          initialValue: _status,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            for (final status in TaskStatus.values)
                              DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _status = value ?? _status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Save Changes' : 'Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// A labelled field with a tinted icon tile on its left.
class _IconField extends StatelessWidget {
  const _IconField({
    required this.label,
    required this.icon,
    required this.color,
    required this.tint,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_FieldLabel(label), child],
          ),
        ),
      ],
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final priority in TaskPriority.values) ...[
          if (priority != TaskPriority.values.first) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(priority),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: priority == value
                      ? AppColors.primaryTint
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: priority == value
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  priority.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: priority == value
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
