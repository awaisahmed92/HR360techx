/// Symbol shown in front of salary amounts. USD is `$`, not the letters PKR or USD.
String moneySymbol(String? code) {
  switch ((code ?? '').trim().toUpperCase()) {
    case '':
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'CAD':
      return r'CA$';
    case 'AED':
      return 'AED ';
    case 'CHF':
      return 'CHF ';
    case 'SAR':
      return 'SAR ';
    default:
      return '${code!.trim().toUpperCase()} ';
  }
}

String moneyLabel(String? code) {
  switch ((code ?? '').trim().toUpperCase()) {
    case '':
    case 'USD':
      return r'US Dollar ($)';
    case 'EUR':
      return 'Euro (€)';
    case 'GBP':
      return 'British Pound (£)';
    case 'AED':
      return 'UAE Dirham (AED)';
    case 'CAD':
      return r'Canadian Dollar (CA$)';
    case 'CHF':
      return 'Swiss Franc (CHF)';
    case 'SAR':
      return 'Saudi Riyal (SAR)';
    case 'PKR':
      return 'Pakistani Rupee (PKR)';
    default:
      return (code ?? 'USD').trim().toUpperCase();
  }
}
