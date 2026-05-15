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

    // Defensive reads — see note in CompanyTransactionAdapter.
    return Transaction(
      id: _asString(fields[0]) ?? '',
      amount: _asDouble(fields[1]),
      date: _parseDate(fields[2]) ?? DateTime.now(),
      description: _asString(fields[3]),
      source: _asString(fields[4]),
      isCash: fields[5] is bool ? fields[5] as bool : true,
      referenceNumber: _asString(fields[6]),
      // Field 7 was added later — older records will not have it (null is OK).
      displayId: _asString(fields[7]),
      // Field 8 (added later — tree-wide default deadline for this normal
      // Transaction's payment tree). Older records have no deadline.
      deadline: _parseDate(fields[8]),
    );
  }

  static String? _asString(dynamic v) => v is String ? v : null;

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

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.displayId)
      ..writeByte(8)
      ..write(obj.deadline?.toIso8601String());
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
  // Tree-wide default deadline. When this Transaction is the root of a
  // payment tree, branches without their own deadline can inherit this
  // value for overdue detection.
  final DateTime? deadline;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    this.description,
    this.source,
    this.isCash = true,
    this.referenceNumber,
    this.displayId,
    this.deadline,
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
    DateTime? deadline,
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
      deadline: deadline ?? this.deadline,
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
      'deadline': deadline?.toIso8601String(),
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
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
    );
  }
}
