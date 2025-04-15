import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      child: Container(
        height: 60,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: 'assets/svgs/home.svg',
              label: 'Home',
              index: 0,
            ),
            _buildNavItem(
              icon: 'assets/svgs/vote.svg',
              label: 'Vote',
              index: 1,
            ),
            _buildNavItem(
              icon: 'assets/svgs/result.svg',
              label: 'Results',
              index: 2,
            ),
            // _buildNavItem(
            //   icon: 'assets/svgs/profile.svg',
            //   label: 'Profile',
            //   index: 3,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
  }) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            color: widget.selectedIndex == index
                ? const Color(0xFF017BFF)
                : Colors.black,
            height: 25,
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.selectedIndex == index
                  ? const Color(0xFF017BFF)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
