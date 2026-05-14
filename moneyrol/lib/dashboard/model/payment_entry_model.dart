import 'package:hive/hive.dart';

// PartyType enum - the kind of party involved in a payment movement.
// `normal`      => personal/cash (you)
// `company`     => a saved Company / partner
// `transaction` => an existing Transaction or CompanyTransaction record
//                  (used when posting a payment against / from another txn)
enum PartyType { normal, company, transaction }

// PartyTypeAdapter
class PartyTypeAdapter extends TypeAdapter<PartyType> {
  @override
  final int typeId = 5;

  @override
  PartyType read(BinaryReader reader) {
    final idx = reader.readByte();
    if (idx < 0 || idx >= PartyType.values.length) {
      return PartyType.normal;
    }
    return PartyType.values[idx];
  }

  @override
  void write(BinaryWriter writer, PartyType obj) {
    writer.writeByte(obj.index);
  }
}

// PaymentEntryAdapter
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
      fromType: PartyType.values[fields[2] as int],
      fromId: fields[3] as String?,
      fromName: fields[4] as String,
      toType: PartyType.values[fields[5] as int],
      toId: fields[6] as String?,
      toName: fields[7] as String,
      amount: (fields[8] as num).toDouble(),
      date: DateTime.parse(fields[9] as String),
      description: fields[10] as String?,
      paymentMethod: fields[11] as String?,
      parentRefId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentEntry obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.parentRefId);
  }
}

// PaymentEntry model class
//
// Represents a single money movement between two parties. Use this as the
// authoritative history record for tracking who sent what to whom and when.
//
// - `parentRefId` (optional) links this payment to a parent transaction or
//   company-transaction record. When set, the parent's "current amount" is
//   the original amount adjusted by all payments referencing it.
// - `fromId` / `toId` hold the relevant entity id when the party is a
//   `company` (companyId) or a `transaction` (txn id). For `normal`, leave
//   the id null.
class PaymentEntry {
  final String id;
  final String? displayId; // e.g. PAY-0001
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
  });

  // Convenience: returns true if `entityId` is involved on the "from" side.
  bool isFrom({required PartyType type, String? id}) {
    if (type != fromType) return false;
    if (type == PartyType.normal) return true; // normal has no id
    return fromId == id;
  }

  // Convenience: returns true if `entityId` is involved on the "to" side.
  bool isTo({required PartyType type, String? id}) {
    if (type != toType) return false;
    if (type == PartyType.normal) return true;
    return toId == id;
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
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
    );
  }
}
