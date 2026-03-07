import 'package:flutter/material.dart';
import 'package:mockathon/core/widgets/mark_form.dart';

class TechnicalMarkPage extends StatelessWidget {
  final String studentId;
  const TechnicalMarkPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return MarkForm(
      title: "Technical Round",
      studentId: studentId,
      markType: 'technical',
      maxScore: 25.0,
    );
  }
}
