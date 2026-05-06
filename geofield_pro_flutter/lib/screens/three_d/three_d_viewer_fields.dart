part of '../three_d_viewer_screen.dart';

mixin ThreeDViewerStateFields on State<ThreeDViewerScreen> {
  double _rotationX = 0.5;
  double _rotationY = 0.5;
  double _zoom = 1.0;

  late LatLng _center;
  late double _avgAlt;
}
