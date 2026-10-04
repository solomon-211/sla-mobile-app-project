import 'package:flutter/material.dart';

import 'screens/create_edit_task_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TempoApp());
}

class TempoApp extends StatelessWidget {
  const TempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tempo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const CreateEditTaskScreen(),
    );
  }
}
