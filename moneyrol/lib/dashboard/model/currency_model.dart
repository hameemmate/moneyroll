// models/currency_model.dart
import 'package:hive_flutter/hive_flutter.dart';

class Currency {
  final String symbol;
  final String code;
  final String name;
  final String imagePath;

  Currency({
    required this.symbol,
    required this.code,
    required this.name,
    required this.imagePath,
  });

  // For JSON serialization (for export/import)
  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'code': code,
    'name': name,
    'imagePath': imagePath,
  };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    symbol: json['symbol'],
    code: json['code'],
    name: json['name'],
    imagePath: json['imagePath'],
  );
}

class CurrencyAdapter extends TypeAdapter<Currency> {
  @override
  final int typeId = 4; // Use typeId 4 (unique from your others: 0, 1, 2, 3)

  @override
  Currency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return Currency(
      symbol: fields[0] as String,
      code: fields[1] as String,
      name: fields[2] as String,
      imagePath: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Currency obj) {
    writer
      ..writeByte(4) // Number of fields
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.imagePath);
  }
}
