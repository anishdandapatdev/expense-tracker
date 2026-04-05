import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple class to hold the currency data
class Currency {
  final String name;
  final String code;
  final String symbol;
  final String flag;
  final String countryName;

  const Currency({
    required this.name,
    required this.code,
    required this.symbol,
    required this.flag,
    required this.countryName,
  });
}

// Top 15 world currencies + India (sorted alphabetically by code)
const List<Currency> appCurrencies = [
  Currency(name: 'Australian Dollar', code: 'AUD', symbol: 'A\$', flag: '🇦🇺', countryName: 'Australia'),
  Currency(name: 'Brazilian Real', code: 'BRL', symbol: 'R\$', flag: '🇧🇷', countryName: 'Brazil'),
  Currency(name: 'Canadian Dollar', code: 'CAD', symbol: 'C\$', flag: '🇨🇦', countryName: 'Canada'),
  Currency(name: 'Swiss Franc', code: 'CHF', symbol: 'Fr', flag: '🇨🇭', countryName: 'Switzerland'),
  Currency(name: 'Chinese Yuan', code: 'CNY', symbol: '¥', flag: '🇨🇳', countryName: 'China'),
  Currency(name: 'Euro', code: 'EUR', symbol: '€', flag: '🇪🇺', countryName: 'European Union'),
  Currency(name: 'British Pound', code: 'GBP', symbol: '£', flag: '🇬🇧', countryName: 'United Kingdom'),
  Currency(name: 'Hong Kong Dollar', code: 'HKD', symbol: 'HK\$', flag: '🇭🇰', countryName: 'Hong Kong'),
  Currency(name: 'Indian Rupee', code: 'INR', symbol: '₹', flag: '🇮🇳', countryName: 'India'),
  Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥', flag: '🇯🇵', countryName: 'Japan'),
  Currency(name: 'South Korean Won', code: 'KRW', symbol: '₩', flag: '🇰🇷', countryName: 'South Korea'),
  Currency(name: 'Mexican Peso', code: 'MXN', symbol: 'Mex\$', flag: '🇲🇽', countryName: 'Mexico'),
  Currency(name: 'Norwegian Krone', code: 'NOK', symbol: 'kr', flag: '🇳🇴', countryName: 'Norway'),
  Currency(name: 'Saudi Riyal', code: 'SAR', symbol: '﷼', flag: '🇸🇦', countryName: 'Saudi Arabia'),
  Currency(name: 'Swedish Krona', code: 'SEK', symbol: 'kr', flag: '🇸🇪', countryName: 'Sweden'),
  Currency(name: 'US Dollar', code: 'USD', symbol: '\$', flag: '🇺🇸', countryName: 'United States'),
];

// Provider to access the current currency anywhere in the app
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  // Defaulting to INR (₹)
  CurrencyNotifier() : super(appCurrencies.firstWhere((c) => c.code == 'INR')) {
    _loadCurrency();
  }

  static const _currencyKey = 'selected_currency_code';

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_currencyKey);
    
    if (savedCode != null) {
      state = appCurrencies.firstWhere(
        (c) => c.code == savedCode,
        orElse: () => appCurrencies.firstWhere((c) => c.code == 'INR'),
      );
    }
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }
}