import 'package:equatable/equatable.dart';

class ClientModel extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final double defaultRate;
  final String currency;
  final String? notes;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.company,
    required this.defaultRate,
    required this.currency,
    this.notes,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ClientModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    double? defaultRate,
    String? currency,
    String? notes,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      defaultRate: defaultRate ?? this.defaultRate,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'default_rate': defaultRate,
      'currency': currency,
      'notes': notes,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      company: map['company'],
      defaultRate: (map['default_rate'] as num).toDouble(),
      currency: map['currency'] ?? 'USD',
      notes: map['notes'],
      isArchived: map['is_archived'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, company, defaultRate, currency, isArchived];
}
