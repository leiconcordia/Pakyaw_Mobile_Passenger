import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/authenticate/otp_verification.dart';
import 'package:pakyaw/providers/auth_provider.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String mobileNo = '';
  String error = '';

  /// Handles Firebase phone authentication
  Future<void> _submitPhoneNumber(BuildContext context) async {
    setState(() => isLoading = true);

    String phoneNumber = '+63${mobileNo.trim()}';
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            isLoading = false;
            error = e.message ?? 'Verification failed. Try again.';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerification(
                verificationID: verificationId,
                phoneNum: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Enter your mobile number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We will send you a verification code.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Phone Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Text(
                            '+63',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '10-digit mobile number',
                                hintStyle: TextStyle(color: Colors.black38),
                              ),
                              style: const TextStyle(fontSize: 18),
                              onChanged: (val) => setState(() => mobileNo = val),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a mobile number';
                                } else if (value.length != 10) {
                                  return 'Must be 10 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                          const Icon(Icons.phone_android, color: Colors.black54),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Error message
                    if (error.isNotEmpty)
                      Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),

                    const SizedBox(height: 20),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            _submitPhoneNumber(context);
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 30),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black26, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  icon: Image.asset(
                    'assets/Google.png',
                    width: 28,
                    height: 28,
                  ),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () async {
                    setState(() => isLoading = true);
                    await authService.signInWithGoogle();
                    setState(() => isLoading = false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
