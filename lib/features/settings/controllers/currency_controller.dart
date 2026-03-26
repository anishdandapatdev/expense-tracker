import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple class to hold the currency data
class Currency {
  final String name;
  final String code;
  final String symbol;

  const Currency({required this.name, required this.code, required this.symbol});
}

// Global list of supported currencies
const List<Currency> appCurrencies = [
  Currency(name: 'Indian Rupee', code: 'INR', symbol: '₹'),
  Currency(name: 'US Dollar', code: 'USD', symbol: '\$'),
  Currency(name: 'Euro', code: 'EUR', symbol: '€'),
  Currency(name: 'British Pound', code: 'GBP', symbol: '£'),
  Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥'),
  Currency(name: 'Australian Dollar', code: 'AUD', symbol: 'A\$'),
  Currency(name: 'Canadian Dollar', code: 'CAD', symbol: 'C\$'),
];

// Provider to access the current currency anywhere in the app
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  // Defaulting to INR (₹)
  CurrencyNotifier() : super(appCurrencies[0]) {
    _loadCurrency();
  }

  static const _currencyKey = 'selected_currency_code';

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_currencyKey);
    
    if (savedCode != null) {
      state = appCurrencies.firstWhere(
        (c) => c.code == savedCode,
        orElse: () => appCurrencies[0],
      );
    }
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }
}