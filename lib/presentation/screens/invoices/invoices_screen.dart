import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../../blocs/invoice/invoice_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/undo_snackbar.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/services/invoice_pdf_service.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice_model.dart';
import '../../../di/service_locator.dart';
import 'create_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _filter = 'all';
  String get _currency => sl<ValueNotifier<String>>().value;

  @override
  void initState() {
    super.initState();
    sl<ValueNotifier<String>>().addListener(_onCurrencyChanged);
    context.read<InvoiceBloc>().add(const LoadInvoices());
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    sl<ValueNotifier<String>>().removeListener(_onCurrencyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterBar(
            selected: _filter,
            onChanged: (f) {
              setState(() => _filter = f);
              context.read<InvoiceBloc>().add(LoadInvoices(
                statusFilter: f == 'all' ? null : f,
              ));
            },
          ),
        ),
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
            );
          } else if (state is InvoiceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = state is InvoiceLoaded
              ? state.invoices
              : state is InvoiceOperationSuccess
                  ? state.invoices
                  : <InvoiceModel>[];

          final stats = state is InvoiceLoaded
              ? state.stats
              : state is InvoiceOperationSuccess
                  ? state.stats
                  : <String, dynamic>{};

          return Column(
            children: [
              if (stats.isNotEmpty) _buildStatsBar(context, stats),
              Expanded(
                child: invoices.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No invoices yet',
                        subtitle: 'Create your first invoice to get paid',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final invoice = invoices[i];
                          return _InvoiceCard(
                            invoice: invoice,
                            onMarkPaid: () => context
                                .read<InvoiceBloc>()
                                .add(MarkInvoicePaid(invoice.id)),
                            onMarkSent: () => context
                                .read<InvoiceBloc>()
                                .add(MarkInvoiceSent(invoice.id)),
                            onDelete: () {
                              context
                                  .read<InvoiceBloc>()
                                  .add(DeleteInvoice(invoice.id));
                              showUndoSnackBar(
                                context,
                                message: 'Invoice deleted',
                                onUndo: () => context.read<InvoiceBloc>().add(
                                      CreateInvoice(
                                        clientId: invoice.clientId,
                                        clientName: invoice.clientName,
                                        clientEmail: invoice.clientEmail,
                                        items: invoice.items,
                                        taxRate: invoice.taxRate,
                                        currency: invoice.currency,
                                        issueDate: invoice.issueDate,
                                        dueDate: invoice.dueDate,
                                        notes: invoice.notes,
                                        isRecurring: invoice.isRecurring,
                                        recurringInterval:
                                            invoice.recurringInterval,
                                        template: invoice.template,
                                      ),
                                    ),
                              );
                            },
                            onExportPdf: () => _exportPdf(context, invoice),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invoices_fab',
        onPressed: () => _createInvoice(context),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, Map<String, dynamic> stats) {
    final currency = _currency;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StatCard(
                label: 'This Month',
                value: Formatters.formatCurrency((stats['monthlyEarned'] as num?)?.toDouble() ?? 0, currency),
                icon: Icons.trending_up,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Outstanding',
                value: Formatters.formatCurrency((stats['outstanding'] as num?)?.toDouble() ?? 0, currency),
                subtitle: '${stats['unpaidCount'] ?? 0} unpaid',
                icon: Icons.pending_outlined,
                color: (stats['overdueCount'] ?? 0) > 0 ? AppTheme.errorColor : AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createInvoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<InvoiceBloc>(),
          child: const CreateInvoiceScreen(),
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    if (!sl<ProService>().isProUser) {
      Navigator.pushNamed(context, '/paywall');
      return;
    }
    try {
      await sl<CsvExportService>().exportInvoices();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export CSV. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, InvoiceModel invoice) async {
    if (!sl<ProService>().isProUser) {
      Navigator.pushNamed(context, '/paywall');
      return;
    }
    try {
      final bytes =
          await sl<InvoicePdfService>().generate(invoice);
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'invoice-${Formatters.invoiceNumber(invoice.invoiceNumber)}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate PDF. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All'),
      ('draft', 'Draft'),
      ('sent', 'Sent'),
      ('paid', 'Paid'),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: filters.map((f) {
          final (value, label) = f;
          final isSelected = selected == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkSent;
  final VoidCallback onDelete;
  final VoidCallback onExportPdf;

  const _InvoiceCard({
    required this.invoice,
    required this.onMarkPaid,
    required this.onMarkSent,
    required this.onDelete,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStatus = invoice.isOverdue ? 'overdue' : invoice.status;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.invoiceNumber(invoice.invoiceNumber),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      invoice.clientName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              StatusBadge(effectiveStatus),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.formatCurrency(invoice.total, invoice.currency),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: invoice.isPaid ? AppTheme.successColor : null,
                    ),
                  ),
                  Text(
                    'Due ${Formatters.formatDate(invoice.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: invoice.isOverdue ? AppTheme.errorColor : Colors.grey,
                      fontWeight: invoice.isOverdue ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (invoice.isDraft)
                    TextButton(
                      onPressed: onMarkSent,
                      child: const Text('Mark Sent'),
                    )
                  else if (invoice.isSent || invoice.isOverdue)
                    ElevatedButton(
                      onPressed: onMarkPaid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Mark Paid'),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                      if (v == 'pdf') onExportPdf();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Row(children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Export PDF'),
                        ]),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
