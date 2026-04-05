//expense_tracker\lib\features\budgets\controllers\budget_controller.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/notifications/controllers/notification_controller.dart';
import 'package:expense_tracker/features/budgets/controllers/budget_controller.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';



class AddTransactionScreen extends HookConsumerWidget {
  static const String routeName = '/add-transaction';
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
   final amountController = useTextEditingController(
        text: existingTransaction != null ? existingTransaction!.amount.toString() : "0");
    final descriptionController = useTextEditingController(
        text: existingTransaction?.note ?? "");
        
    final selectedType = useState<String>(
        existingTransaction != null 
            ? (existingTransaction!.type == 'income' ? 'Income' : 'Expense') 
            : 'Expense');
    final selectedDate = useState<DateTime>(existingTransaction?.date ?? DateTime.now());
    final selectedCategory = useState<String?>(existingTransaction?.category ?? 'Food');
    final selectedAccount = useState<String?>(existingTransaction?.account ?? 'Cash');
    final isRepeating = useState<bool>(false);
    final isSaving = useState<bool>(false);
    final currentCurrency = ref.watch(currencyProvider);

    final accentColor = selectedType.value == 'Expense' ? const Color(0xFFEF4444) : const Color(0xFF007A3D);

    final categories = ['Food & Drink', 'Transport', 'Shopping', 'Entertainment', 'Utilities', 'Salary', 'Other'];
    final accounts = ['Cash', 'Bank', 'Credit Card'];

    void saveTransaction() async {
      if (isSaving.value) return; // Prevent double-tap
      if (formKey.currentState!.validate()) {
        isSaving.value = true;
        final amount = double.tryParse(amountController.text) ?? 0.0;
        final user = ref.read(authStateProvider).value;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to add a transaction')),
          );
          isSaving.value = false;
          return;
        }

        final transactionType = selectedType.value.toLowerCase();

        final transaction = TransactionModel(
          // Keep the existing ID if editing, otherwise generate a new one
          id: existingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          type: transactionType,
          amount: amount,
          category: selectedCategory.value ?? 'Other',
          account: selectedAccount.value ?? 'Cash',
          date: selectedDate.value,
          note: descriptionController.text,
        );

