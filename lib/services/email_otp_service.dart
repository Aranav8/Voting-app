import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:random_string/random_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailOtpService {
  final String _senderEmail = 'aranavk08@gmail.com';
  final String _appPassword = 'ivmt ehux mhxr jvhv';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateOTP() {
    return randomNumeric(6);
  }

  Future<bool> sendOtpEmail({required String? recipientEmail}) async {
    if (recipientEmail == null) return false;

    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Delete any existing OTP document for this user
      await _firestore.collection('otps').doc(userId).delete();

      // Generate and save new OTP
      final String otp = _generateOTP();
      await _firestore.collection('otps').doc(userId).set({
        'otp': otp,
        'email': recipientEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
        'attempts': 0
      });

      final smtpServer = gmail(_senderEmail, _appPassword);
      final message = Message()
        ..from = Address(_senderEmail, 'DigiVote')
        ..recipients.add(recipientEmail)
        ..subject = 'Your Verification Code'
        ..html = '''
          <h1>Email Verification</h1>
          <p>Hello,</p>
          <p>Your verification code is: <strong>$otp</strong></p>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
          <br>
          <p>Best regards,</p>
          <p>DigiVote Team</p>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String enteredOtp) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Get the OTP document
      DocumentSnapshot otpDoc =
          await _firestore.collection('otps').doc(userId).get();

      if (!otpDoc.exists) {
        print('No OTP found for verification');
        return false;
      }

      Map<String, dynamic> otpData = otpDoc.data() as Map<String, dynamic>;

      // Check if already verified
      if (otpData['verified'] == true) {
        print('OTP already verified');
        return true;
      }

      // Check expiration (10 minutes)
      Timestamp createdAt = otpData['createdAt'] as Timestamp;
      DateTime creationTime = createdAt.toDate();
      if (DateTime.now().difference(creationTime).inMinutes > 10) {
        print('OTP expired');
        return false;
      }

      // Update attempts
      int attempts = (otpData['attempts'] ?? 0) + 1;
      await _firestore
          .collection('otps')
          .doc(userId)
          .update({'attempts': attempts});

      // Max attempts check (5 attempts)
      if (attempts > 5) {
        print('Too many attempts');
        return false;
      }

      // Debug prints
      print('Entered OTP: $enteredOtp');
      print('Stored OTP: ${otpData['otp']}');
      print('Creation Time: $creationTime');
      print('Current Time: ${DateTime.now()}');

      // Verify OTP
      if (otpData['otp'] == enteredOtp) {
        // Update verification status in both collections
        await Future.wait([
          _firestore.collection('otps').doc(userId).update(
              {'verified': true, 'verifiedAt': FieldValue.serverTimestamp()}),
          _firestore
              .collection('users')
              .doc(userId)
              .update({'isEmailVerified': true})
        ]);

        print('OTP verified successfully');
        return true;
      }

      print('OTP verification failed - incorrect code');
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }
}
