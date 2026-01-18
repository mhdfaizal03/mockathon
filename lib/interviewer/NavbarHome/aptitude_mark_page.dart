import 'package:flutter/material.dart';
import 'package:mockathon/core/widgets/mark_form.dart';

class AptitudeMarkPage extends StatelessWidget {
  final String studentId;
  const AptitudeMarkPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return MarkForm(
      title: "Aptitude Round",
      studentId: studentId,
      markType: 'aptitude',
    );
  }
}
