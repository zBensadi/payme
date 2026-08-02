sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class FileSystemFailure extends AppFailure {
  const FileSystemFailure(super.message);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}
