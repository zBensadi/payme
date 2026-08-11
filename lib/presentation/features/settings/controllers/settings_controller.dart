import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/entities/business_settings.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../providers/repository_providers.dart';
import '../../../utils/riverpod_invalidation_helper.dart';

final settingsControllerProvider = AsyncNotifierProvider<SettingsController, BusinessSettings>(SettingsController.new);

class SettingsController extends AsyncNotifier<BusinessSettings> {
  late SettingsRepository _repository;

  @override
  Future<BusinessSettings> build() async {
    _repository = ref.watch(settingsRepositoryProvider);
    ref.invalidateOnRepositoryChange(_repository);
    return await _fetchSettings();
  }

  Future<BusinessSettings> _fetchSettings() async {
    final result = await _repository.getSettings();
    if (result is Success<BusinessSettings>) {
      return result.value;
    } else {
      throw Exception((result as Failure).failure.message);
    }
  }

  Future<void> updateSettings({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? currencyCode,
    String? languageCode,
    String? defaultDocumentTitle,
    String? defaultDocumentLayout,
    String? rc,
    String? nif,
    String? nis,
    String? art,
    String? newLogoSourcePath,
  }) async {
    state = const AsyncLoading();
    
    final currentSettings = await _fetchSettings();
    final updated = currentSettings.copyWith(
      businessName: businessName,
      address: address,
      phone: phone,
      email: email,
      currencyCode: currencyCode,
      languageCode: languageCode,
      defaultDocumentTitle: defaultDocumentTitle,
      defaultDocumentLayout: defaultDocumentLayout,
      rc: rc,
      nif: nif,
      nis: nis,
      art: art,
    );

    final result = await _repository.updateSettings(
      updated,
      newLogoSourcePath: newLogoSourcePath,
    );

    if (result is Success<BusinessSettings>) {
      state = AsyncData(result.value);
    } else {
      state = AsyncError((result as Failure).failure.message, StackTrace.current);
    }
  }
}

