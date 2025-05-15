import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:inventory_control/services/service_locator.dart';
import 'package:uuid/uuid.dart';

class MovementFormScreen extends StatefulWidget {
  const MovementFormScreen({super.key});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ServiceLocator.instance.databaseService.getAllProducts();
      setState(() => _products = products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onProductSelected(String? productId) {
    if (productId != null) {
      setState(() {
        _selectedProduct = _products.firstWhere((p) => p['id'] == productId);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final values = _formKey.currentState!.value;
        final now = DateTime.now().millisecondsSinceEpoch;
        final user = await ServiceLocator.instance.authService.getCurrentUser();
        
        if (user == null) {
          throw Exception('User not authenticated');
        }

        final movementData = {
          'id': const Uuid().v4(),
          'product_id': values['product_id'],
          'type': values['type'],
          'quantity': num.parse(values['quantity'].toString()),
          'date': values['date'] is DateTime ? 
              values['date'].millisecondsSinceEpoch : now,
          'reason': values['reason'],
          'reference': values['reference'],
          'notes': values['notes'],
          'created_by': user['id'],
          'created_at': now,
          'updated_at': now,
        };

        // Update product quantity
        final product = _selectedProduct!;
        final currentQuantity = product['current_quantity'] as num;
        final movementQuantity = movementData['quantity'] as num;
        final newQuantity = movementData['type'] == 'in' 
            ? currentQuantity + movementQuantity
            : currentQuantity - movementQuantity;

        if (movementData['type'] == 'out' && newQuantity < 0) {
          throw Exception('Insufficient stock');
        }

        // Update product
        await ServiceLocator.instance.databaseService.updateProduct({
          ...product,
          'current_quantity': newQuantity,
          'updated_at': now,
        });

        // Save movement
        await ServiceLocator.instance.databaseService.insertInventoryMovement(movementData);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movement recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState?.reset();
        setState(() => _selectedProduct = null);
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording movement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Movement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderDropdown<String>(
                name: 'product_id',
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                items: _products.map((product) => DropdownMenuItem<String>(
                  value: product['id'],
                  child: Text(product['name']),
                )).toList(),
                onChanged: _onProductSelected,
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stock: ${_selectedProduct!['current_quantity']} ${_selectedProduct!['unit_of_measurement']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SKU: ${_selectedProduct!['sku']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'type',
                decoration: const InputDecoration(
                  labelText: 'Movement Type',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                items: const [
                  DropdownMenuItem(
                    value: 'in',
                    child: Text('IN'),
                  ),
                  DropdownMenuItem(
                    value: 'out',
                    child: Text('OUT'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'quantity',
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.min(0),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'date',
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(),
                ),
                initialValue: DateTime.now(),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown<String>(
                name: 'reason',
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
                items: const [
                  DropdownMenuItem(
                    value: 'purchase',
                    child: Text('Purchase'),
                  ),
                  DropdownMenuItem(
                    value: 'sale',
                    child: Text('Sale'),
                  ),
                  DropdownMenuItem(
                    value: 'return',
                    child: Text('Return'),
                  ),
                  DropdownMenuItem(
                    value: 'adjustment',
                    child: Text('Adjustment'),
                  ),
                  DropdownMenuItem(
                    value: 'damage',
                    child: Text('Damage'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'reference',
                decoration: const InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'notes',
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Record Movement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 