import 'package:hive/hive.dart';

import 'trip_model.dart';

/// Hand-written Hive adapter for [TripModel].
///
/// Replaces broken hive_generator_plus output. Serializes all 11 fields.
class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 3;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripModel(
      id: fields[0] as String? ?? '',
      userId: fields[1] as String? ?? '',
      startTime: fields[2] as DateTime?,
      endTime: fields[3] as DateTime?,
      distance: fields[4] as double? ?? 0.0,
      maxSpeed: fields[5] as double? ?? 0.0,
      avgSpeed: fields[6] as double? ?? 0.0,
      ratingId: fields[7] as String?,
      notes: fields[8] as String?,
      isSynced: fields[9] as bool? ?? false,
      plateNumber: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.distance)
      ..writeByte(5)
      ..write(obj.maxSpeed)
      ..writeByte(6)
      ..write(obj.avgSpeed)
      ..writeByte(7)
      ..write(obj.ratingId)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.plateNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
