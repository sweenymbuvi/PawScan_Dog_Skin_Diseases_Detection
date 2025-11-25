class LogInWithEmailAndPasswordFailure {
  final String message;

  const LogInWithEmailAndPasswordFailure([
    this.message = "An unknown error occurred.",
  ]);

  factory LogInWithEmailAndPasswordFailure.fromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return const LogInWithEmailAndPasswordFailure(
          'No user found for that email.',
        );
      case 'wrong-password':
        return const LogInWithEmailAndPasswordFailure(
          'Wrong password provided.',
        );
      case 'invalid-email':
        return const LogInWithEmailAndPasswordFailure(
          'The email address is invalid.',
        );
      default:
        return const LogInWithEmailAndPasswordFailure();
    }
  }
}
