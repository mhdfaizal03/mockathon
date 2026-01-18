import 'package:flutter/material.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/data_service.dart';
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
    // Determine how to load. Since getMarks returns a Stream, we can subscribe or just use StreamBuilder in build.
    // However, we want to pre-fill the controllers.
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
        double newScore = double.parse(_scoreController.text);

        // Construct new marks object preserving other fields
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
            targetRole: widget.studentId, // Targeting specific user
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
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.bentoDecoration(
                  color: AppTheme.bentoSurface,
                  radius: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.bentoAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForType(widget.markType),
                              color: AppTheme.bentoAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Score",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _scoreController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: "0 - 100",
                          prefixIcon: const Icon(Icons.star_outline),
                          filled: true,
                          fillColor: AppTheme.bentoBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          final n = double.tryParse(v);
                          if (n == null || n < 0 || n > 100)
                            return "Invalid score";
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Feedback",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _feedbackController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Write your observations here...",
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 70),
                            child: const Icon(Icons.edit_note),
                          ),
                          filled: true,
                          fillColor: AppTheme.bentoBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.bentoJacket,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "UPDATE MARKS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 100,
              ), // Space for bottom nav or just breathing room
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'aptitude':
        return Icons.psychology;
      case 'gd':
        return Icons.groups;
      case 'hr':
        return Icons.person_search;
      default:
        return Icons.assessment;
    }
  }
}
