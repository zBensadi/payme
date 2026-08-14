import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:payme/data/datasources/remote/client_remote_datasource.dart';

import 'client_visibility_serialization_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  WriteBatch,
  DocumentReference,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('ClientRemoteDataSource Serialization', () {
    late MockFirebaseFirestore mockFirestore;
    late MockWriteBatch mockBatch;
    late ClientRemoteDataSource dataSource;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockBatch = MockWriteBatch();
      when(mockFirestore.batch()).thenReturn(mockBatch);
      dataSource = ClientRemoteDataSource(firestore: mockFirestore);
    });

    test('pullClients reads visibilityType correctly', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockCollection = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('businesses')).thenReturn(mockCollection);
      when(mockCollection.doc('bus_1')).thenReturn(mockDoc);
      when(mockDoc.collection('clients')).thenReturn(mockCollection);

      when(mockCollection.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDocSnapshot]);

      when(mockDocSnapshot.id).thenReturn('client_1');
      when(mockDocSnapshot.data()).thenReturn({
        'id': 'client_1',
        'name': 'Test Client',
        'visibilityType': 'assigned',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      });

      final clients = await dataSource.pullClients('bus_1', null);
      
      expect(clients.length, 1);
      expect(clients.first.visibilityType, 'assigned');
    });

    test('pullClients defaults visibilityType to everyone if missing', () async {
      final mockCollection = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('businesses')).thenReturn(mockCollection);
      when(mockCollection.doc('bus_1')).thenReturn(mockDoc);
      when(mockDoc.collection('clients')).thenReturn(mockCollection);

      when(mockCollection.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDocSnapshot]);

      when(mockDocSnapshot.id).thenReturn('client_1');
      when(mockDocSnapshot.data()).thenReturn({
        'id': 'client_1',
        'name': 'Test Client',
        // visibilityType missing
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      });

      final clients = await dataSource.pullClients('bus_1', null);
      
      expect(clients.length, 1);
      expect(clients.first.visibilityType, 'everyone');
    });
  });
}
