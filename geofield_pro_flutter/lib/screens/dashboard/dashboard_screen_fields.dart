part of '../dashboard_screen.dart';

mixin DashboardScreenFields on State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
