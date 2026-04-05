// expense_tracker\lib\features\transactions\views\add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/notifications/controllers/notification_controller.dart';
import 'package:expense_tracker/features/budgets/controllers/budget_controller.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kAppBarColor = Color(0xFF1C1B33);
const _kExpenseColor = Color(0xFFEF4444);
const _kIncomeColor = Color(0xFF22C55E);

class AddTransactionScreen extends HookConsumerWidget {
  static const String routeName = '/add-transaction';
  final TransactionModel? existingTransaction;
  /// Pre-select 'Income' or 'Expense' when opening a new transaction record.
  final String initialType;

  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
    this.initialType = 'Expense',
  });

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final amountController = useTextEditingController(
      text: existingTransaction != null
          ? existingTransaction!.amount.toStringAsFixed(
              existingTransaction!.amount % 1 == 0 ? 0 : 2)
          : '',
    );
    final noteController =
        useTextEditingController(text: existingTransaction?.note ?? '');

    final selectedType = useState<String>(
      existingTransaction != null
          ? (existingTransaction!.type == 'income' ? 'Income' : 'Expense')
          : initialType, // use the passed-in initial type (Income/Expense)
    );
    final selectedDate =
        useState<DateTime>(existingTransaction?.date ?? DateTime.now());
    final selectedCategory =
        useState<String?>(existingTransaction?.category);
    final selectedAccount =
        useState<String?>(existingTransaction?.account ?? 'Cash');
    final isSaving = useState<bool>(false);

    final currency = ref.watch(currencyProvider);
    final isExpense = selectedType.value == 'Expense';
    final accentColor = isExpense ? _kExpenseColor : _kIncomeColor;

    // Clear category when switching type (only for new transactions)
    useEffect(() {
      if (existingTransaction == null) {
        selectedCategory.value = null;
      }
      return null;
    }, [selectedType.value]);

    // ─── Save Handler ─────────────────────────────────────────────────────────
    Future<void> saveTransaction() async {
      if (isSaving.value) return;
      if (selectedCategory.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category first')),
        );
        return;
      }
      if (!formKey.currentState!.validate()) return;

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
        id: existingTransaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        type: transactionType,
        amount: amount,
        category: selectedCategory.value ?? 'Other',
        account: selectedAccount.value ?? 'Cash',
        date: selectedDate.value,
        note: noteController.text,
      );

      try {
        if (existingTransaction != null) {
          ref.read(transactionControllerProvider).updateTransaction(transaction);
        } else {
          ref.read(transactionControllerProvider).addTransaction(transaction);
        }

        // Budget alert check
        if (transactionType == 'expense') {
          final budgetList =
              ref.read(budgetProgressProvider).valueOrNull ?? [];
          for (final bp in budgetList) {
            if (bp.budget.category == transaction.category ||
                (bp.budget.category == 'Food & Drink' &&
                    transaction.category == 'Food')) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .checkBudgetAndNotify(
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
            SnackBar(
              content: Text(existingTransaction != null
                  ? 'Transaction updated!'
                  : 'Transaction added!'),
            ),
          );
        }
      } catch (e) {
        isSaving.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    // ─── Theme helpers ────────────────────────────────────────────────────────
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF2F3F7);
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final borderColor =
        isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0);
    final labelColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      // ─── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kAppBarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          existingTransaction != null ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
      ),
      // ─── Body ─────────────────────────────────────────────────────────────
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Expense / Income Toggle ────────────────────────────
                    _TypeToggle(selectedType: selectedType),
                    const SizedBox(height: 14),

                    // ── Amount ─────────────────────────────────────────────
                    _SectionLabel('Amount', labelColor),
                    const SizedBox(height: 6),
                    _AmountField(
                      controller: amountController,
                      currency: currency,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),

                    // ── Date & Category ────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Expanded(
                          child: _DatePicker(
                            selectedDate: selectedDate,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            labelColor: labelColor,
                            titleColor: titleColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category
                        Expanded(
                          child: _CategoryPicker(
                            selectedCategory: selectedCategory,
                            selectedType: selectedType,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            labelColor: labelColor,
                            titleColor: titleColor,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Payment Method ─────────────────────────────────────
                    _SectionLabel('Payment Method', labelColor),
                    const SizedBox(height: 8),
                    _PaymentMethodRow(
                      selectedAccount: selectedAccount,
                      accentColor: accentColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // ── Tag / Note ─────────────────────────────────────────
                    _SectionLabel('Tag / Note', labelColor),
                    const SizedBox(height: 8),
                    _NoteField(
                      controller: noteController,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      labelColor: labelColor,
                      titleColor: titleColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ─── Save Button ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _SaveButton(
                onPressed: saveTransaction,
                accentColor: accentColor,
                isSaving: isSaving.value,
                isEdit: existingTransaction != null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

/// Small label above each field
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─── Type Toggle ─────────────────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final ValueNotifier<String> selectedType;
  const _TypeToggle({required this.selectedType});

  @override
  Widget build(BuildContext context) {
    final isExpense = selectedType.value == 'Expense';

    return Row(
      children: [
        // ── Expense Pill ──
        Expanded(
          child: GestureDetector(
            onTap: () => selectedType.value = 'Expense',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isExpense
                    ? _kExpenseColor
                    : _kExpenseColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _kExpenseColor,
                  width: isExpense ? 0 : 1.5,
                ),
                boxShadow: isExpense
                    ? [
                        BoxShadow(
                          color: _kExpenseColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 16,
                    color: isExpense ? Colors.white : _kExpenseColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expense',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isExpense ? Colors.white : _kExpenseColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── Income Pill ──
        Expanded(
          child: GestureDetector(
            onTap: () => selectedType.value = 'Income',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: !isExpense
                    ? _kIncomeColor
                    : _kIncomeColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _kIncomeColor,
                  width: !isExpense ? 0 : 1.5,
                ),
                boxShadow: !isExpense
                    ? [
                        BoxShadow(
                          color: _kIncomeColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 16,
                    color: !isExpense ? Colors.white : _kIncomeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Income',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: !isExpense ? Colors.white : _kIncomeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Amount Field ─────────────────────────────────────────────────────────────
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Currency currency;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;

  const _AmountField({
    required this.controller,
    required this.currency,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
        decoration: InputDecoration(
          prefixText: '${currency.symbol} ',
          prefixStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
          hintText: '0',
          hintStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: accentColor.withValues(alpha: 0.35),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        validator: (v) {
          if (v == null || v.isEmpty || (double.tryParse(v) ?? 0) == 0) {
            return 'Please enter a valid amount';
          }
          return null;
        },
      ),
    );
  }
}

// ─── Date Picker ─────────────────────────────────────────────────────────────
class _DatePicker extends StatelessWidget {
  final ValueNotifier<DateTime> selectedDate;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color labelColor;
  final Color titleColor;

  const _DatePicker({
    required this.selectedDate,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.labelColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Date', labelColor),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate.value,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) selectedDate.value = picked;
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 17, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate.value),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Category Picker ──────────────────────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final ValueNotifier<String?> selectedCategory;
  final ValueNotifier<String> selectedType;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color labelColor;
  final Color titleColor;
  final bool isDark;

  const _CategoryPicker({
    required this.selectedCategory,
    required this.selectedType,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.labelColor,
    required this.titleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasCategory = selectedCategory.value != null;
    final catName = selectedCategory.value ?? '';
    final catIcon = hasCategory ? CategoryUtils.getIcon(catName) : null;
    final catColor = hasCategory ? CategoryUtils.getColor(catName) : accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Category', labelColor),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _CategoryBottomSheet.show(
            context: context,
            selectedCategory: selectedCategory,
            isExpense: selectedType.value == 'Expense',
            isDark: isDark,
          ),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: hasCategory
                  ? cardColor
                  : accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasCategory ? borderColor : accentColor.withValues(alpha: 0.4),
                width: hasCategory ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                // Icon circle — shows grid icon as placeholder when nothing selected
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: hasCategory ? 0.15 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasCategory ? catIcon! : Icons.grid_view_rounded,
                    size: 13,
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasCategory ? catName : 'Select Category',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hasCategory ? FontWeight.w600 : FontWeight.w500,
                      color: hasCategory ? titleColor : accentColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: hasCategory ? labelColor : accentColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Category Bottom Sheet ────────────────────────────────────────────────────
class _CategoryBottomSheet {
  static void show({
    required BuildContext context,
    required ValueNotifier<String?> selectedCategory,
    required bool isExpense,
    required bool isDark,
  }) {
    final categories = isExpense
        ? CategoryUtils.expenseCategories
        : CategoryUtils.incomeCategories;

    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = query.isEmpty
              ? categories
              : categories
                  .where((c) =>
                      (c['name'] as String).toLowerCase().contains(query))
                  .toList();

          final sheetBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
          final labelCol =
              isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
          final titleCol = isDark ? Colors.white : const Color(0xFF1E293B);
          final searchBg =
              isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ──
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── Header ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleCol,
                        ),
                      ),
                      const Spacer(),
                      // Type indicator chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isExpense ? _kExpenseColor : _kIncomeColor)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpense ? 'Expense' : 'Income',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isExpense ? _kExpenseColor : _kIncomeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: titleCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search category...',
                        hintStyle: TextStyle(color: labelCol, fontSize: 14),
                        prefixIcon:
                            Icon(Icons.search_rounded, color: labelCol),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),

                // ── Grid ──
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.50,
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final cat = filtered[i];
                      final name = cat['name'] as String;
                      final icon = cat['icon'] as IconData;
                      final color = cat['color'] as Color;
                      final isSelected = selectedCategory.value == name;

                      return GestureDetector(
                        onTap: () {
                          selectedCategory.value = name;
                          Navigator.of(ctx).pop();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: color, width: 2.5)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              color.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Icon(icon, color: color, size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? color : labelCol,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Payment Method Row ───────────────────────────────────────────────────────
class _PaymentMethodRow extends StatelessWidget {
  final ValueNotifier<String?> selectedAccount;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final bool isDark;

  static const _accounts = ['Cash', 'Bank', 'Credit Card'];

  const _PaymentMethodRow({
    required this.selectedAccount,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.isDark,
  });

  IconData _icon(String account) {
    switch (account) {
      case 'Cash':
        return Icons.payments_rounded;
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'Credit Card':
        return Icons.credit_card_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unselectedBg =
        isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);
    final unselectedBorder =
        isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0);
    final unselectedIcon =
        isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8);
    final unselectedText =
        isDark ? Colors.grey.shade300 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: _accounts.map((account) {
          final isSelected = selectedAccount.value == account;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => selectedAccount.value = account,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : unselectedBg,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: unselectedBorder),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(account),
                      size: 24,
                      color: isSelected ? Colors.white : unselectedIcon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : unselectedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Note Field ───────────────────────────────────────────────────────────────
class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  final Color cardColor;
  final Color borderColor;
  final Color labelColor;
  final Color titleColor;

  const _NoteField({
    required this.controller,
    required this.cardColor,
    required this.borderColor,
    required this.labelColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 2,
        style: TextStyle(fontSize: 14, color: titleColor),
        decoration: InputDecoration(
          hintText: 'Enter a note or tag...',
          hintStyle: TextStyle(color: labelColor, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color accentColor;
  final bool isSaving;
  final bool isEdit;

  const _SaveButton({
    required this.onPressed,
    required this.accentColor,
    required this.isSaving,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
          shape: const StadiumBorder(),
          elevation: 4,
          shadowColor: accentColor.withValues(alpha: 0.4),
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                isEdit ? 'Update Transaction' : 'Save',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}