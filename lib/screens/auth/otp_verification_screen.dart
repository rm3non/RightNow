import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// OTP verification screen — enter 6-digit code
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _canResend = false;
  int _resendCountdown = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 30;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
        }
      });
      return _resendCountdown > 0;
    });
  }

  void _verify(String code) {
    if (code.length == 6) {
      context.read<AuthProvider>().verifyOTP(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Back button
                IconButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  icon: const Icon(Icons.arrow_back_ios),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 40),

                Text(
                  'Verify your number',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.phoneNumber ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
                ),

                const SizedBox(height: 40),

                // OTP Input
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  autoFocus: true,
                  cursorColor: AppTheme.primary,
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: AppTheme.surfaceLight,
                    inactiveFillColor: AppTheme.surfaceLight,
                    selectedFillColor: AppTheme.surfaceLight,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.surfaceLighter,
                    selectedColor: AppTheme.primaryLight,
                    fieldOuterPadding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  enableActiveFill: true,
                  onCompleted: _verify,
                  onChanged: (_) {},
                ),

                // Error
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Resend
                Center(
                  child: _canResend
                      ? TextButton(
                          onPressed: () {
                            context.read<AuthProvider>().resendOTP();
                            _startResendTimer();
                          },
                          child: const Text('Resend code'),
                        )
                      : Text(
                          'Resend in ${_resendCountdown}s',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                ),

                const Spacer(),

                // Verify button
                if (authProvider.state == AuthState.verifying)
                  const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
