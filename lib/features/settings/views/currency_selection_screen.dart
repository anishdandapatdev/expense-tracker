import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';

class CurrencySelectionScreen extends ConsumerStatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  ConsumerState<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends ConsumerState<CurrencySelectionScreen> {
  Currency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(currencyProvider);
  }

  void _saveAndContinue() {
    if (_selectedCurrency != null) {
      ref.read(currencyProvider.notifier).setCurrency(_selectedCurrency!);
      
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Currency'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select your primary currency. This will be used for all your transactions and budgets.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: appCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = appCurrencies[index];
                  final isSelected = _selectedCurrency?.code == currency.code;

                  return ListTile(
                    leading: Text(
                      currency.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      '${currency.code} — ${currency.name}',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    subtitle: Text(
                      currency.countryName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) 
                        : Text(
                            currency.symbol,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                          ),
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency;
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveAndContinue,
                  child: const Text('Continue to Dashboard', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable bottom sheet currency picker with search.
/// Call [showCurrencyPickerSheet] from anywhere to open it.
Future<void> showCurrencyPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CurrencyPickerSheet(),
  );
}

class _CurrencyPickerSheet extends ConsumerStatefulWidget {
  const _CurrencyPickerSheet();

  @override
  ConsumerState<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends ConsumerState<_CurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = List.from(appCurrencies);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredCurrencies = List.from(appCurrencies);
      } else {
        _filteredCurrencies = appCurrencies.where((c) {
          return c.name.toLowerCase().contains(q) ||
              c.code.toLowerCase().contains(q) ||
              c.countryName.toLowerCase().contains(q) ||
              c.symbol.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCurrency = ref.watch(currencyProvider);

    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final searchBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final symbolColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle bar ─────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ─── Title Row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
            child: Row(
              children: [
                Text(
                  'Choose Currency',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: subtitleColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ─── Search bar ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: TextStyle(fontSize: 15, color: titleColor),
                decoration: InputDecoration(
                  hintText: 'Search Currency',
                  hintStyle: TextStyle(color: subtitleColor, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: subtitleColor, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: subtitleColor, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ─── Currency list ──────────────────────────────
          Expanded(
            child: _filteredCurrencies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: subtitleColor),
                        const SizedBox(height: 12),
                        Text(
                          'No currencies found',
                          style: TextStyle(color: subtitleColor, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredCurrencies.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 20,
                      color: dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      final isSelected = currentCurrency.code == currency.code;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Text(
                          currency.flag,
                          style: const TextStyle(fontSize: 30),
                        ),
                        title: Text(
                          currency.code,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : titleColor,
                          ),
                        ),
                        subtitle: Text(
                          currency.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              )
                            : Text(
                                currency.symbol,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: symbolColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          ref.read(currencyProvider.notifier).setCurrency(currency);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),

          // ─── Close button ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF87171),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}