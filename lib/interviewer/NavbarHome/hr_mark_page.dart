import 'package:flutter/material.dart';
import 'package:mockathon/core/widgets/mark_form.dart';

class HrMarkPage extends StatelessWidget {
  final String studentId;
  const HrMarkPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return MarkForm(
      title: "Technical / HR Round",
      studentId: studentId,
      markType: 'hr',
    );
  }
}
