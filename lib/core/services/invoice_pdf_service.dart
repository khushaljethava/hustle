import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';
import '../../data/models/invoice_model.dart';

class InvoicePdfService {
  final SharedPreferences _prefs;

  InvoicePdfService(this._prefs);

  static const _brandColor = PdfColor.fromInt(0xFF4F6EF7);
  static const _mutedColor = PdfColor.fromInt(0xFF6B7280);
  static const _modernAccent = PdfColor.fromInt(0xFF1E293B);
  static const _minimalLine = PdfColor.fromInt(0xFFE2E8F0);

  /// Template colour per name
  PdfColor _accentFor(String template) {
    switch (template) {
      case AppConstants.templateModern:
        return _modernAccent;
      case AppConstants.templateMinimal:
        return _mutedColor;
      default: // classic
        return _brandColor;
    }
  }

  Future<Uint8List> generate(InvoiceModel invoice) async {
    final businessName =
        _prefs.getString(AppConstants.keyBusinessName)?.isNotEmpty == true
            ? _prefs.getString(AppConstants.keyBusinessName)!
            : AppConstants.appName;

    final logoBase64 = _prefs.getString(AppConstants.keyLogoBase64);
    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(logoBase64));
      } catch (_) {
        logoImage = null;
      }
    }

    final pdf = pw.Document(
      title: 'Invoice ${Formatters.invoiceNumber(invoice.invoiceNumber)}',
      author: businessName,
    );

    final accent = _accentFor(invoice.template);
    final isMinimal = invoice.template == AppConstants.templateMinimal;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(isMinimal ? 56 : 48),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(businessName, invoice, accent, isMinimal, logoImage),
            pw.SizedBox(height: 32),
            _buildBillTo(invoice),
            pw.SizedBox(height: 24),
            _buildItemsTable(invoice, accent),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: _buildTotals(invoice, accent),
            ),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildNotes(invoice.notes!),
            ],
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    String businessName,
    InvoiceModel invoice,
    PdfColor accent,
    bool minimal,
    pw.MemoryImage? logo,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo + business name
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 56,
                height: 56,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: accent,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Invoice meta
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              Formatters.invoiceNumber(invoice.invoiceNumber),
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Issued: ${_fmtDate(invoice.issueDate)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Text(
              'Due: ${_fmtDate(invoice.dueDate)}',
              style: pw.TextStyle(
                fontSize: 11,
                color: invoice.isOverdue ? PdfColors.red : _mutedColor,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _statusColor(invoice),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                invoice.status.toUpperCase(),
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBillTo(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(
            fontSize: 9,
            letterSpacing: 1.5,
            color: _mutedColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          invoice.clientName,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (invoice.clientEmail != null)
          pw.Text(
            invoice.clientEmail!,
            style: pw.TextStyle(fontSize: 11, color: _mutedColor),
          ),
      ],
    );
  }

  pw.Widget _buildItemsTable(InvoiceModel invoice, PdfColor accent) {
    final headers = ['Description', 'Qty', 'Rate', 'Amount'];
    final rows = invoice.items
        .map((item) => [
              item.description,
              item.quantity % 1 == 0
                  ? item.quantity.toInt().toString()
                  : item.quantity.toStringAsFixed(2),
              Formatters.formatCurrency(item.rate, invoice.currency),
              Formatters.formatCurrency(item.amount, invoice.currency),
            ])
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accent),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: h == 'Description'
                        ? pw.TextAlign.left
                        : pw.TextAlign.right,
                  ),
                ),
              )
              .toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey100 : PdfColors.white,
            ),
            children: entry.value.asMap().entries.map((cell) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: pw.Text(
                  cell.value,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign:
                      cell.key == 0 ? pw.TextAlign.left : pw.TextAlign.right,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotals(InvoiceModel invoice, PdfColor accent) {
    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        children: [
          _totalsRow('Subtotal',
              Formatters.formatCurrency(invoice.subtotal, invoice.currency), accent),
          if (invoice.taxRate > 0) ...[
            pw.SizedBox(height: 4),
            _totalsRow(
              'Tax (${invoice.taxRate.toStringAsFixed(0)}%)',
              Formatters.formatCurrency(invoice.taxAmount, invoice.currency),
              accent,
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Divider(color: accent, thickness: 1.5),
          pw.SizedBox(height: 4),
          _totalsRow(
            'TOTAL',
            Formatters.formatCurrency(invoice.total, invoice.currency),
            accent,
            bold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _totalsRow(String label, String value, PdfColor accent, {bool bold = false}) {
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)
        : const pw.TextStyle(fontSize: 11);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value,
            style: bold
                ? pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: accent)
                : style),
      ],
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes',
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        pw.SizedBox(height: 4),
        pw.Text(notes,
            style: pw.TextStyle(fontSize: 10, color: _mutedColor)),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Thank you for your business! • Generated by ${AppConstants.appName}',
            style: pw.TextStyle(fontSize: 9, color: _mutedColor),
          ),
        ),
      ],
    );
  }

  PdfColor _statusColor(InvoiceModel invoice) {
    if (invoice.isPaid) return PdfColors.green600;
    if (invoice.isOverdue) return PdfColors.red;
    if (invoice.isSent) return PdfColors.blue600;
    return PdfColors.grey600;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
