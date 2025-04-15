import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:voting_application/screens/pan_verification_screen.dart';
import '../services/email_otp_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class MobileVerificationScreen extends StatefulWidget {
  const MobileVerificationScreen({super.key});

  @override
  _MobileVerificationScreenState createState() =>
      _MobileVerificationScreenState();
}

class _MobileVerificationScreenState extends State<MobileVerificationScreen> {
  String _inputCode = "";
  final UserService _userService = UserService();
  bool isVerifying = false;
  bool isResending = false;
  Map<String, dynamic>? userData;
  final _emailOtpService = EmailOtpService();
  bool _isResendDisabled = false;
  int _resendCooldown = 30;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
    checkVerificationStatus();
  }

  Future<void> checkVerificationStatus() async {
    bool isEmailVerified = await _userService.isEmailVerified();
    bool isPanVerified = await _userService.isPanVerified();

    if (mounted) {
      if (isEmailVerified && !isPanVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PanVerificationScreen()),
        );
      } else if (isEmailVerified && isPanVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      isResending = true;
    });

    try {
      setState(() {
        _isResendDisabled = true;
        _resendCooldown = 30;
      });

      String? recipientEmail = _userService.getCurrentUserEmail();
      bool isSent =
          await _emailOtpService.sendOtpEmail(recipientEmail: recipientEmail);

      if (mounted) {
        if (isSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Code resent to $recipientEmail')),
          );
          _startCooldownTimer();
        } else {
          setState(() {
            _isResendDisabled = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to resend code. Please try again.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  void _startCooldownTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _isResendDisabled = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> verifyOtp() async {
    if (_inputCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {
      final isValid = await _emailOtpService.verifyOtp(_inputCode);

      if (mounted) {
        if (isValid) {
          // Wait for a small delay to ensure Firestore updates are completed
          await Future.delayed(const Duration(milliseconds: 500));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PanVerificationScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired code. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          // Clear the input code
          setState(() {
            _inputCode = "";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }

  Future<void> loadUserData() async {
    userData = await _userService.getCurrentUserData();
    setState(() {
      isLoading = false;
    });
  }

  void _onNumberPressed(String number) {
    if (_inputCode.length < 6) {
      setState(() {
        _inputCode += number;
      });
    }
  }

  void _onDeletePressed() {
    if (_inputCode.isNotEmpty) {
      setState(() {
        _inputCode = _inputCode.substring(0, _inputCode.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keypadWidth = screenSize.width * 0.8;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              Center(
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    color: Color(0xFF017BFF),
                  ),
                  child: Center(
                      child: SvgPicture.asset(
                    'assets/svgs/login.svg',
                    height: 30,
                    color: Colors.white,
                  )),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Email Sent!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'A magic code to sign in was sent to ',
                      style: TextStyle(color: Color(0xFF777777)),
                    ),
                    TextSpan(
                      text: _userService.getCurrentUserEmail(),
                      style: TextStyle(
                          color: Color(0xFF017BFF),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        color: const Color(0xFFF1F1F1),
                      ),
                      child: Center(
                        child: Text(
                          _inputCode.length > index ? _inputCode[index] : '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: keypadWidth,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 9) {
                        return SizedBox.shrink();
                      } else if (index == 10) {
                        return _buildNumberButton("0");
                      } else if (index == 11) {
                        return _buildDeleteButton();
                      } else {
                        return _buildNumberButton((index + 1).toString());
                      }
                    },
                  ),
                ),
              ),
              Spacer(),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (_isResendDisabled || isResending) ? null : _resendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Color(0xFFC0BEBE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isResendDisabled
                                ? 'Resend Code in $_resendCooldown'
                                : 'Resend Code',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _isResendDisabled
                                  ? Colors.grey
                                  : Color(0xFF017BFF),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNumberPressed(number),
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onDeletePressed,
          borderRadius: BorderRadius.circular(8),
          child: const Center(
            child: Icon(
              Icons.backspace,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