        try {
         if (existingTransaction != null) {
            ref.read(transactionControllerProvider).updateTransaction(transaction);
          } else {
            ref.read(transactionControllerProvider).addTransaction(transaction);
          }

          // Budget Alert Check: Fire notification if expense pushes category past 80%
          if (transactionType == 'expense') {
            final budgetProgressAsync = ref.read(budgetProgressProvider);
            final budgetList = budgetProgressAsync.valueOrNull ?? [];
            for (final bp in budgetList) {
              if (bp.budget.category == transaction.category ||
                  (bp.budget.category == 'Food & Drink' && transaction.category == 'Food')) {
                ref.read(notificationSettingsProvider.notifier).checkBudgetAndNotify(
                  category: bp.budget.category,
                  spent: bp.spentAmount + transaction.amount,
                  limit: bp.budget.limitAmount,
                );
                break;
              }
            }
          }

          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(existingTransaction != null ? 'Transaction updated!' : 'Transaction added!')),
            );
          }
        } catch (e) {
          isSaving.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      }
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          existingTransaction != null ? "Edit Transaction" : "Add Transaction",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildTypeSegmentedToggle(selectedType, accentColor),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _buildAmountCard(
                amountController, 
                currentCurrency, 
                selectedType, 
                isDarkMode,
              ),
              const SizedBox(height: 15),
              _buildDetailsCard(
                context: context,
                descriptionController: descriptionController,
                categories: categories,
                selectedCategory: selectedCategory,
                selectedDate: selectedDate,
                accentColor: accentColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 15),
              _buildPaymentMethodCard(
                accounts: accounts,
                selectedAccount: selectedAccount,
                isRepeating: isRepeating,
                accentColor: accentColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 30),
              _buildSubmitButton(saveTransaction, accentColor, isSaving.value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegmentedToggle(ValueNotifier<String> selectedType, Color accentColor) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'Expense',
          label: Text('Expense'),
          icon: Icon(Icons.outbound, size: 18),
        ),
        ButtonSegment(
          value: 'Income',
          label: Text('Income'),
          icon: Icon(Icons.call_received, size: 18),
        ),
      ],
      selected: {selectedType.value},
      onSelectionChanged: (newSelection) {
        selectedType.value = newSelection.first;
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white.withValues(alpha: 0.3);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return Colors.white;
        }),
        side: WidgetStateProperty.all(BorderSide.none),
      ),
    );
  }

  Widget _buildAmountCard(
    TextEditingController amountController,
    Currency currentCurrency,
    ValueNotifier<String> selectedType,
    bool isDarkMode,
  ) {
    final amountColor = selectedType.value == 'Expense' ? const Color(0xFFEF4444) : const Color(0xFF007A3D);
    final cardBgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final hintColor = isDarkMode ? Colors.grey.shade400 : Colors.grey[600];

    return Card(
      color: cardBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Set Amount",
              style: TextStyle(color: hintColor, fontSize: 14),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: '${currentCurrency.symbol} ',
                prefixStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.isEmpty || double.tryParse(value) == 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard({
    required BuildContext context,
    required TextEditingController descriptionController,
    required List<String> categories,
    required ValueNotifier<String?> selectedCategory,
    required ValueNotifier<DateTime> selectedDate,
    required Color accentColor,
    required bool isDarkMode,
  }) {
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final cardBgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final itemBgColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey[600];
    final textColor = isDarkMode ? Colors.grey.shade300 : Colors.grey[700];
    final hintColor = isDarkMode ? Colors.grey.shade500 : Colors.grey;

    return Card(
      color: cardBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: descriptionController,
              style: TextStyle(fontSize: 16, color: titleColor),
              decoration: _buildInputDecoration(
                hintText: "Enter Description",
                icon: Icons.edit_note,
                hintColor: hintColor,
              ),
            ),
            const Divider(),
            Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory.value == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => selectedCategory.value = category,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: itemBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? accentColor : borderColor,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                           Icon(
                              CategoryUtils.getIcon(category),
                              size: 36,
                              color: isSelected ? accentColor : iconColor,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? accentColor : textColor,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.value,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) selectedDate.value = picked;
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: hintColor),
                    const SizedBox(width: 15),
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate.value),
                      style: TextStyle(fontSize: 16, color: titleColor),
                    ),
                    const Spacer(),
                    Text(
                      "Set Date",
                      style: TextStyle(color: hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required List<String> accounts,
    required ValueNotifier<String?> selectedAccount,
    required ValueNotifier<bool> isRepeating,
    required Color accentColor,
    required bool isDarkMode,
  }) {
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final cardBgColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final itemBgColor = isDarkMode ? Colors.grey.shade800 : Colors.grey[100];
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey[600];
    final textColor = isDarkMode ? Colors.grey.shade300 : Colors.grey[700];

    return Card(
      color: cardBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Method",
              style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: accounts.map((account) {
                  final isSelected = selectedAccount.value == account;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => selectedAccount.value = account,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : itemBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? null : Border.all(color: borderColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAccountIcon(account),
                              size: 32,
                              color: isSelected ? Colors.white : iconColor,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              account,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.white : textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            Row(
              children: [
                Text(
                  "Repeat",
                  style: TextStyle(fontSize: 16, color: titleColor),
                ),
                const Spacer(),
                Switch(
                  value: isRepeating.value,
                  onChanged: (val) => isRepeating.value = val,
                  activeThumbColor: Colors.blue[600],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(VoidCallback onPressed, Color accentColor, bool isSaving) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                existingTransaction != null ? "UPDATE" : "CONTINUE",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    required Color hintColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor),
      prefixIcon: Icon(icon, color: hintColor),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }


  IconData _getAccountIcon(String account) {
    switch (account) {
      case 'Cash':
        return Icons.payments;
      case 'Bank':
        return Icons.account_balance;
      case 'Credit Card':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}