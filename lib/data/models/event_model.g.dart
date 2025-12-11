// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 2;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventModel(
      id: fields[0] as String,
      userId: fields[14] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      dateTime: fields[3] as DateTime,
      location: fields[4] as String?,
      attendeesCount: fields[5] as int?,
      status: fields[6] as int,
      isRecurring: fields[7] as bool,
      recurringFrequency: fields[8] as String?,
      recurringEndDate: fields[9] as DateTime?,
      notificationDays: (fields[10] as List).cast<int>(),
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      color: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.attendeesCount)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.isRecurring)
      ..writeByte(8)
      ..write(obj.recurringFrequency)
      ..writeByte(9)
      ..write(obj.recurringEndDate)
      ..writeByte(10)
      ..write(obj.notificationDays)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.color)
      ..writeByte(14)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
