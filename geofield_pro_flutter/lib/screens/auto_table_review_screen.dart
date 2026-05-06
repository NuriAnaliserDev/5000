import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/ai_translator_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/settings_controller.dart';
import '../core/network/network_executor.dart';
import '../core/error/error_handler.dart';
import '../core/error/error_mapper.dart';
import '../utils/ai_vertex_error_helper.dart'
    show
        isVertexAiDisabledError,
        isVertexAiQuotaOrBillingError,
        openVertexErrorLink;
import '../utils/app_card.dart';

part 'auto_table/auto_table_review_fields.dart';
part 'auto_table/auto_table_review_logic.dart';
part 'auto_table/auto_table_review_ui.dart';
part 'auto_table/auto_table_review_state.dart';

class AutoTableReviewScreen extends StatefulWidget {
  final String imagePath;
  const AutoTableReviewScreen({super.key, required this.imagePath});

  @override
  State<AutoTableReviewScreen> createState() => _AutoTableReviewScreenState();
}
