import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/constants/status_constants.dart';
import '../../repositories/auth_repository.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_main_screen.dart';
import '../provider/provider_dashboard_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool canSkip;
  final Widget? redirectAfterLogin;

  const LoginScreen({
    super.key,
    this.canSkip = true,
    this.redirectAfterLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> _login() async {
    final email = emailController.text.trim();
      final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email and password to continue.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.login(
        email: email,
        password: password,
      );

      final user = _authRepository.currentUser;

      if (user == null) {
        throw Exception('Login failed.');
      }

      await user.reload();

      final refreshedUser = _authRepository.currentUser;

      if (refreshedUser == null) {
        throw Exception('Login failed.');
      }

      if (!refreshedUser.emailVerified) {
        await _authRepository.logout();

        throw Exception(
          'Please verify your email address before logging in. Check your inbox for the verification link.',
        );
      }

      final userDoc = await _db
          .collection(FirestoreCollections.users)
          .doc(refreshedUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found in Firestore.');
      }

      await _db.collection(FirestoreCollections.users).doc(refreshedUser.uid).update({
        'isEmailVerified': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final data = userDoc.data()!;
      final role = data['role'];
      final isActive = data['isActive'] ?? true;
      final isBlocked = data['isBlocked'] ?? false;

      if (!isActive || isBlocked) {
        await _authRepository.logout();
        throw Exception('Your account is inactive or blocked.');
      }

      if (!mounted) return;

      if (role == UserRoles.customer) {
        if (widget.redirectAfterLogin != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => widget.redirectAfterLogin!),
            (_) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
            (_) => false,
          );
        }
      } else if (role == UserRoles.provider) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
          (_) => false,
        );
      } else if (role == UserRoles.admin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (_) => false,
        );
      } else {
        throw Exception('Invalid user role.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
    );
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter your email address first so we can send a reset link.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showMessage(
        'We sent a password reset link to your email. Please check your inbox.',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) return;

    final cleanMessage = _friendlyErrorMessage(message);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Message',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.84,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFFF1EB)
                          : const Color(0xFFEFFAF3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError
                          ? Icons.info_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isError
                          ? const Color(0xFFFF6333)
                          : const Color(0xFF16A34A),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isError ? 'Check your details' : 'Success',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2B211D),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cleanMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isError
                            ? const Color(0xFFFF6333)
                            : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Okay',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  String _friendlyErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('verify your email')) {
      return 'Please verify your email address before logging in. Check your inbox for the verification link.';
    }

    if (lowerMessage.contains('missing-email')) {
      return 'Enter your email address first.';
    }

    if (lowerMessage.contains('invalid-email') ||
        lowerMessage.contains('badly formatted')) {
      return 'Please enter a valid email address.';
    }

    if (lowerMessage.contains('user-not-found')) {
      return 'No account was found with this email address.';
    }

    if (lowerMessage.contains('wrong-password') ||
        lowerMessage.contains('invalid-credential')) {
      return 'The email or password you entered is incorrect.';
    }

    if (lowerMessage.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in instead.';
    }

    if (lowerMessage.contains('weak-password')) {
      return 'Your password is too weak. Please use a stronger password.';
    }

    if (lowerMessage.contains('network-request-failed')) {
      return 'Please check your internet connection and try again.';
    }

    if (lowerMessage.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (lowerMessage.contains('google sign-in was cancelled') ||
        lowerMessage.contains('canceled')) {
      return 'Google sign-in was cancelled.';
    }

    if (lowerMessage.contains('account is inactive') ||
        lowerMessage.contains('blocked')) {
      return 'Your account is currently unavailable. Please contact support.';
    }

    return message
        .replaceAll('Exception: ', '')
        .replaceAll(RegExp(r'\[firebase_auth\/[^\]]+\]\s*'), '');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  Row(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6333),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Image.asset(
                          'assets/images/mobile_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Feasta',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 55),
                  const Text(
                    'Log in or sign up',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore verified caterers and event services. Log in when you’re ready to book.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'your.email@example.com',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Password',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: primary,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _loginWithGoogle,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  if (widget.canSkip) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _continueAsGuest,
                        child: const Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (widget.canSkip)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: _continueAsGuest,
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);

    try {
      await _authRepository.signInWithGoogleAsCustomer();

      final user = _authRepository.currentUser;

      if (user == null) {
        throw Exception('Google sign-in failed.');
      }

      final userDoc = await _db
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found in Firestore.');
      }

      final data = userDoc.data()!;
      final role = data['role'];
      final isActive = data['isActive'] ?? true;
      final isBlocked = data['isBlocked'] ?? false;

      if (!isActive || isBlocked) {
        await _authRepository.logout();
        throw Exception('Your account is inactive or blocked.');
      }

      if (!mounted) return;

      if (role == UserRoles.customer) {
        if (widget.redirectAfterLogin != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => widget.redirectAfterLogin!),
            (_) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
            (_) => false,
          );
        }
      } else {
        await _authRepository.logout();
        throw Exception(
          'Google sign-in is only available for customer accounts.',
        );
      }
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showMessage('Google sign-in was cancelled.');
      } else {
        _showMessage('Google sign-in failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong while signing in. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}