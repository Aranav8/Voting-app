import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:voting_application/screens/results_screen.dart';
import '../components/app_drawer.dart';
import '../components/bottom_nav_bar.dart';
import '../components/candidate_card.dart';
import '../models/candidates.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'login_screen.dart'; // Make sure to import your login screen

class VoteScreen extends StatefulWidget {
  @override
  _VoteScreenState createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final TextEditingController searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  List<Candidate> _candidates = [];
  List<Candidate> _filteredCandidates = [];
  int _selectedNavIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCandidates();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchTerm = searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredCandidates = List.from(_candidates);
      } else {
        _filteredCandidates = _candidates.where((candidate) {
          final name = candidate.name.toLowerCase();
          final party = candidate.partyName.toLowerCase();
          return name.contains(searchTerm) || party.contains(searchTerm);
        }).toList();
      }
    });
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultsScreen()),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: AppDrawer(currentRoute: 'vote'),
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
                          GestureDetector(
                            onTap: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            child: SvgPicture.asset(
                              'assets/svgs/Menu.svg',
                              height: 30,
                            ),
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
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delhi State Assembly Elections',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Candidates',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 20),
                          _filteredCandidates.isEmpty &&
                                  searchController.text.isNotEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      'No candidates found matching "${searchController.text}"',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: _filteredCandidates.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 20),
                                  itemBuilder: (context, index) {
                                    final candidate =
                                        _filteredCandidates[index];
                                    return CandidateCard(candidate: candidate);
                                  },
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
