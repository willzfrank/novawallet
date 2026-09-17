import 'package:hive/hive.dart';

class SaveGoal {
  SaveGoal({
    required this.id,
    required this.name,
    required this.targetAmountKobo,
    required this.savedAmountKobo,
    required this.targetDate,
  });

  final String id;
  final String name;
  final int targetAmountKobo;
  int savedAmountKobo;
  final DateTime targetDate;

  double get progress {
    if (targetAmountKobo <= 0) return 0;
    final ratio = savedAmountKobo / targetAmountKobo;
    if (ratio > 1) return 1;
    if (ratio < 0) return 0;
    return ratio;
  }

  int get progressPercent => (progress * 100).round();

  SaveGoal copyWith({int? savedAmountKobo}) {
    return SaveGoal(
      id: id,
      name: name,
      targetAmountKobo: targetAmountKobo,
      savedAmountKobo: savedAmountKobo ?? this.savedAmountKobo,
      targetDate: targetDate,
    );
  }
}

class SaveGoalAdapter extends TypeAdapter<SaveGoal> {
  @override
  final int typeId = 2;

  @override
  SaveGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaveGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmountKobo: fields[2] as int,
      savedAmountKobo: fields[3] as int,
      targetDate: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SaveGoal obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmountKobo)
      ..writeByte(3)
      ..write(obj.savedAmountKobo)
      ..writeByte(4)
      ..write(obj.targetDate);
  }
}
