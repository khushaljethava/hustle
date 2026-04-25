import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../constants/app_constants.dart';

class RecurringInvoiceService {
  final InvoiceRepository _invoiceRepo;

  RecurringInvoiceService(this._invoiceRepo);

  /// Called on app start. Generates new draft invoices for any recurring
  /// template whose next_date has passed, then advances the next_date.
  Future<List<InvoiceModel>> processRecurring() async {
    final due = await _invoiceRepo.getRecurringDue();
    final generated = <InvoiceModel>[];

    for (final template in due) {
      final newInvoice = await _invoiceRepo.create(
        clientId: template.clientId,
        clientName: template.clientName,
        clientEmail: template.clientEmail,
        items: template.items,
        taxRate: template.taxRate,
        currency: template.currency,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        notes: template.notes,
        status: 'draft',
        template: template.template,
      );
      generated.add(newInvoice);

      final next = _nextDate(
        template.recurringNextDate ?? DateTime.now(),
        template.recurringInterval ?? AppConstants.recurringMonthly,
      );
      await _invoiceRepo.updateRecurringNextDate(template.id, next);
    }

    return generated;
  }

  DateTime _nextDate(DateTime from, String interval) {
    switch (interval) {
      case AppConstants.recurringWeekly:
        return from.add(const Duration(days: 7));
      case AppConstants.recurringQuarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case AppConstants.recurringMonthly:
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
