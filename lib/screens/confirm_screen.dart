import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voting_application/screens/done_screen.dart';
import 'dart:async';
import '../components/bottom_nav_bar.dart';
import '../models/candidates.dart';
import '../notifier/wallet_state.dart';
import '../services/user_service.dart';
import '../services/email_otp_service.dart';
import '../services/web_3_service.dart';
import 'home_screen.dart';
import 'info_screen.dart';

class ConfirmScreen extends StatefulWidget {
  final Candidate candidate;
  const ConfirmScreen({
    super.key,
    required this.candidate,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final UserService _userService = UserService();
  final EmailOtpService _otpService = EmailOtpService();
  final Web3Service _web3Service = Web3Service();
  final WalletState _walletState = WalletState();
  bool _isVoting = false;
  int _selectedNavIndex = 1;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  int _resendTimer = 0;
  Timer? _timer;
  List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    await _walletState.initializeWalletState();
    if (!_walletState.isWalletConnected) {
      await _connectWallet();
    }
  }

  Future<void> _connectWallet() async {
    try {
      // Replace with your test account details
      final testPrivateKey =
          '5a5e4e84c84f356c5f39bd37c655f05641c910f7788ba78548aebb4fbb3b6e0a';
      final testAddress = '0xC85f2bf5F42b170E7D2612B78ef05ad99281d880';

      await _walletState.setWalletDetails(testPrivateKey, testAddress);
    } catch (e) {
      print('Error connecting wallet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect wallet: $e')),
        );
      }
    }
  }

  bool get _isOtpComplete {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  Future<void> _handleVoteSubmission() async {
    if (_isVoting || !_isOtpComplete) return;

    setState(() {
      _isVoting = true;
    });

    try {
      // First verify OTP
      String enteredOtp = _otpControllers.map((c) => c.text).join();
      bool isOtpValid = await _otpService.verifyOtp(enteredOtp);

      if (!isOtpValid) {
        throw Exception('Invalid OTP');
      }

      // Check wallet connection
      if (!_walletState.isWalletConnected) {
        await _connectWallet();
      }

      final prefs = await SharedPreferences.getInstance();
      final privateKey = prefs.getString('private_key');

      if (privateKey == null) {
        throw Exception('Wallet not connected properly');
      }

      // Check if already voted
      final userAddress = prefs.getString('wallet_address');
      if (userAddress != null) {
        final hasVoted = await _web3Service.checkIfVoted(userAddress);
        if (hasVoted) {
          throw Exception('Already voted');
        }
      }

      print('Submitting vote for: ${widget.candidate.name}'); // Debug log
      print(
          'Using private key: ${privateKey.substring(0, 6)}...'); // Debug log (partial key for safety)

      // Submit vote to blockchain
      final result = await _web3Service.vote(widget.candidate.name, privateKey);
      print('Vote submission result: $result'); // Debug log

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate successful vote
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => DoneScreen()));
      }
    } catch (e) {
      print('Error during vote submission: $e'); // Debug log
      if (mounted) {
        String errorMessage;

        if (e.toString().contains('Invalid OTP')) {
          errorMessage = 'Invalid OTP. Please try again.';
        } else if (e.toString().contains('Already voted')) {
          errorMessage = 'You have already cast your vote';
        } else if (e.toString().contains('Wallet not connected')) {
          errorMessage = 'Wallet connection failed. Please try again.';
        } else {
          errorMessage = 'Failed to submit vote: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _isOtpSent = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    setState(() {
      _isSendingOtp = true;
    });

    String? email = _userService.getCurrentUserEmail();
    if (email != null) {
      try {
        bool success = await _otpService.sendOtpEmail(recipientEmail: email);
        if (success) {
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP sent successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP')),
          );
        }
      } finally {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length == 6) {
      try {
        bool isValid = await _otpService.verifyOtp(enteredOtp);
        if (isValid) {
          // Handle successful verification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP verified successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid OTP')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
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
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 650,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
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
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              height: 80,
                                              width: 80,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.person,
                                                  color: Colors.grey[600]),
                                            ),
                                          ),
                                          const SizedBox(width: 30),
                                          Image.network(
                                            'http://192.168.31.83:3000${widget.candidate.partyPhoto}',
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              height: 80,
                                              width: 80,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.group,
                                                  color: Colors.grey[600]),
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17),
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
                                              top: BorderSide(
                                                  color: Color(0xFFC0BEBE),
                                                  width: .5),
                                              right: BorderSide(
                                                  color: Color(0xFFC0BEBE),
                                                  width: .5),
                                              bottom: BorderSide(
                                                  color: Color(0xFFC0BEBE),
                                                  width: .5),
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
                                              top: BorderSide(
                                                  color: Color(0xFFC0BEBE),
                                                  width: .5),
                                              right: BorderSide(
                                                  color: Color(0xFFC0BEBE),
                                                  width: .5),
                                              bottom: BorderSide(
                                                  color: Color(0xFFC0BEBE),
                                                  width: .5),
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
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 50),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'You receive OTP at \n',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                height: 2,
                                              ),
                                            ),
                                            TextSpan(
                                              text: _userService
                                                  .getCurrentUserEmail(),
                                              style: TextStyle(
                                                color: Color(0xFF017BFF),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _isSendingOtp
                                          ? CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Color(0xFF017BFF),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: _resendTimer == 0
                                                  ? _sendOtp
                                                  : null,
                                              child: Text(
                                                _isOtpSent
                                                    ? _resendTimer > 0
                                                        ? 'Resend code in ${_resendTimer}s'
                                                        : 'Resend Code'
                                                    : 'Send OTP',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: _resendTimer > 0
                                                      ? Colors.grey
                                                      : Color(0xFF017BFF),
                                                ),
                                              ),
                                            ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            6,
                                            (index) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              child: Container(
                                                height: 45,
                                                width: 45,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(8)),
                                                  color:
                                                      const Color(0xFFF1F1F1),
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _otpControllers[index],
                                                  focusNode: _focusNodes[index],
                                                  textAlign: TextAlign.center,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  maxLength: 1,
                                                  decoration: InputDecoration(
                                                    counterText: "",
                                                    border: InputBorder.none,
                                                  ),
                                                  onChanged: (value) {
                                                    setState(
                                                        () {}); // Trigger rebuild for button state
                                                    if (value.length == 1 &&
                                                        index < 5) {
                                                      _focusNodes[index + 1]
                                                          .requestFocus();
                                                    } else if (value.isEmpty &&
                                                        index > 0) {
                                                      _focusNodes[index - 1]
                                                          .requestFocus();
                                                    }
                                                    if (index == 5 &&
                                                        value.length == 1) {
                                                      _verifyOtp();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Container(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isOtpComplete &&
                                              !_isVoting &&
                                              _walletState.isWalletConnected
                                          ? _handleVoteSubmission
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF017BFF),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.all(15),
                                      ),
                                      child: _isVoting
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              _walletState.isWalletConnected
                                                  ? 'Vote Now'
                                                  : 'Connecting Wallet...',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, bottom: 20),
                                  child: Container(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.all(15),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
