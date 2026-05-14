import 'package:hive/hive.dart';

// TransactionAdapter class
class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return Transaction(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      date: DateTime.parse(fields[2] as String),
      description: fields[3] as String?,
      source: fields[4] as String?,
      isCash: fields[5] as bool? ?? true,
      referenceNumber: fields[6] as String?,
      // Field 7 was added later — older records will not have it (null is OK).
      displayId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date.toIso8601String())
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.isCash)
      ..writeByte(6)
      ..write(obj.referenceNumber)
      ..writeByte(7)
      ..write(obj.displayId);
  }
}

// Transaction model class
class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String? description;
  final String? source;
  final bool isCash;
  final String? referenceNumber;
  // Human-readable id like TXN-0001. Optional for backward compatibility
  // with records created before this field existed.
  final String? displayId;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    this.description,
    this.source,
    this.isCash = true,
    this.referenceNumber,
    this.displayId,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? description,
    String? source,
    bool? isCash,
    String? referenceNumber,
    String? displayId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      source: source ?? this.source,
      isCash: isCash ?? this.isCash,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      displayId: displayId ?? this.displayId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayId': displayId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'source': source,
      'isCash': isCash,
      'referenceNumber': referenceNumber,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      displayId: json['displayId'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      source: json['source'],
      isCash: json['isCash'] ?? true,
      referenceNumber: json['referenceNumber'],
    );
  }
}
