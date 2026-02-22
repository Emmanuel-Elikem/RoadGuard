import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

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
  MockSpec<Box<dynamic>>(),
])
void main() {
  late MockLocationService mockLocationService;
  late MockStorageService mockStorageService;
  late MockTripRepository mockTripRepository;
  late MockBox mockSettingsBox;
  late ProviderContainer container;

  setUp(() {
    mockLocationService = MockLocationService();
    mockStorageService = MockStorageService();
    mockTripRepository = MockTripRepository();
    mockSettingsBox = MockBox();

    // Default stubs
    when(mockLocationService.speedStream).thenAnswer((_) => const Stream.empty());
    when(mockStorageService.userId).thenReturn('test_user_id');
    when(mockStorageService.settingsBox).thenReturn(mockSettingsBox);

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
      
      // Must await since stopTrip is async
      await controller.stopTrip();
      
      expect(container.read(tripControllerProvider), TripState.idle);
      expect(controller.currentTrip!.endTime, isNotNull);
    });

    test('saveCompletedTrip calls repository', () async {
       final controller = container.read(tripControllerProvider.notifier);
       final trip = TripModel(id: '1', userId: 'u1', startTime: DateTime.now());
       
       await controller.saveCompletedTrip(trip);
       
       verify(mockTripRepository.saveTrip(trip)).called(1);
    });

    group('draft trip persistence', () {
      test('hasDraftTrip returns false when no draft exists', () {
        when(mockSettingsBox.get('draft_trip_id')).thenReturn(null);

        final controller = container.read(tripControllerProvider.notifier);
        expect(controller.hasDraftTrip, isFalse);
      });

      test('hasDraftTrip returns true when draft exists', () {
        when(mockSettingsBox.get('draft_trip_id')).thenReturn('trip-123');

        final controller = container.read(tripControllerProvider.notifier);
        expect(controller.hasDraftTrip, isTrue);
      });

      test('resumeTrip restores state from draft and sets recording', () {
        final startTime = DateTime.now().subtract(const Duration(minutes: 5));
        when(mockSettingsBox.get('draft_trip_id')).thenReturn('trip-123');
        when(mockSettingsBox.get('draft_trip_user_id', defaultValue: 'guest'))
            .thenReturn('test_user');
        when(mockSettingsBox.get('draft_trip_start_time'))
            .thenReturn(startTime.toIso8601String());
        when(mockSettingsBox.get('draft_trip_max_speed', defaultValue: 0.0))
            .thenReturn(25.5);
        when(mockSettingsBox.get('draft_trip_distance', defaultValue: 0.0))
            .thenReturn(1500.0);
        when(mockSettingsBox.get('draft_trip_route_points', defaultValue: ''))
            .thenReturn('5.55,-0.20,10.0;5.56,-0.21,12.0');

        final controller = container.read(tripControllerProvider.notifier);
        final result = controller.resumeTrip();

        expect(result, isTrue);
        expect(container.read(tripControllerProvider), TripState.recording);
        expect(controller.currentTrip, isNotNull);
        expect(controller.currentTrip!.id, 'trip-123');
        expect(controller.currentTrip!.userId, 'test_user');
        expect(controller.currentMaxSpeed, closeTo(25.5 * 3.6, 0.01));
        expect(controller.currentDistance, closeTo(1.5, 0.001));
      });

      test('resumeTrip returns false when no draft exists', () {
        when(mockSettingsBox.get('draft_trip_id')).thenReturn(null);

        final controller = container.read(tripControllerProvider.notifier);
        expect(controller.resumeTrip(), isFalse);
        expect(container.read(tripControllerProvider), TripState.idle);
      });

      test('resumeTrip returns false when already recording', () {
        final controller = container.read(tripControllerProvider.notifier);
        controller.startTrip();

        expect(controller.resumeTrip(), isFalse);
      });

      test('discardDraftTrip clears all draft keys from Hive', () {
        final controller = container.read(tripControllerProvider.notifier);
        controller.discardDraftTrip();

        verify(mockSettingsBox.delete('draft_trip_id')).called(1);
        verify(mockSettingsBox.delete('draft_trip_user_id')).called(1);
        verify(mockSettingsBox.delete('draft_trip_start_time')).called(1);
        verify(mockSettingsBox.delete('draft_trip_route_points')).called(1);
        verify(mockSettingsBox.delete('draft_trip_max_speed')).called(1);
        verify(mockSettingsBox.delete('draft_trip_distance')).called(1);
      });
    });
  });
}
