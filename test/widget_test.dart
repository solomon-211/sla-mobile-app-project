import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sla_mobile_app/main.dart';
import 'package:sla_mobile_app/models/task.dart';
import 'package:sla_mobile_app/screens/create_edit_task_screen.dart';
import 'package:sla_mobile_app/theme/app_theme.dart';

void main() {
  testWidgets('shows validation errors when the form is empty', (tester) async {
    await tester.pumpWidget(const TempoApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
    await tester.pump();

    expect(find.text('Title is required (3–60 characters)'), findsOneWidget);
    expect(find.text('Assignee is required'), findsOneWidget);
    expect(find.text('Due date is required'), findsOneWidget);
  });

  testWidgets('prefills the form when editing a task', (tester) async {
    final task = Task(
      id: 'T-014',
      title: 'Write API error states',
      description: 'Show clear messages for timeouts.',
      assignee: kTeamMembers.first,
      dueDate: DateTime(2026, 10, 6, 9),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CreateEditTaskScreen(task: task),
      ),
    );

    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Write API error states'), findsOneWidget);
    expect(find.text('6 Oct 2026, 09:00'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save Changes'), findsOneWidget);
  });
}
