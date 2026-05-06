part of '../auto_table_review_screen.dart';

mixin AutoTableReviewLogicMixin on AutoTableReviewFields {
  Future<void> _startAnalysis() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _analysisError = null;
        _parsedData = null;
        _tableRows = [];
      });
    }
    final result = await _aiService.analyzeReportImage(widget.imagePath);
    if (!mounted) return;
    if (result.containsKey('error') && result['error'] != null) {
      setState(() {
        _analysisError = result['error'].toString();
        _parsedData = null;
        _tableRows = [];
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _parsedData = result;
      _analysisError = null;
      final type = result['report_type'] ?? 'unknown';
      if (type == 'rc_drill' && result['holes'] != null) {
        _tableRows = List<Map<String, dynamic>>.from(result['holes']);
      } else if (type == 'ore_stockpile' && result['loaders'] != null) {
        _tableRows = List<Map<String, dynamic>>.from(result['loaders']);
      } else if (type == 'ore_block') {
        _tableRows = [Map<String, dynamic>.from(result)];
      }
      _isLoading = false;
    });
  }

  Future<void> _submitReport() async {
    if (_parsedData == null || _analysisError != null) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final settings = context.read<SettingsController>();
      final loc = context.read<LocationService>().currentPosition;
      final uid =
          auth.currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hisobot yuborish uchun avval tizimga kiring.')),
          );
        }
        return;
      }

      final updatedTable = List<Map<String, dynamic>>.from(_tableRows);
      final reportType = _parsedData!['report_type'] ?? 'unknown';

      await NetworkExecutor.execute(
        () => FirebaseFirestore.instance.collection('daily_mine_reports').add({
          'reportType': reportType,
          'authorUid': uid,
          'authorName': settings.currentUserName ??
              auth.currentUser?.email ??
              'Noma\'lum',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'imageUrl': '',
          'lat': loc?.latitude,
          'lng': loc?.longitude,
          'parsedData': {
            'header': {
              'date': _parsedData!['date'],
              'shift': _parsedData!['shift'],
              'driller': _parsedData!['driller'] ??
                  _parsedData!['spotter'] ??
                  _parsedData!['geologist'] ??
                  '—',
              'location':
                  _parsedData!['location'] ?? _parsedData!['pit'] ?? '—',
            },
            'table': updatedTable,
          },
        }),
        actionName: 'Submit Mine Report',
        maxRetries: 2,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Hisobot muvaffaqiyatli Dashboard\'ga yuborildi! ✅')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.show(context, ErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
