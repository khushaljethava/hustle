import 'package:equatable/equatable.dart';

class InvoiceItemModel extends Equatable {
  final String id;
  final String invoiceId;
  final String description;
  final double quantity;
  final double rate;
  final double amount;

  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  InvoiceItemModel copyWith({
    String? id,
    String? invoiceId,
    String? description,
    double? quantity,
    double? rate,
    double? amount,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'],
      invoiceId: map['invoice_id'],
      description: map['description'],
      quantity: (map['quantity'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, invoiceId, description, quantity, rate, amount];
}

class InvoiceModel extends Equatable {
  final String id;
  final int invoiceNumber;
  final String clientId;
  final String clientName;
  final String? clientEmail;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  final String status;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? notes;
  final bool isRecurring;
  final String? recurringInterval;
  final DateTime? recurringNextDate;
  final String template;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.currency,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    this.notes,
    this.isRecurring = false,
    this.recurringInterval,
    this.recurringNextDate,
    this.template = 'classic',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isPaid => status == 'paid';
  bool get isOverdue =>
      (status == 'sent') && dueDate.isBefore(DateTime.now());

  InvoiceModel copyWith({
    String? id,
    int? invoiceNumber,
    String? clientId,
    String? clientName,
    String? clientEmail,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? currency,
    String? status,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
    bool? isRecurring,
    String? recurringInterval,
    DateTime? recurringNextDate,
    String? template,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      recurringNextDate: recurringNextDate ?? this.recurringNextDate,
      template: template ?? this.template,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'currency': currency,
      'status': status,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'notes': notes,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_interval': recurringInterval,
      'recurring_next_date': recurringNextDate?.toIso8601String(),
      'template': template,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, List<InvoiceItemModel> items) {
    return InvoiceModel(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      clientEmail: map['client_email'],
      items: items,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxRate: (map['tax_rate'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      currency: map['currency'] ?? 'USD',
      status: map['status'] ?? 'draft',
      issueDate: DateTime.parse(map['issue_date']),
      dueDate: DateTime.parse(map['due_date']),
      notes: map['notes'],
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurringInterval: map['recurring_interval'],
      recurringNextDate: map['recurring_next_date'] != null
          ? DateTime.parse(map['recurring_next_date'])
          : null,
      template: map['template'] as String? ?? 'classic',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, invoiceNumber, clientId, status, total];
}
