import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/repositories/accounting_year_repository.dart';
import 'package:payme/presentation/features/accounting_years/screens/accounting_years_screen.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

class FakeAccountingYearRepository implements AccountingYearRepository {
  List<AccountingYear> years = [];

  @override
  Future<Result<List<AccountingYear>>> getAll() async {
    return Success(years.toList());
  }

  @override
  Future<Result<AccountingYear?>> getActive() async {
    try {
      return Success(years.firstWhere((y) => y.isActive));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<AccountingYear>> create(String name) async {
    final year = AccountingYear(
      id: name,
      name: name,
      isActive: years.isEmpty,
      createdAt: DateTime.now(),
    );
    years.add(year);
    return Success(year);
  }

  @override
  Future<Result<void>> rename(String id, String newName) async {
    final index = years.indexWhere((y) => y.id == id);
    if (index >= 0) {
      years[index] = years[index].copyWith(name: newName);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> setActive(String id) async {
    years = years.map((y) {
      return y.copyWith(isActive: y.id == id);
    }).toList();
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    years.removeWhere((y) => y.id == id);
    return const Success(null);
  }
}

void main() {
  testWidgets('AccountingYearsScreen displays empty state when no years', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: AccountingYearsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('No accounting years found'), findsOneWidget);
  });

  testWidgets('AccountingYearsScreen displays list of years', (WidgetTester tester) async {
    final fakeRepo = FakeAccountingYearRepository();
    await fakeRepo.create('2025');
    await fakeRepo.create('2026');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: AccountingYearsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });
}
