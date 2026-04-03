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
    // Initialize with the current state value
    _selectedCurrency = ref.read(currencyProvider);
  }

  void _saveAndContinue() {
    if (_selectedCurrency != null) {
      ref.read(currencyProvider.notifier).setCurrency(_selectedCurrency!);
      
      // If we pushed this screen from the Home Screen header, simply pop it.
      // If we came here from the initial login flow natively, go to Dashboard.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Currency'),
        automaticallyImplyLeading: false, // Prevents going back to login
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
                    leading: CircleAvatar(
                      backgroundColor: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).colorScheme.surface,
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${currency.name} (${currency.code})'),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) 
                        : null,
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