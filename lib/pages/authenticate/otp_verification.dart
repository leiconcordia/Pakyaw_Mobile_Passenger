import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pakyaw/services/auth.dart';

class OtpVerification extends StatefulWidget {
  final String verificationID;
  final String phoneNum;

  const OtpVerification({
    super.key,
    required this.verificationID,
    required this.phoneNum,
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final AuthService _authService = AuthService(FirebaseAuth.instance);

  final List<String> otp = List.filled(6, '');
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool isLoading = false;

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Combine OTP digits into a single string
  String get finalOtp => otp.join('');

  /// Handle OTP input behavior
  void _onOtpChanged(String value, int index) {
    setState(() {
      otp[index] = value;
    });

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  /// Submit OTP to Firebase
  Future<void> _submitOTP(BuildContext context) async {
    if (otp.contains('')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationID,
        smsCode: finalOtp,
      );

      await _authService.signInWithCredentials(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification Successful!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  /// OTP Text Field Builder
  Widget _buildOtpField(int index) {
    return SizedBox(
      height: 60,
      width: 50,
      child: TextField(
        focusNode: _focusNodes[index],
        onChanged: (value) => _onOtpChanged(value, index),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Title
              Text(
                'Verify Your Number',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We sent a 6-digit code to\n${widget.phoneNum}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpField(index)),
              ),
              const SizedBox(height: 30),

              // Resend Code
              TextButton(
                onPressed: () {
                  // TODO: Implement resend logic
                },
                child: const Text(
                  'Didn\'t get the code? Resend',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(),

              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submitOTP(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Verify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
