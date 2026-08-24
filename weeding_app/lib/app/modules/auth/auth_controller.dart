import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/profile.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final Rx<User?> user = Rx<User?>(null);
  final Rx<Profile?> profile = Rx<Profile?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void _initializeAuth() {
    user.value = _authRepository.currentUser;

    _authRepository.authStateChanges.listen((data) {
      final session = data.session;
      final event = data.event;

      user.value = session?.user;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        profile.value = null;
      }
    });

    if (user.value != null) {
      _loadProfile();
    }

    isInitialized.value = true;
  }

  Future<void> _loadProfile() async {
    try {
      profile.value = await _authRepository.getProfile();
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    }
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir tous les champs',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      await _authRepository.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      Get.offAllNamed(AppRoutes.home);
      _clearControllers();
    } on AuthException catch (e) {
      Get.snackbar(
        'Erreur de connexion',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur inattendue est survenue',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir tous les champs obligatoires',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      await _authRepository.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.isNotEmpty ? phoneController.text.trim() : null,
      );

      Get.offAllNamed(AppRoutes.home);
      _clearControllers();
    } on AuthException catch (e) {
      Get.snackbar(
        'Erreur d\'inscription',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur inattendue est survenue',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    fullNameController.clear();
    phoneController.clear();
  }

  bool get isLoggedIn => user.value != null;
}
