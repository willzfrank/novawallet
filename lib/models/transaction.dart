import 'package:hive/hive.dart';

class Transaction {
  Transaction({
    required this.id,
    required this.description,
    required this.amountKobo,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String description;
  final int amountKobo;
  final String type; // 'debit' | 'credit'
  final DateTime createdAt;
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      description: fields[1] as String,
      amountKobo: fields[2] as int,
      type: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.amountKobo)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
