import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';
import 'mood_flow_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ForgotPasswordStep { email, verifyCode, newPassword }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _step = _ForgotPasswordStep.verifyCode);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyCode() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showError('Enter the code from your email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPasswordRecoveryOtp(email: email, otp: otp);
      if (!mounted) return;
      setState(() => _step = _ForgotPasswordStep.newPassword);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSetPassword() async {
    final pass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.completePasswordRecovery(pass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Password updated. Log in with your new password.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleBack() {
    switch (_step) {
      case _ForgotPasswordStep.email:
        _goBackToLogin();
      case _ForgotPasswordStep.verifyCode:
        setState(() {
          _step = _ForgotPasswordStep.email;
          _otpController.clear();
        });
      case _ForgotPasswordStep.newPassword:
        _authService.signOut();
        setState(() {
          _step = _ForgotPasswordStep.verifyCode;
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
    }
  }

  String get _backLabel {
    switch (_step) {
      case _ForgotPasswordStep.email:
        return 'Back to log in';
      case _ForgotPasswordStep.verifyCode:
        return 'Change email';
      case _ForgotPasswordStep.newPassword:
        return 'Back to code';
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

  void _goBackToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();

    return Scaffold(
      backgroundColor: kMoodFlowBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 22, 0),
                  child: _AuthBackLink(
                    label: _backLabel,
                    onTap: _handleBack,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 72),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ForgotPasswordCard(
                            step: _step,
                            email: email,
                            isLoading: _isLoading,
                            emailController: _emailController,
                            otpController: _otpController,
                            newPasswordController: _newPasswordController,
                            confirmPasswordController: _confirmPasswordController,
                            obscureNew: _obscureNew,
                            obscureConfirm: _obscureConfirm,
                            onToggleNew: () => setState(() => _obscureNew = !_obscureNew),
                            onToggleConfirm: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                            onSendCode: _handleSendCode,
                            onVerifyCode: _handleVerifyCode,
                            onSetPassword: _handleSetPassword,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Back navigation ─────────────────────────────────────────────────────

class _AuthBackLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AuthBackLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: Colors.black.withValues(alpha: 0.55),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.55),
            letterSpacing: -0.1,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ─── Main card (hero + form in one block) ────────────────────────────────

class _ForgotPasswordCard extends StatelessWidget {
  final _ForgotPasswordStep step;
  final String email;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController otpController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureNew;
  final bool obscureConfirm;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSendCode;
  final VoidCallback onVerifyCode;
  final VoidCallback onSetPassword;

  const _ForgotPasswordCard({
    required this.step,
    required this.email,
    required this.isLoading,
    required this.emailController,
    required this.otpController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onSetPassword,
  });

  int get _stepNumber {
    switch (step) {
      case _ForgotPasswordStep.email:
        return 1;
      case _ForgotPasswordStep.verifyCode:
        return 2;
      case _ForgotPasswordStep.newPassword:
        return 3;
    }
  }

  String get _title {
    switch (step) {
      case _ForgotPasswordStep.email:
        return 'Reset password';
      case _ForgotPasswordStep.verifyCode:
        return 'Enter your code';
      case _ForgotPasswordStep.newPassword:
        return 'New password';
    }
  }

  String get _subtitle {
    switch (step) {
      case _ForgotPasswordStep.email:
        return 'Enter the email for your account and we\'ll send you a reset code.';
      case _ForgotPasswordStep.verifyCode:
        return 'We sent a code to ${email.isEmpty ? 'your email' : email}. Enter it below to continue.';
      case _ForgotPasswordStep.newPassword:
        return 'Choose a new password for your account.';
    }
  }

  IconData get _icon {
    switch (step) {
      case _ForgotPasswordStep.email:
        return Icons.lock_reset_rounded;
      case _ForgotPasswordStep.verifyCode:
        return Icons.pin_rounded;
      case _ForgotPasswordStep.newPassword:
        return Icons.lock_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kMoodMint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(_icon, size: 26, color: Colors.black87),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step $_stepNumber of 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kMoodFlowTealAccent,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.42),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          switch (step) {
            _ForgotPasswordStep.email => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ForgotEmailField(controller: emailController),
                  const SizedBox(height: 18),
                  isLoading
                      ? const _ForgotLoadingIndicator()
                      : _NeoAuthButton(label: 'Send code', onTap: onSendCode),
                ],
              ),
            _ForgotPasswordStep.verifyCode => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ForgotOtpField(controller: otpController),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : onSendCode,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Resend code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isLoading
                              ? Colors.black.withValues(alpha: 0.25)
                              : kMoodFlowTealAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  isLoading
                      ? const _ForgotLoadingIndicator()
                      : _NeoAuthButton(label: 'Verify code', onTap: onVerifyCode),
                ],
              ),
            _ForgotPasswordStep.newPassword => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ForgotPasswordField(
                    controller: newPasswordController,
                    hintText: 'New password',
                    obscureText: obscureNew,
                    onToggleObscure: onToggleNew,
                  ),
                  const SizedBox(height: 12),
                  _ForgotPasswordField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm new password',
                    obscureText: obscureConfirm,
                    onToggleObscure: onToggleConfirm,
                  ),
                  const SizedBox(height: 18),
                  isLoading
                      ? const _ForgotLoadingIndicator()
                      : _NeoAuthButton(label: 'Update password', onTap: onSetPassword),
                ],
              ),
          },
        ],
      ),
    );
  }
}

class _ForgotLoadingIndicator extends StatelessWidget {
  const _ForgotLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: kMoodFlowTealAccent,
        ),
      ),
    );
  }
}

// ─── Fields (neo style, matches login) ───────────────────────────────────

class _ForgotEmailField extends StatelessWidget {
  final TextEditingController controller;

  const _ForgotEmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: 'Email address',
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.38),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          Icons.mail_outline_rounded,
          color: Colors.black.withValues(alpha: 0.45),
          size: 22,
        ),
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

class _ForgotOtpField extends StatelessWidget {
  final TextEditingController controller;

  const _ForgotOtpField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      maxLength: 12,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Code from email',
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.38),
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          Icons.password_rounded,
          color: Colors.black.withValues(alpha: 0.45),
          size: 22,
        ),
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

class _ForgotPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggleObscure;

  const _ForgotPasswordField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: Colors.black.withValues(alpha: 0.45),
          size: 22,
        ),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
