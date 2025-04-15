import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/bottom_nav_bar.dart';
import '../models/candidates.dart';
import '../services/api_service.dart';
import '../services/web_3_service.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();
  final Web3Service _web3Service = Web3Service();
  List<Candidate> _candidates = [];
  Map<String, int> _voteResults = {};
  bool _isLoading = true;
  int _selectedNavIndex = 2;
  bool _electionEnded = false; // You'll need to implement this check
  int _totalVotes = 0;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load candidates
      final candidates = await _apiService.getAllCandidates();
      setState(() {
        _candidates = candidates;
      });

      _electionEnded = true; // For testing purposes

      if (_electionEnded) {
        for (var candidate in _candidates) {
          final voteCount = await _web3Service.getVoteCount(candidate.name);
          setState(() {
            _voteResults[candidate.name] = voteCount;
            _totalVotes += voteCount;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading results: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Widget _buildResultCard(Candidate candidate) {
    final voteCount = _voteResults[candidate.name] ?? 0;
    final votePercentage = _totalVotes > 0
        ? (voteCount / _totalVotes * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 4,
            spreadRadius: 1,
            offset: Offset(-1, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'http://192.168.31.83:3000${candidate.candidatePhoto}',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60,
                      width: 60,
                      color: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600]),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        candidate.partyName,
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$voteCount votes',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF017BFF),
                      ),
                    ),
                    Text(
                      '$votePercentage%',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 4,
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _totalVotes > 0 ? voteCount / _totalVotes : 0,
                backgroundColor: Color(0xFFF2F3F5),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF017BFF)),
              ),
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : !_electionEnded
                ? Center(
                    child: Text(
                      'Results will be available after the election ends',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 30, horizontal: 20),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Election Results',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Total Votes: $_totalVotes',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF777777),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final userAddress =
                                        prefs.getString('wallet_address');
                                    if (userAddress != null) {
                                      await _web3Service
                                          .resetVoterState(userAddress);
                                      // Refresh the results
                                      await _loadResults();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Vote reset successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Failed to reset vote: $e')),
                                    );
                                  }
                                },
                                child: Text('Reset My Vote (Testing)'),
                              ),
                            ],
                          ),
                        ),
                        ..._candidates
                            .map((candidate) => _buildResultCard(candidate))
                            .toList(),
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
