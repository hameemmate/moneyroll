import 'package:hive/hive.dart';

// CompanyAdapter class
class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final int typeId = 0;

  @override
  Company read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return Company(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      createdAt: DateTime.parse(fields[3] as String),
      contactPerson: fields[4] as String?,
      phoneNumber: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(4)
      ..write(obj.contactPerson)
      ..writeByte(5)
      ..write(obj.phoneNumber);
  }
}

// Company model class
class Company {
  final String id;
  String name;
  String? description;
  final DateTime createdAt;
  String? contactPerson;
  String? phoneNumber;

  Company({
    required this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
    this.contactPerson,
    this.phoneNumber,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      contactPerson: json['contactPerson'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
