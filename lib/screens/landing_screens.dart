import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_screen.dart';

class LandingScreens extends StatefulWidget {
  const LandingScreens({super.key});

  @override
  State<LandingScreens> createState() => _LandingScreensState();
}

class _LandingScreensState extends State<LandingScreens> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNextPressed() {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage(
                    title: 'Are you ready \nto vote?',
                    description:
                        'Welcome to DigiVote, the app that makes \nvoting secure & transparent. Take part in \nelections, wherever you are.',
                    svgPath: 'assets/svgs/screen_1.svg',
                  ),
                  _buildPage(
                    title: '100% safe and secure \nvoting',
                    description:
                        'Since our app is built on the blockchain, it is \ncompletely secure. Results and votes cannot be \nmanipulated by a third party.',
                    svgPath: 'assets/svgs/screen_2.svg',
                  ),
                  _buildPage(
                    title: 'Completely open, clear \nand verificable',
                    description:
                        'Full transparency is made possible by \nblockchain technology. Any participant in the \nsystem has the ability to verify each vote.',
                    svgPath: 'assets/svgs/screen_3.svg',
                  ),
                  _buildPage(
                    title: 'Make a Difference',
                    description:
                        'Be part of shaping a better future \nwith your vote.',
                    svgPath: 'assets/svgs/screen_4.svg',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    height: 7,
                    width: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _currentIndex == index
                          ? const Color(0xFF017BFF)
                          : const Color(0xFFC0BEBE),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _currentIndex < 3 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String svgPath,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFFC0BEBE)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'DigiVote',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 100),
          Center(
            child: SvgPicture.asset(
              svgPath,
              height: 200,
            ),
          ),
        ],
      ),
    );
  }
}
