import 'package:hive/hive.dart';

import 'rating_model.dart';

/// Hand-written Hive adapter for [RatingModel].
///
/// Replaces broken hive_generator_plus output. Serializes all 12 fields.
class RatingModelAdapter extends TypeAdapter<RatingModel> {
  @override
  final int typeId = 2;

  @override
  RatingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RatingModel(
      id: fields[0] as String? ?? '',
      plateNumber: fields[1] as String? ?? '',
      raterId: fields[2] as String?,
      isGood: fields[3] as bool? ?? true,
      tags: (fields[4] as List?)?.cast<String>() ?? [],
      comment: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      lat: fields[7] as double?,
      lng: fields[8] as double?,
      isSynced: fields[9] as bool? ?? false,
      syncedAt: fields[10] as DateTime?,
      tripId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RatingModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.plateNumber)
      ..writeByte(2)
      ..write(obj.raterId)
      ..writeByte(3)
      ..write(obj.isGood)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.comment)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lat)
      ..writeByte(8)
      ..write(obj.lng)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.syncedAt)
      ..writeByte(11)
      ..write(obj.tripId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
