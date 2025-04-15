import 'dart:async';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:voting_application/screens/results_screen.dart';
import 'package:voting_application/screens/vote_screen.dart';
import 'package:voting_application/components/bottom_nav_bar.dart';
import 'package:voting_application/screens/home_screen2.dart';
import '../components/app_drawer.dart';
import '../components/candidate_card.dart';
import '../models/candidates.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  int _currentBannerIndex = 0;
  bool isLoading = false;
  bool isFAQExpanded = false;
  int _selectedNavIndex = 0;
  List<Candidate> _candidates = [];
  List<Candidate> _filteredCandidates = [];
  List<FAQ> _faqs = [];
  List<FAQ> _filteredFaqs = [];
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCandidates();
    _initializeFAQs();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates() async {
    try {
      final candidates = await _apiService.getAllCandidates();
      setState(() {
        _candidates = candidates;
        _filteredCandidates = List.from(candidates);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading candidates: $e')),
      );
    }
  }

  final List<String> bannerImages = [
    'assets/pngs/banner1.jpg',
    'assets/pngs/banner2.jpg',
    'assets/pngs/banner3.jpg',
    'assets/pngs/banner4.jpg',
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VoteScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultsScreen()),
      );
    } else if (index == 3) {}
  }

  Future<void> voteNow() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VoteScreen()),
        );
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeFAQs() {
    _faqs = [
      FAQ(
        question: 'How is my vote secure and anonymous?',
        answer:
            'Your vote is recorded on a tamper-proof blockchain, ensuring security. Cryptographic methods keep your vote anonymous and untraceable.',
      ),
      FAQ(
        question: 'Can I change my vote after casting it?',
        answer:
            'No, once confirmed, votes are permanently recorded on the blockchain. A review screen helps you verify your choice before submission.',
      ),
      FAQ(
        question: 'How do I know my vote was counted?',
        answer:
            "You'll receive a transaction ID to track your vote on the blockchain and confirm it was recorded correctly.",
      ),
      FAQ(
        question: 'Can I use the app without a crypto wallet?',
        answer:
            'No, a wallet is required for secure voting. The app guides you in setting up one if needed.',
      ),
    ];
    _filteredFaqs = List.from(_faqs);
  }

  void _onSearchChanged() {
    final searchTerm = searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredCandidates = List.from(_candidates);
        _filteredFaqs = List.from(_faqs);
      } else {
        // Filter candidates
        _filteredCandidates = _candidates.where((candidate) {
          final name = candidate.name.toLowerCase();
          final party = candidate.partyName.toLowerCase();

          return name.contains(searchTerm) || party.contains(searchTerm);
        }).toList();

        // Filter FAQs
        _filteredFaqs = _faqs.where((faq) {
          final question = faq.question.toLowerCase();
          final answer = faq.answer.toLowerCase();

          return question.contains(searchTerm) || answer.contains(searchTerm);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      drawer: AppDrawer(currentRoute: 'home'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        child: SvgPicture.asset(
                          'assets/svgs/Menu.svg',
                          height: 30,
                        ),
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      SvgPicture.asset(
                        'assets/svgs/Notifications.svg',
                        height: 30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _sliderBanner(),
                ),
                SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ongoing Elections',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Container(
                          height: 350,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F6FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delhi State Assembly Elections',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Your Constituency is Wazirpur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF777777),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      OngoingElectionsBox(
                                        title: DateFormat('hh:mm a')
                                            .format(DateTime.now()),
                                        subtitle:
                                            "Voting ends at \n5:00pm 5th Jan'25",
                                      ),
                                      OngoingElectionsBox(
                                        title: '10000',
                                        subtitle:
                                            'Voters voted\nthrough mobile',
                                        isAnimated: true,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : voteNow,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF017BFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Candidates List${searchController.text.isNotEmpty ? ' (${_filteredCandidates.length})' : ''}",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => VoteScreen()),
                              ),
                              child: Text(
                                "View all",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_filteredCandidates.isEmpty &&
                          searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No candidates found matching "${searchController.text}"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filteredCandidates.length,
                            itemBuilder: (context, index) {
                              final candidate = _filteredCandidates[index];
                              return Container(
                                width: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right:
                                        index == _filteredCandidates.length - 1
                                            ? 0
                                            : 10,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      'http://192.168.31.83:3000${candidate.candidatePhoto}',
                                      height: 70,
                                      width: 130,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x25000000),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: Offset(-1, 2),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                  'assets/pngs/narendra_modi_pic.jpeg'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Narendra Modi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Prime Minister of India',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF777777),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'I encourage citizens across all states to actively \nparticipate in the elections and cast their votes to \nshape a better future for our nation.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        child: SvgPicture.asset(
                          'assets/svgs/Format_quote.svg',
                          height: 70,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FAQ's${searchController.text.isNotEmpty ? ' (${_filteredFaqs.length})' : ''}",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (_filteredFaqs.isEmpty &&
                          searchController.text.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No FAQs found matching "${searchController.text}"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._filteredFaqs.map((faq) => FaqBox(
                              question: faq.question,
                              answer: faq.answer,
                            )),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _sliderBanner() {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: bannerImages.length,
          itemBuilder: (context, index, realIndex) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: AssetImage(bannerImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 180,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            aspectRatio: 16 / 8,
            viewportFraction: 0.95,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerImages.asMap().entries.map((entry) {
            return Container(
              width: 24,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _currentBannerIndex == entry.key
                    ? Colors.blue
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class FaqBox extends StatefulWidget {
  const FaqBox({
    super.key,
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  State<FaqBox> createState() => _FaqBoxState();
}

class _FaqBoxState extends State<FaqBox> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FF),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.answer,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OngoingElectionsBox extends StatefulWidget {
  const OngoingElectionsBox({
    super.key,
    required this.title,
    required this.subtitle,
    this.isAnimated = false,
  });

  final String title;
  final String subtitle;
  final bool isAnimated;

  @override
  State<OngoingElectionsBox> createState() => _OngoingElectionsBoxState();
}

class _OngoingElectionsBoxState extends State<OngoingElectionsBox> {
  int value = 0;
  Timer? _timer;
  static const int finalValue = 10000;
  static const int updateInterval = 50;
  static const int animationDuration = 1500;

  @override
  void initState() {
    super.initState();
    if (widget.isAnimated) {
      final steps = animationDuration ~/ updateInterval;
      final increment = finalValue ~/ steps;

      _timer = Timer.periodic(Duration(milliseconds: updateInterval), (timer) {
        setState(() {
          if (value + increment >= finalValue) {
            value = finalValue;
            timer.cancel();
          } else {
            value += increment;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.isAnimated
                ? AnimatedFlipCounter(
                    duration: const Duration(milliseconds: updateInterval),
                    value: value,
                    thousandSeparator: ',',
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  )
                : Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                    textAlign: TextAlign.center,
                  ),
            const SizedBox(height: 10),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF777777),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});
}
