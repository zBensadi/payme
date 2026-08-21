import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../domain/entities/business_settings.dart';
import '../../datasources/file/logo_file_datasource.dart';

class SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final LogoFileDataSource _logoFileDataSource;

  SettingsRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required this._logoFileDataSource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<void> pushSettings(String businessId, BusinessSettings settings) async {
    final map = {
      'businessId': businessId,
      'businessName': settings.businessName,
      'address': settings.address,
      'phone': settings.phone,
      'email': settings.email,
      'logoPath': settings.logoPath,
      'logoSha256': settings.logoSha256,
      'currencyCode': settings.currencyCode,
      'languageCode': settings.languageCode,
      'defaultDocumentTitle': settings.defaultDocumentTitle,
      'defaultDocumentLayout': settings.defaultDocumentLayout,
      'currencyLockedAt': settings.currencyLockedAt?.toUtc().toIso8601String(),
      'rc': settings.rc,
      'nif': settings.nif,
      'nis': settings.nis,
      'art': settings.art,
      'updatedAt': settings.updatedAt?.toUtc().toIso8601String(),
    };

    // Remove null values so we don't overwrite with nulls unnecessarily during merge
    map.removeWhere((key, value) => value == null);

    bool newLogoUploaded = false;
    Reference? newLogoRef;

    // 0. Fetch old settings to know the old logo for potential deletion
    String? oldLogoPath;
    try {
      final doc = await _firestore.collection('businesses').doc(businessId).collection('settings').doc('main').get();
      if (doc.exists && doc.data() != null) {
        oldLogoPath = doc.data()!['logoPath'] as String?;
      }
    } catch (e) {
      debugPrint('[LOGO-OLD-PATH] Failed to fetch old settings from Firestore: $e');
    }
    debugPrint(
      '[LOGO-OLD-PATH] '
      'businessId=$businessId '
      'firestoreOldLogoPath=$oldLogoPath '
      'newLogoPath=${settings.logoPath}',
    );

    // 1. Upload new logo if it exists and differs from old
    if (settings.logoPath != null && settings.logoPath != oldLogoPath) {
      try {
        final absPath = await _logoFileDataSource.getAbsolutePath(settings.logoPath!);
        final file = File(absPath);
        if (await file.exists()) {
          final fileName = settings.logoPath!;
          newLogoRef = _storage.ref().child('businesses').child(businessId).child('logos').child(fileName);
          
          try {
            await newLogoRef.getMetadata();
          } catch (e) {
            // Metadata not found, so upload it
            await newLogoRef.putFile(
              file,
              SettableMetadata(
                contentType: fileName.endsWith('.png') ? 'image/png' : 'image/jpeg',
              ),
            );
            newLogoUploaded = true;
          }
        }
      } catch (e) {
        debugPrint('Error uploading logo: $e');
        // Do not update Firestore with the new path if upload fails, to prevent orphaned paths
        map.remove('logoPath');
        map.remove('logoSha256');
      }
    }

    try {
      final batch = _firestore.batch();

      // 2. Update tenant-scoped settings document
      final settingsRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('settings')
          .doc('main');
      batch.set(settingsRef, map, SetOptions(merge: true));

      // 3. Update businesses document atomically
      if (settings.businessName != null) {
        final businessRef = _firestore.collection('businesses').doc(businessId);
        batch.update(businessRef, {'name': settings.businessName});
      }

      await batch.commit();
    } catch (e) {
      // 4. Firestore failed. Clean up newly uploaded logo if any.
      if (newLogoUploaded && newLogoRef != null) {
        try {
          await newLogoRef.delete();
        } catch (cleanupError) {
          debugPrint('Failed to clean up newly uploaded logo after Firestore error: $cleanupError');
        }
      }
      rethrow;
    }

    // 5. Firestore succeeded. Delete old logo if it changed.
    if (oldLogoPath != null && oldLogoPath != settings.logoPath) {
      final fullStoragePath = 'businesses/$businessId/logos/$oldLogoPath';
      debugPrint(
        '[LOGO-CLEANUP-ATTEMPT] '
        'businessId=$businessId '
        'oldLogoPath=$oldLogoPath '
        'fullStoragePath=$fullStoragePath',
      );
      try {
        final oldRef = _storage.ref().child('businesses').child(businessId).child('logos').child(oldLogoPath);
        await oldRef.delete();
        debugPrint('[LOGO-CLEANUP-SUCCESS] fullStoragePath=$fullStoragePath');
      } catch (e, stack) {
        debugPrint(
          '[LOGO-CLEANUP-ERROR] '
          'businessId=$businessId '
          'oldLogoPath=$oldLogoPath '
          'newLogoPath=${settings.logoPath} '
          'fullStoragePath=$fullStoragePath '
          'error=$e\n$stack',
        );
      }
    } else {
      debugPrint(
        '[LOGO-CLEANUP-SKIP] '
        'condition not met: '
        'oldLogoPath=$oldLogoPath '
        'newLogoPath=${settings.logoPath} '
        '(null or same path — no delete attempted)',
      );
    }
  }

  Future<BusinessSettings?> pullSettings(String businessId) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('main')
        .get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate().toUtc();
      if (val is String) return DateTime.tryParse(val)?.toUtc();
      return null;
    }
    
    final logoPath = data['logoPath'];
    if (logoPath != null) {
      try {
        final absPath = await _logoFileDataSource.getAbsolutePath(logoPath);
        final file = File(absPath);
        if (!await file.exists()) {
          final ref = _storage.ref().child('businesses').child(businessId).child('logos').child(logoPath);
          await ref.writeToFile(file);
        }
      } catch (e) {
        debugPrint('Error downloading logo: $e');
      }
    }

    return BusinessSettings(
      id: 1,
      businessName: data['businessName'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      logoPath: logoPath,
      currencyCode: data['currencyCode'] ?? 'DZD',
      languageCode: data['languageCode'] ?? 'en',
      defaultDocumentTitle: data['defaultDocumentTitle'] ?? 'Invoice',
      defaultDocumentLayout: data['defaultDocumentLayout'] ?? 'standard',
      currencyLockedAt: parseDate(data['currencyLockedAt']),
      rc: data['rc'],
      nif: data['nif'],
      nis: data['nis'],
      art: data['art'],
      updatedAt: parseDate(data['updatedAt']),
      isDirty: false,
      remoteId: doc.id,
      syncedAt: parseDate(data['updatedAt']),
    );
  }
}
