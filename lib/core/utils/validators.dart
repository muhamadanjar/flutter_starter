import 'package:formz/formz.dart';

// Username Validator
enum UsernameValidationError { tooShort, invalidCharacters }

class Username extends FormzInput<String, UsernameValidationError> {
  const Username.pure() : super.pure('');
  const Username.dirty([super.value = '']) : super.dirty();

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_-]{3,}$');

  @override
  UsernameValidationError? validator(String value) {
    if (value.trim().length < 3) return UsernameValidationError.tooShort;
    if (!_usernameRegex.hasMatch(value)) return UsernameValidationError.invalidCharacters;
    return null;
  }

  bool get invalid => !isValid;
}

// Email Validator
enum EmailValidationError { invalid }

class Email extends FormzInput<String, EmailValidationError> {
  const Email.pure() : super.pure('');
  const Email.dirty([super.value = '']) : super.dirty();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
  );

  @override
  EmailValidationError? validator(String value) {
    return _emailRegex.hasMatch(value) ? null : EmailValidationError.invalid;
  }

  bool get invalid => !isValid;
}

// Password Validator
enum PasswordValidationError { tooShort, noUppercase, noLowercase, noDigit, noSpecialChar }

class Password extends FormzInput<String, PasswordValidationError> {
  const Password.pure() : super.pure('');
  const Password.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.length < 8) return PasswordValidationError.tooShort;
    if (!value.contains(RegExp(r'[A-Z]'))) return PasswordValidationError.noUppercase;
    if (!value.contains(RegExp(r'[a-z]'))) return PasswordValidationError.noLowercase;
    if (!value.contains(RegExp(r'[0-9]'))) return PasswordValidationError.noDigit;
    // if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return PasswordValidationError.noSpecialChar;
    return null;
  }

  bool get invalid => !isValid;
}

// Confirmed Password Validator
enum ConfirmedPasswordValidationError { mismatch }

class ConfirmedPassword extends FormzInput<String, ConfirmedPasswordValidationError> {
  final String password;

  const ConfirmedPassword.pure({this.password = ''}) : super.pure('');
  const ConfirmedPassword.dirty({required this.password, String value = ''}) : super.dirty(value);

  @override
  ConfirmedPasswordValidationError? validator(String value) {
    return password == value ? null : ConfirmedPasswordValidationError.mismatch;
  }

  bool get invalid => !isValid;
}

// Name Validator
enum NameValidationError { tooShort }

class Name extends FormzInput<String, NameValidationError> {
  const Name.pure() : super.pure('');
  const Name.dirty([super.value = '']) : super.dirty();

  @override
  NameValidationError? validator(String value) {
    return value.trim().length >= 2 ? null : NameValidationError.tooShort;
  }

  bool get invalid => !isValid;
}

// Helper to get error messages
class ValidatorMessages {
  ValidatorMessages._();

  static String usernameError(UsernameValidationError? error) {
    switch (error) {
      case UsernameValidationError.tooShort:
        return 'Username must be at least 3 characters';
      case UsernameValidationError.invalidCharacters:
        return 'Username can only contain letters, numbers, hyphens, and underscores';
      default:
        return '';
    }
  }

  static String emailError(EmailValidationError? error) {
    switch (error) {
      case EmailValidationError.invalid:
        return 'Please enter a valid email address';
      default:
        return '';
    }
  }

  static String passwordError(PasswordValidationError? error) {
    switch (error) {
      case PasswordValidationError.tooShort:
        return 'Password must be at least 8 characters';
      case PasswordValidationError.noUppercase:
        return 'Password must contain at least one uppercase letter';
      case PasswordValidationError.noLowercase:
        return 'Password must contain at least one lowercase letter';
      case PasswordValidationError.noDigit:
        return 'Password must contain at least one digit';
      case PasswordValidationError.noSpecialChar:
        return 'Password must contain at least one special character';
      default:
        return '';
    }
  }

  static String confirmedPasswordError(ConfirmedPasswordValidationError? error) {
    switch (error) {
      case ConfirmedPasswordValidationError.mismatch:
        return 'Passwords do not match';
      default:
        return '';
    }
  }

  static String nameError(NameValidationError? error) {
    switch (error) {
      case NameValidationError.tooShort:
        return 'Name must be at least 2 characters';
      default:
        return '';
    }
  }
}
