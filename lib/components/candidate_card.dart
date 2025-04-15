import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candidates.dart';
import '../notifier/wallet_state.dart';
import '../screens/confirm_screen.dart';
import '../screens/info_screen.dart';
import '../services/web_3_service.dart';

class CandidateCard extends StatefulWidget {
  final Candidate candidate;

  const CandidateCard({Key? key, required this.candidate}) : super(key: key);

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  bool isLoading = false;
  final Web3Service _web3Service = Web3Service();
  final WalletState _walletState = WalletState();
  bool hasVoted = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _walletState.addListener(_onWalletStateChanged);
  }

  Future<void> _initializeData() async {
    await _walletState.initializeWalletState();
    if (_walletState.isWalletConnected) {
      await _checkVotingStatus();
    }
  }

  void _onWalletStateChanged() {
    setState(() {});
    if (_walletState.isWalletConnected) {
      _checkVotingStatus();
    }
  }

  Future<void> _connectWallet() async {
    if (isLoading) return;

    try {
      setState(() {
        isLoading = true;
      });

      // Replace with your test account details or wallet connection logic
      final testPrivateKey =
          '5a5e4e84c84f356c5f39bd37c655f05641c910f7788ba78548aebb4fbb3b6e0a';
      final testAddress = '0xC85f2bf5F42b170E7D2612B78ef05ad99281d880';

      await _walletState.setWalletDetails(testPrivateKey, testAddress);

      await _checkVotingStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet connected successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect wallet: Please try again')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _walletState.removeListener(_onWalletStateChanged);
    super.dispose();
  }

  Future<void> _checkVotingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userAddress = prefs.getString('wallet_address');

    if (userAddress != null) {
      try {
        final voted = await _web3Service.checkIfVoted(userAddress);
        if (mounted) {
          setState(() {
            hasVoted = voted;
          });
        }
      } catch (e) {
        print('Error checking voting status: $e');
      }
    }
  }

  Future<void> _handleVoteAction() async {
    if (!_walletState.isWalletConnected) {
      await _connectWallet();
      return;
    }

    if (isLoading || hasVoted) return;

    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final privateKey = prefs.getString('private_key');

      if (privateKey == null) {
        throw Exception('Wallet not connected');
      }

      // Submit vote to blockchain
      await _web3Service.vote(widget.candidate.name, privateKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          hasVoted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to submit vote: Please try again';

        if (e.toString().contains('Already voted')) {
          errorMessage = 'You have already cast your vote';
          setState(() {
            hasVoted = true;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getButtonText() {
    if (hasVoted) return 'Already Voted';
    if (!_walletState.isWalletConnected) return 'Connect Wallet to Vote';
    return 'Vote for ${widget.candidate.name}';
  }

  Future<void> _navigateToConfirmScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmScreen(candidate: widget.candidate),
      ),
    );

    // Update voting status when returning from ConfirmScreen
    if (result == true) {
      await _checkVotingStatus();
    }
  }

  void _navigateToCandidateInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoScreen(
          candidate: widget.candidate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 4,
            spreadRadius: 1,
            offset: Offset(-1, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Image.network(
                        'http://192.168.31.83:3000${widget.candidate.candidatePhoto}',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Image.network(
                        'http://192.168.31.83:3000${widget.candidate.partyPhoto}',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.group, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              widget.candidate.name,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              widget.candidate.partyName,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToCandidateInfo,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFC0BEBE), width: .5),
                          right:
                              BorderSide(color: Color(0xFFC0BEBE), width: .5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Candidate Info',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InfoScreen(
                            candidate: widget.candidate,
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFC0BEBE), width: .5),
                          right:
                              BorderSide(color: Color(0xFFC0BEBE), width: .5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Party Info',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasVoted ? null : _navigateToConfirmScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasVoted ? Colors.grey : const Color(0xFF017BFF),
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: Text(
                    hasVoted ? 'Already Voted' : 'Vote',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
