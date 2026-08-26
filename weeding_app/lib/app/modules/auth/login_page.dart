import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import 'auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.tertiaryFixed],
            stops: [0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: AppColors.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Icône
                      const Icon(
                        Icons.favorite,
                        size: 48,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(height: 16),

                      // Titre
                      Text('Bienvenue', style: AppTextStyles.displayMdPrimary),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous pour accéder\nà votre espace mariage',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMdOnVariant,
                      ),
                      const SizedBox(height: 32),

                      // Form
                      Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email
                            Text('Email', style: AppTextStyles.labelMd),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: controller.emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              decoration: const InputDecoration(
                                hintText: 'exemple@mail.com',
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Mot de passe
                            Text('Mot de passe', style: AppTextStyles.labelMd),
                            const SizedBox(height: 4),
                            _PasswordField(
                              controller: controller.passwordController,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Get.snackbar(
                                    'Info',
                                    'Fonctionnalité à venir',
                                  );
                                },
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bouton Connexion
                            Obx(
                              () => ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.login,
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.onPrimaryContainer,
                                        ),
                                      )
                                    : const Text('Se connecter'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const _PasswordField({required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: Validators.password,
      decoration: InputDecoration(
        hintText: '••••••••',
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
