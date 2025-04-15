import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:voting_application/screens/login_screen.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class PanVerificationScreen extends StatefulWidget {
  const PanVerificationScreen({super.key});

  @override
  State<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends State<PanVerificationScreen> {
  final TextEditingController panController = TextEditingController();
  bool isLoading = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    checkVerificationStatus();
  }

  Future<void> checkVerificationStatus() async {
    bool isPanVerified = await _userService.isPanVerified();

    if (mounted && isPanVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  bool isValidPAN(String pan) {
    RegExp panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return panPattern.hasMatch(pan);
  }

  void showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> verifyPAN() async {
    String pan = panController.text.toUpperCase();
    if (pan.isEmpty) {
      showMessage('Please enter PAN number', true);
      return;
    }

    if (!isValidPAN(pan)) {
      showMessage('Invalid PAN format. Please enter a valid PAN', true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Update PAN verification status and store PAN number
      await _userService.updateUserData({
        'isPanVerified': true,
        'pan': panController.text.toUpperCase(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      showMessage('Verification failed. Please try again.', true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 20),
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
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Verify your PAN and get ready to \nvote for your favourite candidate!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                BuildLoginField(controller: panController, hint: 'Enter Pan'),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : verifyPAN,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF017BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                              'Confirm',
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
    );
  }
}
