// company_transation_model.dart - UPDATED with recordId
import 'package:hive/hive.dart';

// TransactionType enum (keep this)
enum TransactionType { received, sent }

// SourceType enum for tracking where money comes from
enum SourceType { normal, company, internal }

// TransactionTypeAdapter (keep existing)
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

// SourceTypeAdapter
class SourceTypeAdapter extends TypeAdapter<SourceType> {
  @override
  final int typeId = 4;

  @override
  SourceType read(BinaryReader reader) {
    return SourceType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SourceType obj) {
    writer.writeByte(obj.index);
  }
}

// CompanyTransactionAdapter - UPDATED (14 fields now, added recordId at index 13)
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

    return CompanyTransaction(
      id: fields[0] as String,
      companyId: fields[1] as String,
      companyName: fields[2] as String,
      amount: fields[3] as double,
      date: DateTime.parse(fields[4] as String),
      type: TransactionType.values[fields[5] as int],
      description: fields[6] as String?,
      invoiceNumber: fields[7] as String?,
      paymentMethod: fields[8] as String?,
      deadLine: fields[9] != null ? DateTime.parse(fields[9] as String) : null,
      sourceType: fields[10] != null
          ? SourceType.values[fields[10] as int]
          : SourceType.normal,
      sourceCompanyId: fields[11] as String?,
      sourceCompanyName: fields[12] as String?,
      recordId: fields[13] as String?, // ← NEW
    );
  }

  @override
  void write(BinaryWriter writer, CompanyTransaction obj) {
    writer
      ..writeByte(14) // ← was 13, now 14
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
      ..write(obj.deadLine?.toIso8601String())
      ..writeByte(10)
      ..write(obj.sourceType.index)
      ..writeByte(11)
      ..write(obj.sourceCompanyId)
      ..writeByte(12)
      ..write(obj.sourceCompanyName)
      ..writeByte(13)
      ..write(obj.recordId); // ← NEW
  }
}

// CompanyTransaction model class - UPDATED
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
  final SourceType sourceType;
  final String? sourceCompanyId;
  final String? sourceCompanyName;
  final String? recordId; // ← NEW: groups payments under one record

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
    this.sourceType = SourceType.normal,
    this.sourceCompanyId,
    this.sourceCompanyName,
    this.recordId, // ← NEW
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'amount': amount,
      'date': date.toIso8601String(),
      'deadline': deadLine?.toIso8601String(),
      'type': type.index,
      'description': description,
      'invoiceNumber': invoiceNumber,
      'paymentMethod': paymentMethod,
      'sourceType': sourceType.index,
      'sourceCompanyId': sourceCompanyId,
      'sourceCompanyName': sourceCompanyName,
      'recordId': recordId, // ← NEW
    };
  }

  factory CompanyTransaction.fromJson(Map<String, dynamic> json) {
    return CompanyTransaction(
      id: json['id'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      deadLine: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      type: TransactionType.values[json['type']],
      description: json['description'],
      invoiceNumber: json['invoiceNumber'],
      paymentMethod: json['paymentMethod'],
      sourceType: json['sourceType'] != null
          ? SourceType.values[json['sourceType']]
          : SourceType.normal,
      sourceCompanyId: json['sourceCompanyId'],
      sourceCompanyName: json['sourceCompanyName'],
      recordId: json['recordId'], // ← NEW
    );
  }
}
