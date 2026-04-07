import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/query_model.dart';
import '../providers/auth_provider.dart';
import '../providers/query_provider.dart';

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueryProvider>().loadQueries();
    });
  }

  Future<void> _resolveQuery(QueryModel query) async {
    final noteController = TextEditingController();
    final shouldResolve = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mark query as resolved'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Resolution note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );

    if (shouldResolve != true || !mounted) {
      noteController.dispose();
      return;
    }

    try {
      await context.read<QueryProvider>().resolveQuery(
            query.id,
            resolutionNote: noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Query marked as resolved')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resolve query: $error')),
      );
    } finally {
      noteController.dispose();
    }
  }

  Widget _buildStatusChip(QueryModel query) {
    final isResolved = query.isResolved;
    return Chip(
      label: Text(
        isResolved ? 'Resolved' : 'Open',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isResolved ? Colors.green : Colors.orange,
    );
  }

  Widget _buildQueryCard(QueryModel query, bool isFarmer) {
    final cropLabel = query.cropName ?? 'Crop';
    final cropDetails = [
      if ((query.cropType ?? '').isNotEmpty) query.cropType!,
      if ((query.cropSeason ?? '').isNotEmpty) query.cropSeason!,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        cropLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (cropDetails.isNotEmpty)
                        Text(
                          cropDetails,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(query),
              ],
            ),
            if (!isFarmer) ...[
              const SizedBox(height: 12),
              Text(
                query.farmerName ?? 'Farmer',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if ((query.farmerVillage ?? '').isNotEmpty)
                Text(query.farmerVillage!),
              if ((query.farmerMobile ?? '').isNotEmpty)
                Text(query.farmerMobile!),
            ],
            const SizedBox(height: 12),
            Text(query.description),
            if ((query.resolutionNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Resolution: ${query.resolutionNote}'),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (query.createdAt != null)
                  Text(
                    'Raised: ${query.createdAt!.day}/${query.createdAt!.month}/${query.createdAt!.year}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                if (query.resolvedAt != null)
                  Text(
                    'Resolved: ${query.resolvedAt!.day}/${query.resolvedAt!.month}/${query.resolvedAt!.year}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
              ],
            ),
            if (!isFarmer && !query.isResolved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  onPressed: () => _resolveQuery(query),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Resolved'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.isFarmer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFarmer ? 'My Queries' : 'Farmer Queries'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Consumer<QueryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.queries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.queries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isFarmer
                      ? 'No queries submitted yet. Open My Crops and raise a query from a crop.'
                      : 'No farmer queries available right now.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadQueries(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.queries.length,
              itemBuilder: (context, index) {
                return _buildQueryCard(provider.queries[index], isFarmer);
              },
            ),
          );
        },
      ),
    );
  }
}
