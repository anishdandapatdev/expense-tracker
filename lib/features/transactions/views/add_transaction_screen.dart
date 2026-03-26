//expense_tracker\lib\features\budgets\controllers\budget_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Run: flutter pub add uuid
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
// We use ConsumerStatefulWidget to access Riverpod and manage local form state
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // Local state for the form
  String _selectedType = 'expense'; // default to expense
  final String _selectedCategory = 'Food'; 
  final String _selectedAccount = 'Cash';
  final DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return; 

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

    // 1. GET THE REAL LOGGED-IN USER
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You must be logged in to save.')),
      );
      return;
    }

    // 2. USE THE REAL UID
    final newTransaction = TransactionModel(
      id: const Uuid().v4(), 
      userId: user.uid, // <-- CHANGED THIS LINE
      type: _selectedType,
      amount: amount,
      category: _selectedCategory,
      account: _selectedAccount,
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    try {
      await ref.read(transactionControllerProvider).addTransaction(newTransaction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction Saved!')),
        );
        context.pop(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () => context.pop(),
),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Segmented Control for Income/Expense (Simplified for now)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: _selectedType == 'expense',
                  selectedColor: Colors.red.shade100,
                  onSelected: (bool selected) {
                    setState(() => _selectedType = 'expense');
                  },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _selectedType == 'income',
                  selectedColor: Colors.green.shade100,
                  onSelected: (bool selected) {
                    setState(() => _selectedType = 'income');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 16),

            // Note Input
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            
            const Spacer(),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveTransaction,
                child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}