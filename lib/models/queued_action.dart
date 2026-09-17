import 'package:hive/hive.dart';

class QueuedAction {
  QueuedAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.retryCount = 0,
    this.failureReason,
  });

  /// UUID v4 — idempotency key, generated ONCE, never changes.
  final String id;
  final String type; // 'send' | 'contribute'
  final Map<String, dynamic> payload;
  final String status; // 'pending' | 'processing' | 'completed' | 'dead'
  final DateTime createdAt;
  final int retryCount;
  final String? failureReason;

  QueuedAction copyWith({
    String? status,
    Map<String, dynamic>? payload,
    int? retryCount,
    String? failureReason,
    bool clearFailureReason = false,
  }) {
    return QueuedAction(
      id: id,
      type: type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      failureReason: clearFailureReason
          ? null
          : (failureReason ?? this.failureReason),
    );
  }
}

class QueuedActionAdapter extends TypeAdapter<QueuedAction> {
  @override
  final int typeId = 0;

  @override
  QueuedAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedAction(
      id: fields[0] as String,
      type: fields[1] as String,
      payload: Map<String, dynamic>.from(fields[2] as Map),
      status: fields[3] as String,
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] as int? ?? 0,
      failureReason: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedAction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.failureReason);
  }
}
