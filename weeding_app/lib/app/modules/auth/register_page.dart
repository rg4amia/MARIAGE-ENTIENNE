import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import 'auth_controller.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface,
              AppColors.tertiaryFixed,
            ],
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
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Get.back(),
                          ),
                        ),

                        // Icône
                        const Icon(
                          Icons.favorite,
                          size: 48,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(height: 16),

                        // Titre
                        Text(
                          'Créer un compte',
                          style: AppTextStyles.displayMdPrimary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejoignez l\'espace mariage',
                          style: AppTextStyles.bodyMdOnVariant,
                        ),
                        const SizedBox(height: 32),

                        // Nom complet
                        Text('Nom complet', style: AppTextStyles.labelMd),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: controller.fullNameController,
                          validator: (v) => Validators.required(v, 'Le nom'),
                          decoration: const InputDecoration(
                            hintText: 'Jean Dupont',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Téléphone
                        Text('Téléphone', style: AppTextStyles.labelMd),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: controller.phoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                          decoration: const InputDecoration(
                            hintText: '+225 07 00 00 00 00',
                          ),
                        ),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),

                        // Mot de passe
                        Text('Mot de passe', style: AppTextStyles.labelMd),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: controller.passwordController,
                          obscureText: true,
                          validator: Validators.password,
                          decoration: const InputDecoration(
                            hintText: '••••••••',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bouton Inscription
                        Obx(() => ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () {
                                      if (formKey.currentState!.validate()) {
                                        controller.register();
                                      }
                                    },
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    )
                                  : const Text('Créer mon compte'),
                            )),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Déjà un compte ? ',
                              style: AppTextStyles.bodyMdOnVariant,
                            ),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Text(
                                'Se connecter',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ),
    );
  }
}
