abstract class ConflictResolver<T> {
  T resolve(T local, T remote);
}

/// A stub conflict resolver until a robust policy is implemented.
/// Currently defaults to Last-Write-Wins (or local in this stub).
class DefaultConflictResolver<T> implements ConflictResolver<T> {
  @override
  T resolve(T local, T remote) {
    // Stub implementation: local wins
    return local;
  }
}
