import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/models/vehicle_options_model.dart';
import 'package:pakyaw/pages/account/account_page.dart';
import 'package:pakyaw/pages/authenticate/display_name.dart';
import 'package:pakyaw/pages/blocked_screen.dart';
import 'package:pakyaw/pages/history/history_page.dart';
import 'package:pakyaw/pages/home/home_page.dart';
import 'package:pakyaw/pages/home/vehicle_options.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../shared/loading.dart';

class Home extends ConsumerStatefulWidget {
  final String id;
  const Home({super.key, required this.id});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _currentIndex = 0;

  // Modern color palette
  final Color primaryColor = const Color(0xFF83358E); // Purple
  final Color accentColor = const Color(0xFFFFD41C);  // Yellow
  final Color backgroundColor = const Color(0xFFF8F8F8); // Light background

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(getUserProvider(widget.id));

    SizeConfig().init(context);

    List<Widget> pages = [
      const HomePage(),
      const HistoryPage(),
      const AccountPage(),
    ];

    return user.when(
      data: (data) {
        if (data.blockedStatus) {
          return const BlockedScreen();
        } else {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: pages[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                currentIndex: _currentIndex,
                onTap: (int newIndex) {
                  setState(() {
                    _currentIndex = newIndex;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedFontSize: SizeConfig.safeBlockHorizontal * 4.5,
                unselectedFontSize: SizeConfig.safeBlockHorizontal * 4,
                selectedItemColor: primaryColor,
                unselectedItemColor: Colors.grey.shade600,
                showUnselectedLabels: true,
                elevation: 0,
                items: [
                  _buildNavItem(Icons.home, "Home", 0),
                  _buildNavItem(Icons.history, "History", 1),
                  _buildNavItem(Icons.person, "Profile", 2),
                ],
              ),
            ),
          );
        }
      },
      error: (error, stack) => ErrorCatch(error: '$error'),
      loading: () => const Loading(),
    );
  }

  /// Helper widget for glowing icons
  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          icon,
          size: SizeConfig.safeBlockHorizontal * 8,
          color: isSelected ? primaryColor : Colors.grey.shade600,
          shadows: isSelected
              ? [
            Shadow(
              color: primaryColor.withOpacity(0.6),
              blurRadius: 15,
            ),
          ]
              : [],
        ),
      ),
      label: label,
    );
  }
}
