import 'package:flutter/material.dart';
import 'package:mockathon/core/widgets/mark_form.dart';

class MachineTestMarkPage extends StatelessWidget {
  final String studentId;
  const MachineTestMarkPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return MarkForm(
      title: "Machine Test",
      studentId: studentId,
      markType: 'machine_test',
      maxScore: 25.0,
    );
  }
}
