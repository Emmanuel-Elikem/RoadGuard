import 'package:hive/hive.dart';

import 'driver_model.dart';

/// Hand-written Hive adapter for [DriverModel].
///
/// Replaces broken hive_generator_plus output. Serializes all 8 fields.
class DriverModelAdapter extends TypeAdapter<DriverModel> {
  @override
  final int typeId = 4;

  @override
  DriverModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverModel(
      plateNumber: fields[0] as String? ?? '',
      totalRatings: fields[1] as int? ?? 0,
      goodRatings: fields[2] as int? ?? 0,
      badRatings: fields[3] as int? ?? 0,
      commonTags: (fields[4] as List?)?.cast<String>() ?? [],
      lastUpdated: fields[5] as DateTime?,
      region: fields[6] as String?,
      tagFrequency: (fields[7] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, DriverModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.plateNumber)
      ..writeByte(1)
      ..write(obj.totalRatings)
      ..writeByte(2)
      ..write(obj.goodRatings)
      ..writeByte(3)
      ..write(obj.badRatings)
      ..writeByte(4)
      ..write(obj.commonTags)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.region)
      ..writeByte(7)
      ..write(obj.tagFrequency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
