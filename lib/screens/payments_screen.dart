import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/db_helper.dart';
import '../services/pdf_generator.dart';
import '../models/payment.dart';
import 'camera_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final payments =
          await _dbHelper.getPaymentsByUserId(1); // replace with actual userId
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payments: $e')),
      );
    }
  }

  Future<void> _updatePaymentStatus(int id, String newStatus) async {
    try {
      await _dbHelper.updatePaymentStatus(id, newStatus);
      await _loadPayments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment marked as $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating payment status: $e')),
      );
    }
  }

  Future<void> _generateReceipt(Payment payment) async {
    try {
      await PdfGenerator.generateReceipt(payment);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt generated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating receipt: $e')),
      );
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'mobile':
        return '💰 Mobile Payment';
      case 'card':
        return '💳 Card Payment';
      case 'bank':
        return '🏦 Bank Transfer';
      default:
        return 'Other';
    }
  }

  void _showPaymentOptions(Payment payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Manage Payment',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple[700])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(45)),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Complete'),
                onPressed: () async {
                  await _updatePaymentStatus(payment.id!, 'completed');
                  await _generateReceipt(payment);
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(45)),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Payment'),
                onPressed: () async {
                  try {
                    await _dbHelper.deletePayment(payment.id!);
                    await _loadPayments();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment deleted')),
                    );
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting payment: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _payments.isEmpty
          ? const Center(
              child: Text(
                'No payments yet.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                final statusColor = payment.status == 'completed'
                    ? Colors.green
                    : payment.status == 'failed'
                        ? Colors.red
                        : Colors.orange;

                return GestureDetector(
                  onTap: () async {
                    if (payment.status == 'pending') {
                      _showPaymentOptions(payment);
                    } else if (payment.status == 'completed') {
                      await _generateReceipt(payment);
                    }
                  },
                  child: Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          payment.type == 'electricity'
                              ? '⚡'
                              : payment.type == 'water'
                                  ? '💧'
                                  : '', // Gas removed
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        '${payment.type.toUpperCase()} - ETB ${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(_getPaymentMethodName(payment.paymentMethod)),
                          Text(
                            '${payment.date.toString().split(' ')[0]} - ${payment.status}',
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: payment.status == 'completed'
                              ? Colors.green.withOpacity(0.2)
                              : payment.status == 'failed'
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payment.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: AddPaymentForm(
                  onPaymentAdded: () => _loadPayments(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ================= Add Payment Form =================

class AddPaymentForm extends StatefulWidget {
  final VoidCallback onPaymentAdded;
  const AddPaymentForm({super.key, required this.onPaymentAdded});

  @override
  State<AddPaymentForm> createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends State<AddPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _passcodeController = TextEditingController();

  String _selectedUtility = 'electricity';
  String _selectedMethod = 'mobile';
  XFile? _idPhoto;

  final DBHelper _dbHelper = DBHelper();

  bool _verifyIDWithPasscode(XFile idPhoto, String passcode) {
    return passcode == '1234';
  }

  Future<void> _pickID() async {
    try {
      final imagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );

      if (imagePath == null || imagePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ID & Face verification required to proceed')),
        );
        return;
      }

      setState(() {
        _idPhoto = XFile(imagePath);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID captured! Enter passcode to verify.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing ID: $e')),
      );
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      if (_idPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You must scan your ID and face before adding payment')),
        );
        return;
      }

      if (!_verifyIDWithPasscode(_idPhoto!, _passcodeController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Verification failed: Passcode does not match ID')),
        );
        return;
      }

      final userId = 1; // replace with actual user id
      final payment = Payment(
        id: null,
        userId: userId,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        type: _selectedUtility,
        paymentMethod: _selectedMethod,
        date: DateTime.now(),
        status: 'pending',
        notes: _passcodeController.text,
      );

      try {
        await _dbHelper.insertPayment(payment);

        widget.onPaymentAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving payment: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (ETB)',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter amount' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedUtility,
              decoration: const InputDecoration(
                labelText: 'Select Utility',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'electricity', child: Text('Electricity')),
                DropdownMenuItem(value: 'water', child: Text('Water')),
                // Gas removed
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedUtility = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedMethod = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passcode to view ID',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter passcode' : null,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan ID & Face'),
              onPressed: _pickID,
            ),
            if (_idPhoto != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.file(
                  File(_idPhoto!.path),
                  height: 120,
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _savePayment,
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
