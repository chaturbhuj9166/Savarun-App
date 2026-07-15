import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'data/auth_providers.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

enum _Step { enterPhone, enterOtp }

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.enterPhone;
  bool _busy = false;

  // Platform-specific handles between the two steps.
  ConfirmationResult? _webConfirmation; // web
  String? _verificationId; // mobile

  String get _phoneE164 {
    final raw = _phoneController.text.trim().replaceAll(' ', '');
    return raw.startsWith('+') ? raw : '+91$raw'; // default country: India
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _toast('Enter your phone number');
      return;
    }
    setState(() => _busy = true);
    final auth = ref.read(authServiceProvider);
    try {
      if (kIsWeb) {
        _webConfirmation = await auth.sendOtpWeb(_phoneE164);
        _goToOtp();
      } else {
        await auth.sendOtpMobile(
          _phoneE164,
          onCodeSent: (id) {
            _verificationId = id;
            _goToOtp();
          },
          onFailed: (e) => _toast(e.message ?? 'Could not send OTP'),
        );
      }
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Could not send OTP');
    } catch (e) {
      _toast('Could not send OTP: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goToOtp() {
    if (!mounted) return;
    setState(() => _step = _Step.enterOtp);
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      _toast('Enter the 6-digit code');
      return;
    }
    setState(() => _busy = true);
    final auth = ref.read(authServiceProvider);
    try {
      if (kIsWeb) {
        await auth.confirmOtpWeb(_webConfirmation!, code);
      } else {
        await auth.confirmOtpMobile(_verificationId!, code);
      }
      // Router redirect handles navigation to Home on success.
    } on FirebaseAuthException catch (e) {
      _toast(e.message ?? 'Invalid code');
    } catch (e) {
      _toast('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 6),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _step == _Step.enterPhone;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPhone ? 'Phone Login' : 'Verify OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == _Step.enterOtp) {
              setState(() => _step = _Step.enterPhone);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: isPhone ? _phoneStep() : _otpStep(),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _phoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Enter your phone number',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text("We'll send you a 6-digit verification code.",
            style: TextStyle(color: AppColors.inkMuted)),
        const SizedBox(height: 28),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
          decoration: const InputDecoration(
            hintText: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _busy ? null : _sendOtp, child: const Text('Send OTP')),
        // reCAPTCHA (web) renders here automatically when needed.
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Enter the code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Sent to $_phoneE164',
            style: const TextStyle(color: AppColors.inkMuted)),
        const SizedBox(height: 28),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: '••••••', counterText: ''),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _busy ? null : _verifyOtp, child: const Text('Verify & Continue')),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _sendOtp,
            child: const Text('Resend code'),
          ),
        ),
      ],
    );
  }
}
