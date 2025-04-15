import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/vote_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final Color selectedColor = Color(0xFF017BFF);

  AppDrawer({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _navigateToScreen(BuildContext context, String route) {
    if (currentRoute == route) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          switch (route) {
            case 'home':
              return HomeScreen();
            case 'vote':
              return VoteScreen();
            default:
              return HomeScreen();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: selectedColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/svgs/logo_svg_white.svg',
                  width: 150,
                ),
              ],
            ),
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/svgs/home.svg',
              height: 24,
              width: 24,
              color: currentRoute == 'home' ? selectedColor : Colors.black54,
            ),
            title: Text(
              'Home',
              style: TextStyle(
                color: currentRoute == 'home' ? selectedColor : Colors.black,
              ),
            ),
            selected: currentRoute == 'home',
            selectedColor: selectedColor,
            onTap: () => _navigateToScreen(context, 'home'),
          ),
          ListTile(
            leading: SvgPicture.asset(
              'assets/svgs/vote.svg',
              height: 24,
              width: 24,
              color: currentRoute == 'vote' ? selectedColor : Colors.black54,
            ),
            title: Text(
              'Vote',
              style: TextStyle(
                color: currentRoute == 'vote' ? selectedColor : Colors.black,
              ),
            ),
            selected: currentRoute == 'vote',
            selectedColor: selectedColor,
            onTap: () => _navigateToScreen(context, 'vote'),
          ),
          ListTile(
            leading: Icon(
              Icons.info,
              color: currentRoute == 'about' ? selectedColor : Colors.black54,
            ),
            title: Text(
              'About',
              style: TextStyle(
                color: currentRoute == 'about' ? selectedColor : Colors.black,
              ),
            ),
            selected: currentRoute == 'about',
            selectedColor: selectedColor,
            onTap: () {
              Navigator.pop(context);
              // Add about screen navigation when ready
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.settings,
              color:
                  currentRoute == 'settings' ? selectedColor : Colors.black54,
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color:
                    currentRoute == 'settings' ? selectedColor : Colors.black,
              ),
            ),
            selected: currentRoute == 'settings',
            selectedColor: selectedColor,
            onTap: () {
              Navigator.pop(context);
              // Add settings screen navigation when ready
            },
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.black54,
            ),
            title: Text('Logout'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
