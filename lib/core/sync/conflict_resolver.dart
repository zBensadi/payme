abstract class ConflictResolver<T> {
  T resolve(T local, T remote);
}
