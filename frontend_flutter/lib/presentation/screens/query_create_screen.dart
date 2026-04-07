import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/models/crop_model.dart';
import '../providers/query_provider.dart';

class QueryCreateScreen extends StatefulWidget {
  final CropModel crop;

  const QueryCreateScreen({
    required this.crop,
    super.key,
  });

  @override
  State<QueryCreateScreen> createState() => _QueryCreateScreenState();
}

class _QueryCreateScreenState extends State<QueryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<QueryProvider>().createQuery(
            cropId: widget.crop.serverId ?? widget.crop.id ?? '',
            description: _descriptionController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      Helpers.showSnackBar(context, 'Query submitted successfully');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      Helpers.showSnackBar(
        context,
        'Failed to submit query: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Crop Query'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.grass, color: Colors.white),
                ),
                title: Text(crop.cropName),
                subtitle: Text('${crop.cropType} • ${crop.season}'),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Describe the disease or issue',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  helperText:
                      'Explain the visible symptoms so the field worker can respond faster',
                ),
                maxLines: 6,
                validator: (value) =>
                    Validators.validateRequired(value, 'Description'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Query'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
