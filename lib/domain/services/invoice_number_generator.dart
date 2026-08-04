import '../../core/error/result.dart';
import '../repositories/invoice_repository.dart';

class InvoiceNumberGenerator {
  final InvoiceRepository _repository;

  InvoiceNumberGenerator(this._repository);

  Future<Result<int>> generateNext(String accountingYearId) async {
    final result = await _repository.getHighestInvoiceNumber(accountingYearId);
    
    return switch (result) {
      Success(value: final highestNumber) => Success(highestNumber + 1),
      Failure() => result,
    };
  }
}
