import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/data_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mockathon/models/user_models.dart';

class MarkForm extends StatefulWidget {
  final String title;
  final String studentId;
  final String markType; // 'aptitude', 'gd', 'hr'

  const MarkForm({
    super.key,
    required this.title,
    required this.studentId,
    required this.markType,
  });

  @override
  State<MarkForm> createState() => _MarkFormState();
}

class _MarkFormState extends State<MarkForm> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  bool _isLoading = false;
  MarkModel? _currentMarks;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final stream = _dataService.getMarks(widget.studentId);
    stream.listen((marks) {
      if (mounted && marks != null) {
        setState(() {
          _currentMarks = marks;
          double score = 0;
          if (widget.markType == 'aptitude') {
            score = marks.aptitude;
            _feedbackController.text = marks.aptitudeFeedback;
          } else if (widget.markType == 'gd') {
            score = marks.gd;
            _feedbackController.text = marks.gdFeedback;
          } else if (widget.markType == 'hr') {
            score = marks.hr;
            _feedbackController.text = marks.hrFeedback;
          }

          if (_scoreController.text.isEmpty) {
            _scoreController.text = score > 0 ? score.toString() : '';
          }
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        double newScore = double.tryParse(_scoreController.text) ?? 0.0;

        MarkModel newMarks = MarkModel(
          aptitude: widget.markType == 'aptitude'
              ? newScore
              : (_currentMarks?.aptitude ?? 0),
          aptitudeFeedback: widget.markType == 'aptitude'
              ? _feedbackController.text
              : (_currentMarks?.aptitudeFeedback ?? ''),
          gd: widget.markType == 'gd' ? newScore : (_currentMarks?.gd ?? 0),
          gdFeedback: widget.markType == 'gd'
              ? _feedbackController.text
              : (_currentMarks?.gdFeedback ?? ''),
          hr: widget.markType == 'hr' ? newScore : (_currentMarks?.hr ?? 0),
          hrFeedback: widget.markType == 'hr'
              ? _feedbackController.text
              : (_currentMarks?.hrFeedback ?? ''),
        );

        await _dataService.updateMarks(widget.studentId, newMarks);

        // Also send notification
        await _dataService.broadcastNotification(
          NotificationModel(
            id: '',
            title: "Mark Updated",
            message: "Your ${widget.title} marks have been updated.",
            timestamp: DateTime.now(),
            targetRole: widget.studentId,
            type: 'info',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${widget.title} marks saved!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error saving marks"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Slightly narrower for focus
          child: Column(
            children: [
              // Header Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.bentoDecoration(
                  color: Colors.white,
                  radius: 32,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryIndigo.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(widget.markType),
                        color: AppTheme.primaryIndigo,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Enter assessment details below",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),

              // Form Container
              Container(
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.bentoDecoration(
                  color: Colors.white,
                  radius: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Score", Icons.star_rounded),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _scoreController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),

                        decoration: InputDecoration(
                          hintText: "0",
                          suffixText: "/ ${_getMaxScore().toInt()}",
                          suffixStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: AppTheme.bentoBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppTheme.primaryIndigo,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          final n = double.tryParse(v);
                          final max = _getMaxScore();
                          if (n == null || n < 0 || n > max) {
                            return "Max allowed is $max";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                      ),

                      const SizedBox(height: 32),

                      _buildLabel("Feedback", Icons.edit_note_rounded),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _feedbackController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Write detailed observations...",
                          filled: true,
                          fillColor: AppTheme.bentoBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: AppTheme.primaryIndigo,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(24),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryIndigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "SUBMIT EVALUATION",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]), // Subtle icon
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  double _getMaxScore() {
    switch (widget.markType) {
      case 'aptitude':
        return 25.0;
      case 'gd':
        return 25.0;
      case 'hr':
        return 25.0;
      default:
        return 100.0;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'aptitude':
        return Icons.psychology_alt_rounded;
      case 'gd':
        return Icons.groups_3_rounded;
      case 'hr':
        return Icons.person_search_rounded;
      default:
        return Icons.assessment_rounded;
    }
  }
}
