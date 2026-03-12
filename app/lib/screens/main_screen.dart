import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'screens.dart';

/// Main Screen with Bottom Navigation
/// 
/// Provides navigation between Home, Search, and Library tabs
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    if (!isDesktop) {
      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppTheme.surface,
            indicatorColor: AppTheme.accent.withAlpha(26),
            selectedIconTheme: const IconThemeData(color: AppTheme.accent),
            unselectedIconTheme: const IconThemeData(color: AppTheme.textDim),
            selectedLabelTextStyle: const TextStyle(
              fontFamily: 'Inconsolata',
              letterSpacing: 2,
              color: AppTheme.accent,
              fontSize: 10,
            ),
            unselectedLabelTextStyle: const TextStyle(
              fontFamily: 'Inconsolata',
              letterSpacing: 2,
              color: AppTheme.textDim,
              fontSize: 10,
            ),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Icon(Icons.graphic_eq, color: AppTheme.text, size: 20),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('HOME'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: Text('SEARCH'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: Text('LIBRARY'),
              ),
            ],
          ),
          VerticalDivider(color: AppTheme.border, width: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  ),
                ),
                VerticalDivider(color: AppTheme.border.withAlpha(120), width: 1),
                SizedBox(
                  width: 460,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(
                        left: BorderSide(color: AppTheme.border.withAlpha(90), width: 1),
                      ),
                    ),
                    child: const NowPlayingScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.border,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textDim,
        elevation: 0,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inconsolata',
          letterSpacing: 2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inconsolata',
          letterSpacing: 2,
        ),
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.home, 0),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.search, 1),
            label: 'SEARCH',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.library_music, 2),
            label: 'LIBRARY',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(
                color: AppTheme.accent.withAlpha(77),
                width: 1,
              )
            : null,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isSelected ? AppTheme.accent : AppTheme.textDim,
      ),
    );
  }
}
