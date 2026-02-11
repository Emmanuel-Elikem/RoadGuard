import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:road_guard/features/trip/application/trip_service.dart';
import 'package:road_guard/features/trip/data/repositories/trip_repository.dart';
import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/services/location_service.dart';
import 'package:road_guard/shared/services/storage_service.dart';

import 'trip_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<LocationService>(),
  MockSpec<StorageService>(),
  MockSpec<TripRepository>(),
])
void main() {
  late MockLocationService mockLocationService;
  late MockStorageService mockStorageService;
  late MockTripRepository mockTripRepository;
  late ProviderContainer container;

  setUp(() {
    mockLocationService = MockLocationService();
    mockStorageService = MockStorageService();
    mockTripRepository = MockTripRepository();

    // Default stubs
    when(mockLocationService.speedStream).thenAnswer((_) => const Stream.empty());
    when(mockStorageService.userId).thenReturn('test_user_id');

    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(mockLocationService),
        storageServiceProvider.overrideWithValue(mockStorageService),
        tripRepositoryProvider.overrideWithValue(mockTripRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TripController', () {
    test('initial state is TripState.idle', () {
      final state = container.read(tripControllerProvider);
      expect(state, TripState.idle);
    });

    test('startTrip changes state to recording and initializes trip', () {
      final controller = container.read(tripControllerProvider.notifier);
      
      controller.startTrip();
      
      expect(container.read(tripControllerProvider), TripState.recording);
      expect(controller.currentTrip, isNotNull);
      expect(controller.currentTrip!.userId, 'test_user_id');
      verify(mockLocationService.speedStream).called(1);
    });

    test('stopTrip changes state to idle and updates trip stats', () async {
      final controller = container.read(tripControllerProvider.notifier);
      
      // Start trip
      controller.startTrip();
      
      // Simulate some time passing (controller uses DateTime.now(), difficult to mock exact duration without Clock)
      // For this test, we just check state transition
      
      controller.stopTrip();
      
      expect(container.read(tripControllerProvider), TripState.idle);
      expect(controller.currentTrip!.endTime, isNotNull);
    });

    test('saveCompletedTrip calls repository', () async {
       final controller = container.read(tripControllerProvider.notifier);
       final trip = TripModel(id: '1', userId: 'u1', startTime: DateTime.now());
       
       await controller.saveCompletedTrip(trip);
       
       verify(mockTripRepository.saveTrip(trip)).called(1);
    });
  });
}
