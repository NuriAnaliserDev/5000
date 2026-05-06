part of '../auto_table_review_screen.dart';

class _AutoTableReviewScreenState extends State<AutoTableReviewScreen>
    with AutoTableReviewFields, AutoTableReviewLogicMixin, AutoTableReviewUiMixin {
  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Hisobot Tahlili'),
        actions: [
          if (!_isLoading && _parsedData != null && _analysisError == null)
            TextButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.send, color: Colors.blue),
              label: const Text('YUBORISH',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _parsedData == null
              ? _buildErrorState()
              : _buildReviewLayout(),
    );
  }
}
