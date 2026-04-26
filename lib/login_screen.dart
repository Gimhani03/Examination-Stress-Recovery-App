import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'homepage.dart';
import 'services/auth_service.dart';
import 'mood_flow_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _showError('Login failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMoodFlowBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kMoodMint,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: moodFlowNeoShadows(),
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    size: 40,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log in to continue your journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kMoodCardCreamA, kMoodCardCreamB],
                    ),
                    borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: moodFlowNeoShadows(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthNeoTextField(
                        hintText: 'Email address',
                        controller: _emailController,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _AuthNeoTextField(
                        hintText: 'Password',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscure,
                        suffixIcon: _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        onSuffixTap: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: kMoodFlowTealAccent,
                                ),
                              ),
                            )
                          : _NeoAuthButton(
                              label: 'Log in',
                              onTap: _handleLogin,
                            ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.5),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: kMoodFlowTealAccent,
                          decoration: TextDecoration.underline,
                          decorationColor: kMoodFlowTealAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets (used by both login & signup) ──────────────────────────

class _AuthNeoTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;

  const _AuthNeoTextField({
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.38),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.black.withValues(alpha: 0.45), size: 22)
            : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon,
                    color: Colors.black.withValues(alpha: 0.4), size: 22),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kMoodFlowTealAccent, width: 2),
        ),
      ),
    );
  }
}

class _NeoAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NeoAuthButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const bg = kMoodMint;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
