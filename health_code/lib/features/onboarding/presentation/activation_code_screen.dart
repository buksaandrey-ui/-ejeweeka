// lib/features/onboarding/presentation/activation_code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_code/core/router/route_names.dart';
import 'package:health_code/core/theme/app_theme.dart';
import 'package:health_code/features/onboarding/providers/profile_provider.dart';
import 'package:health_code/core/network/api_client.dart';

class ActivationCodeScreen extends ConsumerStatefulWidget {
  const ActivationCodeScreen({super.key});

  @override
  ConsumerState<ActivationCodeScreen> createState() => _ActivationCodeScreenState();
}

class _ActivationCodeScreenState extends ConsumerState<ActivationCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activateCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length < 6) {
      setState(() => _errorMessage = 'Введите корректный 6-значный код');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance.post(
        '/api/v1/subscription/activate-code', 
        data: {'code': code}
      );
      
      final tier = response.data['tier'] as String? ?? 'gold';

      // Save status to profile
      await ref.read(profileNotifierProvider.notifier).saveFields({
        'subscription_status': tier,
        'trial_start': DateTime.now().toIso8601String(),
        'activation_code_used': code,
      });

      if (mounted) {
        context.go(Routes.o175Disclaimer);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Неверный код активации или он уже использован';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.key_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Код активации',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Введите 6-значный код, полученный после оформления плана на сайте ejeweeka.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'XXX-XXX',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onChanged: (val) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _activateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Активировать Статус Gold',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
