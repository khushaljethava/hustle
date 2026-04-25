import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/time_entry_repository.dart';
import '../utils/formatters.dart';

class CsvExportService {
  final InvoiceRepository _invoiceRepo;
  final TimeEntryRepository _timeEntryRepo;

  CsvExportService(this._invoiceRepo, this._timeEntryRepo);

  Future<void> exportInvoices() async {
    final invoices = await _invoiceRepo.getAll();
    final buffer = StringBuffer();
    buffer.writeln('Invoice #,Client,Currency,Subtotal,Tax,Total,Status,Issue Date,Due Date');

    for (final inv in invoices) {
      buffer.writeln([
        inv.invoiceNumber.toString().padLeft(4, '0'),
        _escape(inv.clientName),
        inv.currency,
        inv.subtotal.toStringAsFixed(2),
        inv.taxAmount.toStringAsFixed(2),
        inv.total.toStringAsFixed(2),
        inv.status,
        Formatters.formatDate(inv.issueDate),
        Formatters.formatDate(inv.dueDate),
      ].join(','));
    }

    await _share(buffer.toString(), 'hustle_invoices.csv', 'Export Invoices CSV');
  }

  Future<void> exportTimeEntries() async {
    final entries = await _timeEntryRepo.getAll();
    final buffer = StringBuffer();
    buffer.writeln('Date,Client,Task,Duration (hrs),Billable,Hourly Rate,Amount');

    for (final entry in entries) {
      if (entry.endTime == null) continue;
      final hours = entry.actualDuration.inSeconds / 3600;
      final amount = entry.isBillable ? hours * (entry.hourlyRate ?? 0) : 0.0;
      buffer.writeln([
        Formatters.formatDate(entry.startTime),
        _escape(entry.clientName ?? ''),
        _escape(entry.taskTitle ?? ''),
        hours.toStringAsFixed(2),
        entry.isBillable ? 'Yes' : 'No',
        (entry.hourlyRate ?? 0).toStringAsFixed(2),
        amount.toStringAsFixed(2),
      ].join(','));
    }

    await _share(buffer.toString(), 'hustle_time_entries.csv', 'Export Time Entries CSV');
  }

  Future<void> _share(String content, String filename, String subject) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: subject,
    );
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
