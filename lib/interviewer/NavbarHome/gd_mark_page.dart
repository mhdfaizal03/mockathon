import 'package:flutter/material.dart';
import 'package:mockathon/core/widgets/mark_form.dart';

class GdMarkPage extends StatelessWidget {
  final String studentId;
  const GdMarkPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return MarkForm(
      title: "Group Discussion Round",
      studentId: studentId,
      markType: 'gd',
    );
  }
}
