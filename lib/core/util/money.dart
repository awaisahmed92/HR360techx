import 'package:intl/intl.dart';

/// One payroll currency. The company (or an employee's pay record) stores the ISO code.
/// Screens look up the symbol and decimals from that code. They do not hardcode `$`.
class PayCurrency {
  const PayCurrency(this.code, this.name);
  final String code;
  final String name;
}

/// Currencies a global payroll company usually offers. Any other ISO code still formats.
const payCurrencies = <PayCurrency>[
  PayCurrency('USD', 'US Dollar'),
  PayCurrency('EUR', 'Euro'),
  PayCurrency('GBP', 'British Pound'),
  PayCurrency('AED', 'UAE Dirham'),
  PayCurrency('SAR', 'Saudi Riyal'),
  PayCurrency('CAD', 'Canadian Dollar'),
  PayCurrency('AUD', 'Australian Dollar'),
  PayCurrency('CHF', 'Swiss Franc'),
  PayCurrency('JPY', 'Japanese Yen'),
  PayCurrency('CNY', 'Chinese Yuan'),
  PayCurrency('INR', 'Indian Rupee'),
  PayCurrency('SGD', 'Singapore Dollar'),
  PayCurrency('HKD', 'Hong Kong Dollar'),
  PayCurrency('NZD', 'New Zealand Dollar'),
  PayCurrency('QAR', 'Qatari Riyal'),
  PayCurrency('KWD', 'Kuwaiti Dinar'),
  PayCurrency('BHD', 'Bahraini Dinar'),
  PayCurrency('OMR', 'Omani Rial'),
  PayCurrency('ZAR', 'South African Rand'),
  PayCurrency('SEK', 'Swedish Krona'),
  PayCurrency('NOK', 'Norwegian Krone'),
  PayCurrency('DKK', 'Danish Krone'),
  PayCurrency('MXN', 'Mexican Peso'),
  PayCurrency('BRL', 'Brazilian Real'),
  PayCurrency('TRY', 'Turkish Lira'),
  PayCurrency('PKR', 'Pakistani Rupee'),
];

/// Blank means the company has not chosen yet, so new organizations start on USD.
String payIso(String? code) {
  final value = (code ?? '').trim().toUpperCase();
  return value.isEmpty ? 'USD' : value;
}

NumberFormat payFormat(String? code) {
  final iso = payIso(code);
  try {
    return NumberFormat.simpleCurrency(name: iso);
  } catch (_) {
    return NumberFormat.currency(name: iso, symbol: '$iso ', decimalDigits: 2);
  }
}

String moneySymbol(String? code) => payFormat(code).currencySymbol;

String formatMoney(num? value, String? code) => payFormat(code).format(value ?? 0);

String moneyLabel(String? code) {
  final iso = payIso(code);
  var name = iso;
  for (final currency in payCurrencies) {
    if (currency.code == iso) {
      name = currency.name;
      break;
    }
  }
  return '$iso — $name (${moneySymbol(iso).trim()})';
}

List<String> payCurrencyCodes([String? current]) {
  final codes = [for (final currency in payCurrencies) currency.code];
  final extra = (current ?? '').trim().toUpperCase();
  if (extra.isNotEmpty && !codes.contains(extra)) {
    codes.insert(0, extra);
  }
  return codes;
}
