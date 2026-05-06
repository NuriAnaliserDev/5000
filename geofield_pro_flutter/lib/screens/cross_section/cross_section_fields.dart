part of '../cross_section_screen.dart';

mixin CrossSectionStateFields on State<CrossSectionScreen> {
  double _buffer = 500.0;
  double _exaggeration = 2.0;
  final _service = CrossSectionService();
}
