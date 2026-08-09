import 'conflict_resolver.dart';
import '../../domain/entities/accounting_year.dart';

class AccountingYearConflictResolver implements ConflictResolver<AccountingYear> {
  @override
  AccountingYear resolve(AccountingYear local, AccountingYear remote) {
    // If one is active and the other is not, the one with the latest updatedAt wins the active status
    if (local.isActive != remote.isActive) {
      if (remote.updatedAt.compareTo(local.updatedAt) > 0) {
        return remote;
      } else {
        // Local is newer or same time, but local is dirty (since it's in conflict resolution)
        // so we favor local
        return local;
      }
    }

    // Default Last-Write-Wins based on updatedAt
    if (remote.updatedAt.compareTo(local.updatedAt) > 0) {
      return remote;
    }
    return local;
  }
}
