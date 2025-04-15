import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voting_application/screens/confirm_screen.dart';
import '../components/bottom_nav_bar.dart';
import '../components/social_media_section.dart';
import '../models/candidates.dart';
import 'home_screen.dart';

class InfoScreen extends StatefulWidget {
  final Candidate candidate;
  final int initialTabIndex;

  const InfoScreen({
    super.key,
    required this.candidate,
    this.initialTabIndex = 0,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool isLoading = false;
  int selectedIndex = 0;
  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (index == 2) {
    } else if (index == 3) {}
  }

  String extractAbbreviation(String partyName) {
    final match = RegExp(r'\((.*?)\)').firstMatch(partyName);
    return match?.group(1) ?? partyName;
  }

  Widget buildContent() {
    switch (selectedIndex) {
      case 0:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Candidate',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                widget.candidate.candidateInfo,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Party',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                widget.candidate.partyInfo,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manifesto',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 10),
              Text(
                widget.candidate.manifesto,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(
                            'assets/svgs/Menu.svg',
                            height: 30,
                          ),
                          SvgPicture.asset(
                            'assets/svgs/Notifications.svg',
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.network(
                      'http://192.168.31.83:3000${widget.candidate.candidatePhoto}',
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.candidate.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 22),
                          ),
                          Text(
                            extractAbbreviation(widget.candidate.partyName),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFFC0BEBE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConfirmScreen(
                                          candidate: widget.candidate),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF017BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Vote Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = 0;
                              });
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: selectedIndex == 0
                                        ? Colors.blue
                                        : Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                  right: BorderSide(
                                    color: Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                  bottom: BorderSide(
                                    color: selectedIndex == 0
                                        ? Colors.blue
                                        : Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                ),
                                color: selectedIndex == 0
                                    ? Colors.blue[50]
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Candidate Info',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: selectedIndex == 0
                                        ? Colors.blue
                                        : Color(0xFF777777),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = 1;
                              });
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: selectedIndex == 1
                                        ? Colors.blue
                                        : Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                  right: BorderSide(
                                    color: Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                  bottom: BorderSide(
                                    color: selectedIndex == 1
                                        ? Colors.blue
                                        : Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                ),
                                color: selectedIndex == 1
                                    ? Colors.blue[50]
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Party Info',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: selectedIndex == 1
                                        ? Colors.blue
                                        : Color(0xFF777777),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = 2;
                              });
                            },
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: selectedIndex == 2
                                        ? Colors.blue
                                        : Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                  right: BorderSide(
                                    color: Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                  bottom: BorderSide(
                                    color: selectedIndex == 2
                                        ? Colors.blue
                                        : Color(0xFFC0BEBE),
                                    width: .5,
                                  ),
                                ),
                                color: selectedIndex == 2
                                    ? Colors.blue[50]
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  'Manifesto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: selectedIndex == 2
                                        ? Colors.blue
                                        : Color(0xFF777777),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: buildContent(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: SocialMediaSection(
                        socialLinks: [
                          SocialMediaLink(
                            platform: 'Facebook',
                            url: widget.candidate.socials.facebook,
                            iconPath: 'assets/svgs/facebook_icon.svg',
                          ),
                          SocialMediaLink(
                            platform: 'Instagram',
                            url: widget.candidate.socials.instagram,
                            iconPath: 'assets/svgs/instagram_icon.svg',
                          ),
                          SocialMediaLink(
                            platform: 'YouTube',
                            url: widget.candidate.socials.youtube,
                            iconPath: 'assets/svgs/youtube_icon.svg',
                          ),
                          SocialMediaLink(
                            platform: 'LinkedIn',
                            url: widget.candidate.socials.linkedin,
                            iconPath: 'assets/svgs/linkedin_icon.svg',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
