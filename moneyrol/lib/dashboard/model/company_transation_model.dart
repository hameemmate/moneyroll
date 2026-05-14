import 'package:hive/hive.dart';

// TransactionType enum
enum TransactionType { received, sent }

// TransactionTypeAdapter class
class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 2;

  @override
  TransactionType read(BinaryReader reader) {
    return TransactionType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeByte(obj.index);
  }
}

// CompanyTransactionAdapter class
class CompanyTransactionAdapter extends TypeAdapter<CompanyTransaction> {
  @override
  final int typeId = 3;

  @override
  CompanyTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    // Defensive reads: device may carry records written by an earlier
    // version of this adapter where a particular field index held a
    // different type. We never want a stale on-disk row to crash app
    // startup, so every cast is null-tolerant and date parsing falls back
    // to null when the value isn't a String.
    return CompanyTransaction(
      id: _asString(fields[0]) ?? '',
      companyId: _asString(fields[1]) ?? '',
      companyName: _asString(fields[2]) ?? '',
      amount: _asDouble(fields[3]),
      date: _parseDate(fields[4]) ?? DateTime.now(),
      type: _asTransactionType(fields[5]),
      description: _asString(fields[6]),
      invoiceNumber: _asString(fields[7]),
      paymentMethod: _asString(fields[8]),
      // Field 9 added later — older records won't have it.
      displayId: _asString(fields[9]),
      // Field 10 added later. Some legacy/intermediate records can have
      // an int here (e.g. left over from a prior schema), so parse only
      // when it's actually a String.
      deadLine: _parseDate(fields[10]),
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

  static TransactionType _asTransactionType(dynamic v) {
    if (v is int && v >= 0 && v < TransactionType.values.length) {
      return TransactionType.values[v];
    }
    return TransactionType.received;
  }

  @override
  void write(BinaryWriter writer, CompanyTransaction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.companyId)
      ..writeByte(2)
      ..write(obj.companyName)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date.toIso8601String())
      ..writeByte(5)
      ..write(obj.type.index)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.invoiceNumber)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.displayId)
      ..writeByte(10)
      ..write(obj.deadLine?.toIso8601String());
  }
}

// CompanyTransaction model class
class CompanyTransaction {
  final String id;
  final String companyId;
  final String companyName;
  final double amount;
  final DateTime date;
  DateTime? deadLine;
  final TransactionType type;
  final String? description;
  final String? invoiceNumber;
  final String? paymentMethod;
  // Human-readable id like COMP-0001. Optional for backward compatibility.
  final String? displayId;

  CompanyTransaction({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
    this.invoiceNumber,
    this.deadLine,
    this.paymentMethod,
    this.displayId,
  });

  CompanyTransaction copyWith({
    String? id,
    String? companyId,
    String? companyName,
    double? amount,
    DateTime? date,
    DateTime? deadLine,
    TransactionType? type,
    String? description,
    String? invoiceNumber,
    String? paymentMethod,
    String? displayId,
  }) {
    return CompanyTransaction(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      deadLine: deadLine ?? this.deadLine,
      type: type ?? this.type,
      description: description ?? this.description,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      displayId: displayId ?? this.displayId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayId': displayId,
      'companyId': companyId,
      'companyName': companyName,
      'amount': amount,
      'date': date.toIso8601String(),
      'deadline': deadLine?.toIso8601String(),
      'type': type.index,
      'description': description,
      'invoiceNumber': invoiceNumber,
      'paymentMethod': paymentMethod,
    };
  }

  factory CompanyTransaction.fromJson(Map<String, dynamic> json) {
    return CompanyTransaction(
      id: json['id'],
      displayId: json['displayId'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      deadLine: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      type: TransactionType.values[json['type']],
      description: json['description'],
      invoiceNumber: json['invoiceNumber'],
      paymentMethod: json['paymentMethod'],
    );
  }
}
