import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voting_application/screens/pan_verification_screen.dart';
import 'package:voting_application/services/auth_service.dart';
import '../services/email_otp_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'mobile_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginSelected = true;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool isPasswordObsecured = true;
  final AuthService _authService = AuthService();
  bool isLoading = false;
  final UserService _userService = UserService();
  final _emailOtpService = EmailOtpService();

  Future<void> _handleSubmit() async {
    // Validate inputs first
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters long')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isLoginSelected) {
        // Handle Login
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          bool isEmailVerified = await _userService.isEmailVerified();
          bool isPanVerified = await _userService.isPanVerified();

          if (!isEmailVerified) {
            // Send verification email once
            String? userEmail = _userService.getCurrentUserEmail();
            if (userEmail != null) {
              await sendVerificationEmail(userEmail);
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const MobileVerificationScreen()),
            );
          } else if (!isPanVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const PanVerificationScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else {
        // Handle Sign Up
        if (_passwordController.text != _confirmPasswordController.text) {
          throw 'Passwords do not match';
        }

        // Create new user
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Send verification email once for new sign-ups
        String? userEmail = _userService.getCurrentUserEmail();
        if (userEmail != null && mounted) {
          await sendVerificationEmail(userEmail);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const MobileVerificationScreen()),
          );
        }
      }
    } catch (e) {
      // Handle specific Firebase errors with user-friendly messages
      String errorMessage = 'An error occurred';

      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'No user found with this email';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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

  Future<void> sendVerificationEmail(String? email) async {
    if (email == null) {
      throw 'No email address available';
    }

    bool success = await _emailOtpService.sendOtpEmail(recipientEmail: email);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send verification code')),
        );
      }
    }
  }

  // Future<void> sendVerificationEmail(String? email) async {
  //   bool success = await _emailOtpService.sendOtpEmail(recipientEmail: email);
  //
  //   if (success) {
  //     SnackBar(content: Text('OTP sent successfully'));
  //   } else {
  //     SnackBar(content: Text('Failed to send OTP'));
  //   }
  // }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordObsecured = !isPasswordObsecured;
    });
  }

  void toogleLoginSelected(bool isLogin) {
    setState(() {
      isLoginSelected = isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 50, bottom: 300),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    SizedBox(height: 15),
                    Text(
                      'Login or \nSignUp Today',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Join us today and make your voice \nheard effortlessly!',
                      style: TextStyle(color: Color(0xFF777777)),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F1F1),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  alignment: isLoginSelected
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  duration: Duration(milliseconds: 300),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 5),
                                    height: 40,
                                    width:
                                        MediaQuery.of(context).size.width / 2 -
                                            30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isLoginSelected = true;
                                        });
                                      },
                                      child: Center(
                                        child: Text(
                                          'Log in',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isLoginSelected
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isLoginSelected = false;
                                        });
                                      },
                                      child: Center(
                                        child: Text(
                                          'Sign up',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isLoginSelected
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoginSelected) ...[
                      BuildLoginField(
                        controller: _emailController,
                        hint: 'Email Address',
                        isPasswordField: false,
                        isObscured: false,
                      ),
                      BuildLoginField(
                        controller: _passwordController,
                        hint: 'Password',
                        isPasswordField: true,
                        isObscured: isPasswordObsecured,
                        toggleObscured: togglePasswordVisibility,
                      ),
                    ] else ...[
                      BuildLoginField(
                        controller: _emailController,
                        hint: 'Email Address',
                        isPasswordField: false,
                        isObscured: false,
                      ),
                      BuildLoginField(
                        controller: _passwordController,
                        hint: 'Password',
                        isPasswordField: true,
                        isObscured: isPasswordObsecured,
                        toggleObscured: togglePasswordVisibility,
                      ),
                      BuildLoginField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        isPasswordField: true,
                        isObscured: isPasswordObsecured,
                        toggleObscured: togglePasswordVisibility,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isLoginSelected ? 'Log in' : 'Sign up',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
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

class BuildLoginField extends StatelessWidget {
  const BuildLoginField({
    super.key,
    required this.controller,
    required this.hint,
    this.isPasswordField = false,
    this.isObscured = false,
    this.toggleObscured,
  });

  final TextEditingController controller;
  final String hint;
  final bool isPasswordField;
  final bool isObscured;
  final VoidCallback? toggleObscured;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFF1F1F1),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          child: Center(
            child: TextField(
              controller: controller,
              obscureText: isPasswordField && isObscured,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                border: InputBorder.none,
                suffixIcon: isPasswordField
                    ? IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: toggleObscured,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
