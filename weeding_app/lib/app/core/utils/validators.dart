class Validators {
  /// Email obligatoire (connexion, inscription…).
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    return _emailFormat(value);
  }

  /// Email facultatif : accepté vide (invité sans adresse), mais formaté
  /// quand une adresse est saisie.
  static String? emailOptional(String? value) {
    if (value == null || value.isEmpty) return null;
    return _emailFormat(value);
  }

  static String? _emailFormat(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // optionnel
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''))) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    final num = int.tryParse(value);
    if (num == null || num <= 0) {
      return 'Doit être un nombre positif';
    }
    return null;
  }
}
