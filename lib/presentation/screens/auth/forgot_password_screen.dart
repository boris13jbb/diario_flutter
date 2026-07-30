import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/form_validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/fluent_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _autovalidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() => _autovalidate = true);
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authViewModelProvider.notifier).resetPassword(
          _emailController.text.trim(),
        );

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    if (_emailSent) {
      return AuthScaffold(
        showBackButton: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 64, color: FluentColors.success),
            const SizedBox(height: FluentSpacing.lg),
            Text(
              'Correo enviado',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FluentSpacing.sm),
            Text(
              'Revisa tu bandeja de entrada para restablecer la contraseña.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FluentSpacing.xl),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Volver al inicio de sesión'),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      showBackButton: true,
      title: 'Recuperar contraseña',
      subtitle:
          'Te enviaremos un enlace para restablecer el acceso a tu cuenta',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _handleReset(),
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'tu@correo.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: FormValidators.email,
            ),
            const SizedBox(height: FluentSpacing.xl),
            if (authState.error != null) ...[
              AuthErrorBanner(message: authState.error!),
              const SizedBox(height: FluentSpacing.lg),
            ],
            FilledButton(
              onPressed: authState.isLoading ? null : _handleReset,
              child: authState.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
  }
}
