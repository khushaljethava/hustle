import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/client_model.dart';
import '../../../di/service_locator.dart';
import 'add_client_sheet.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: BlocConsumer<ClientBloc, ClientState>(
        listener: (context, state) {
          if (state is ClientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
            );
          } else if (state is ClientOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ClientLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = state is ClientLoaded
              ? state.clients
              : state is ClientOperationSuccess
                  ? state.clients
                  : <ClientModel>[];

          if (clients.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'No clients yet',
              subtitle: 'Add your first client to start tracking work',
              actionLabel: 'Add Client',
              onAction: () => _showAddClient(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _ClientCard(
              client: clients[i],
              onEdit: () => _showEditClient(context, clients[i]),
              onArchive: () => context.read<ClientBloc>().add(ArchiveClient(clients[i].id)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'clients_fab',
        onPressed: () => _showAddClient(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddClient(BuildContext context) {
    // Gate free users at 3 clients
    final state = context.read<ClientBloc>().state;
    final count = state is ClientLoaded
        ? state.clients.length
        : state is ClientOperationSuccess
            ? state.clients.length
            : 0;
    if (!sl<ProService>().isProUser && count >= AppConstants.freeClientLimit) {
      Navigator.pushNamed(context, '/paywall');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ClientBloc>(),
        child: const AddClientSheet(),
      ),
    );
  }

  void _showEditClient(BuildContext context, ClientModel client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ClientBloc>(),
        child: AddClientSheet(client: client),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _ClientCard({
    required this.client,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = client.name.split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (client.company != null)
                  Text(
                    client.company!,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                if (client.email != null)
                  Text(
                    client.email!,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatCurrency(client.defaultRate, client.currency) + '/hr',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                client.currency,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'archive') onArchive();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
            child: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
