import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/wedding_rings_icon.dart';
import 'auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _formKey = GlobalKey<FormState>();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(AuthController controller) {
    if (controller.isLoading.value) return;
    if (_formKey.currentState!.validate()) {
      controller.register();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Mint green gradient header
          Container(
            height: 180,
            decoration: BoxDecoration(color: AppColors.primary),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ),

          // Form card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 70),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _ctrl,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: FadeTransition(
                    opacity: _ctrl,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.dark, width: 1.3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dark.withValues(alpha: 0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: WeddingRingsIcon(
                                    color: AppColors.onPrimary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Créer un compte',
                                  style: AppTextStyles.headlineMd,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  'Rejoignez l\'espace mariage',
                                  style: AppTextStyles.bodyMdOnVariant,
                                ),
                              ),
                              const SizedBox(height: 28),

                              _buildField(
                                label: 'Nom complet',
                                child: TextFormField(
                                  controller: controller.fullNameController,
                                  validator: (v) =>
                                      Validators.required(v, 'Le nom'),
                                  style: AppTextStyles.bodyLg,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.name],
                                  onFieldSubmitted: (_) =>
                                      _phoneFocus.requestFocus(),
                                  decoration: _inputDecoration(
                                    'Jean Dupont',
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildField(
                                label: 'Téléphone (optionnel)',
                                child: TextFormField(
                                  controller: controller.phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.phone,
                                  validator: Validators.phone,
                                  style: AppTextStyles.bodyLg,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  onFieldSubmitted: (_) =>
                                      _emailFocus.requestFocus(),
                                  decoration: _inputDecoration(
                                    '+225 07 00 00 00 00',
                                    Icons.phone_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildField(
                                label: 'Email',
                                child: TextFormField(
                                  controller: controller.emailController,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.email,
                                  style: AppTextStyles.bodyLg,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onFieldSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  decoration: _inputDecoration(
                                    'exemple@mail.com',
                                    Icons.mail_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildField(
                                label: 'Mot de passe',
                                child: _PasswordField(
                                  controller: controller.passwordController,
                                  focusNode: _passwordFocus,
                                  onFieldSubmitted: () => _submit(controller),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Register button
                              Obx(
                                () => SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : () => _submit(controller),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.dark,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AppColors.dark
                                          .withValues(alpha: 0.45),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: controller.isLoading.value
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Créer mon compte',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Center(
                                child: GestureDetector(
                                  onTap: () => Get.back(),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Déjà un compte ? ',
                                      style: AppTextStyles.bodyMd.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Se connecter',
                                          style: AppTextStyles.bodyMd.copyWith(
                                            color: AppColors.dark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return _registerInputDecoration(hint, icon: icon);
  }
}

InputDecoration _registerInputDecoration(
  String hint, {
  IconData? icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: icon == null
        ? null
        : Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

// ── Password field with visibility toggle ──
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onFieldSubmitted;

  const _PasswordField({
    required this.controller,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      validator: Validators.password,
      style: AppTextStyles.bodyLg,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
      decoration: _registerInputDecoration(
        '••••••••',
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
