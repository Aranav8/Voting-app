import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/candidate_card.dart';
import '../models/candidates.dart';
import '../services/api_service.dart';

class HomeScreen2 extends StatefulWidget {
  @override
  _HomeScreen2State createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  final ApiService _apiService = ApiService();
  List<Candidate> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final candidates = await _apiService.getAllCandidates();
      setState(() {
        _candidates = candidates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading candidates: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voting App'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final candidate = _candidates[index];
                return CandidateCard(candidate: candidate);
              },
            ),
    );
  }
}
