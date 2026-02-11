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
    );
  }

  @override
  void write(BinaryWriter writer, CompanyTransaction obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.paymentMethod);
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
    };
  }

  factory CompanyTransaction.fromJson(Map<String, dynamic> json) {
    return CompanyTransaction(
      id: json['id'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      deadLine: DateTime.parse(json['deadline']),
      type: TransactionType.values[json['type']],
      description: json['description'],
      invoiceNumber: json['invoiceNumber'],
      paymentMethod: json['paymentMethod'],
    );
  }
}
