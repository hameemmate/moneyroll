import 'package:hive/hive.dart';

enum PartyType { normal, company, transaction }

class PartyTypeAdapter extends TypeAdapter<PartyType> {
  @override
  final int typeId = 5;
  @override
  PartyType read(BinaryReader reader) {
    final idx = reader.readByte();
    return idx >= 0 && idx < PartyType.values.length
        ? PartyType.values[idx]
        : PartyType.normal;
  }

  @override
  void write(BinaryWriter writer, PartyType obj) => writer.writeByte(obj.index);
}

class PaymentEntryAdapter extends TypeAdapter<PaymentEntry> {
  @override
  final int typeId = 6;
  @override
  PaymentEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return PaymentEntry(
      id: fields[0] as String,
      displayId: fields[1] as String?,
      fromType: _asPartyType(fields[2]),
      fromId: fields[3] as String?,
      fromName: fields[4] as String,
      toType: _asPartyType(fields[5]),
      toId: fields[6] as String?,
      toName: fields[7] as String,
      amount: _asDouble(fields[8]),
      date: _parseDate(fields[9]) ?? DateTime.now(),
      description: fields[10] as String?,
      paymentMethod: fields[11] as String?,
      parentRefId: fields[12] as String?,
      sourcePaymentId: fields[13] as String?,
      deadline: _parseDate(fields[14]),
    );
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static PartyType _asPartyType(dynamic v) {
    if (v is int && v >= 0 && v < PartyType.values.length)
      return PartyType.values[v];
    return PartyType.normal;
  }

  @override
  void write(BinaryWriter writer, PaymentEntry obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayId)
      ..writeByte(2)
      ..write(obj.fromType.index)
      ..writeByte(3)
      ..write(obj.fromId)
      ..writeByte(4)
      ..write(obj.fromName)
      ..writeByte(5)
      ..write(obj.toType.index)
      ..writeByte(6)
      ..write(obj.toId)
      ..writeByte(7)
      ..write(obj.toName)
      ..writeByte(8)
      ..write(obj.amount)
      ..writeByte(9)
      ..write(obj.date.toIso8601String())
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.paymentMethod)
      ..writeByte(12)
      ..write(obj.parentRefId)
      ..writeByte(13)
      ..write(obj.sourcePaymentId)
      ..writeByte(14)
      ..write(obj.deadline?.toIso8601String());
  }
}

class PaymentEntry {
  final String id;
  final String? displayId;
  final PartyType fromType;
  final String? fromId;
  final String fromName;
  final PartyType toType;
  final String? toId;
  final String toName;
  final double amount;
  final DateTime date;
  final String? description;
  final String? paymentMethod;
  final String? parentRefId;
  final String? sourcePaymentId;
  final DateTime? deadline; // new

  PaymentEntry({
    required this.id,
    this.displayId,
    required this.fromType,
    this.fromId,
    required this.fromName,
    required this.toType,
    this.toId,
    required this.toName,
    required this.amount,
    required this.date,
    this.description,
    this.paymentMethod,
    this.parentRefId,
    this.sourcePaymentId,
    this.deadline,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayId': displayId,
    'fromType': fromType.index,
    'fromId': fromId,
    'fromName': fromName,
    'toType': toType.index,
    'toId': toId,
    'toName': toName,
    'amount': amount,
    'date': date.toIso8601String(),
    'description': description,
    'paymentMethod': paymentMethod,
    'parentRefId': parentRefId,
    'sourcePaymentId': sourcePaymentId,
    'deadline': deadline?.toIso8601String(),
  };

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
    id: json['id'],
    displayId: json['displayId'],
    fromType: PartyType.values[json['fromType'] as int],
    fromId: json['fromId'],
    fromName: json['fromName'] ?? '',
    toType: PartyType.values[json['toType'] as int],
    toId: json['toId'],
    toName: json['toName'] ?? '',
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    description: json['description'],
    paymentMethod: json['paymentMethod'],
    parentRefId: json['parentRefId'],
    sourcePaymentId: json['sourcePaymentId'],
    deadline: json['deadline'] != null
        ? DateTime.parse(json['deadline'])
        : null,
  );
}
