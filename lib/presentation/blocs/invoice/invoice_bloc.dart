import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/invoice_repository.dart';

// Events
abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {
  final String? statusFilter;
  const LoadInvoices({this.statusFilter});
  @override
  List<Object?> get props => [statusFilter];
}

class CreateInvoice extends InvoiceEvent {
  final String clientId;
  final String clientName;
  final String? clientEmail;
  final List<InvoiceItemModel> items;
  final double taxRate;
  final String currency;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? notes;
  final bool isRecurring;
  final String? recurringInterval;
  final String template;

  const CreateInvoice({
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    required this.items,
    required this.taxRate,
    required this.currency,
    required this.issueDate,
    required this.dueDate,
    this.notes,
    this.isRecurring = false,
    this.recurringInterval,
    this.template = 'classic',
  });

  @override
  List<Object?> get props => [clientId, items, total];
  double get total => items.fold(0, (sum, i) => sum + i.amount);
}

class MarkInvoicePaid extends InvoiceEvent {
  final String invoiceId;
  const MarkInvoicePaid(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class MarkInvoiceSent extends InvoiceEvent {
  final String invoiceId;
  const MarkInvoiceSent(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class DeleteInvoice extends InvoiceEvent {
  final String invoiceId;
  const DeleteInvoice(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

// States
abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}
class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceModel> invoices;
  final Map<String, dynamic> stats;
  const InvoiceLoaded({required this.invoices, required this.stats});
  @override
  List<Object?> get props => [invoices, stats];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceOperationSuccess extends InvoiceState {
  final String message;
  final InvoiceModel? invoice;
  final List<InvoiceModel> invoices;
  final Map<String, dynamic> stats;
  const InvoiceOperationSuccess({
    required this.message,
    this.invoice,
    required this.invoices,
    required this.stats,
  });
  @override
  List<Object?> get props => [message, invoice, invoices];
}

// BLoC
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository _repository;
  String? _currentFilter;

  InvoiceBloc(this._repository) : super(InvoiceInitial()) {
    on<LoadInvoices>(_onLoad);
    on<CreateInvoice>(_onCreate);
    on<MarkInvoicePaid>(_onMarkPaid);
    on<MarkInvoiceSent>(_onMarkSent);
    on<DeleteInvoice>(_onDelete);
  }

  Future<void> _onLoad(LoadInvoices event, Emitter<InvoiceState> emit) async {
    emit(InvoiceLoading());
    try {
      _currentFilter = event.statusFilter;
      final invoices = await _repository.getAll(status: event.statusFilter);
      final stats = await _repository.getDashboardStats();
      emit(InvoiceLoaded(invoices: invoices, stats: stats));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateInvoice event, Emitter<InvoiceState> emit) async {
    try {
      final recurringNext = event.isRecurring
          ? _nextRecurringDate(DateTime.now(), event.recurringInterval ?? 'monthly')
          : null;
      final invoice = await _repository.create(
        clientId: event.clientId,
        clientName: event.clientName,
        clientEmail: event.clientEmail,
        items: event.items,
        taxRate: event.taxRate,
        currency: event.currency,
        issueDate: event.issueDate,
        dueDate: event.dueDate,
        notes: event.notes,
        isRecurring: event.isRecurring,
        recurringInterval: event.recurringInterval,
        recurringNextDate: recurringNext,
        template: event.template,
      );
      final invoices = await _repository.getAll(status: _currentFilter);
      final stats = await _repository.getDashboardStats();
      emit(InvoiceOperationSuccess(
        message: 'Invoice created',
        invoice: invoice,
        invoices: invoices,
        stats: stats,
      ));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onMarkPaid(MarkInvoicePaid event, Emitter<InvoiceState> emit) async {
    try {
      final invoice = await _repository.updateStatus(event.invoiceId, 'paid');
      final invoices = await _repository.getAll(status: _currentFilter);
      final stats = await _repository.getDashboardStats();
      emit(InvoiceOperationSuccess(
        message: 'Invoice marked as paid',
        invoice: invoice,
        invoices: invoices,
        stats: stats,
      ));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onMarkSent(MarkInvoiceSent event, Emitter<InvoiceState> emit) async {
    try {
      final invoice = await _repository.updateStatus(event.invoiceId, 'sent');
      final invoices = await _repository.getAll(status: _currentFilter);
      final stats = await _repository.getDashboardStats();
      emit(InvoiceOperationSuccess(
        message: 'Invoice marked as sent',
        invoice: invoice,
        invoices: invoices,
        stats: stats,
      ));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteInvoice event, Emitter<InvoiceState> emit) async {
    try {
      await _repository.delete(event.invoiceId);
      final invoices = await _repository.getAll(status: _currentFilter);
      final stats = await _repository.getDashboardStats();
      emit(InvoiceOperationSuccess(
        message: 'Invoice deleted',
        invoices: invoices,
        stats: stats,
      ));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  DateTime _nextRecurringDate(DateTime from, String interval) {
    switch (interval) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'quarterly':
        return DateTime(from.year, from.month + 3, from.day);
      case 'monthly':
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
