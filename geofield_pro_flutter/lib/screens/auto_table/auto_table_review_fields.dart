part of '../auto_table_review_screen.dart';

mixin AutoTableReviewFields on State<AutoTableReviewScreen> {
  final AiTranslatorService _aiService = AiTranslatorService();
  bool _isLoading = true;
  Map<String, dynamic>? _parsedData;
  List<Map<String, dynamic>> _tableRows = [];
  String? _analysisError;
}
