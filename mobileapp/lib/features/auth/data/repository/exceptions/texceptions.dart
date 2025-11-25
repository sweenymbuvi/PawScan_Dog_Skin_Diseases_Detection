class TExceptions implements Exception {
  final String message;

  const TExceptions([this.message = 'An unknown exception occurred']);

  factory TExceptions.fromCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const TExceptions('Email already exists');
      case 'invalid-email':
        return const TExceptions('Email is invalid');
      case 'weak-password':
        return const TExceptions('Enter a stronger password');
      case 'user-disabled':
        return const TExceptions(
          'This user has been disabled. Please contact support for help',
        );
      default:
        return const TExceptions();
    }
  }
}
