class Currencies {
  static const Map<String, String> currencyMap = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'EGP': 'E£',
    'SAR': 'SR',
    'AED': 'AED',
    'JPY': '¥',
    'CNY': '¥',
    'INR': '₹',
  };

  static const Map<String, List<String>> currencyKeywords = {
    'USD': ['dollar', 'dollars', 'usd', '\$'],
    'EUR': ['euro', 'euros', 'eur', '€'],
    'GBP': ['pound', 'pounds', 'gbp', '£'],
    'EGP': ['جنيه', 'جنيهات', 'egp', 'egyptian pound'],
    'SAR': ['ريال', 'riyal', 'sar', 'saudi riyal'],
    'AED': ['درهم', 'dirham', 'aed', 'uae dirham'],
    'JPY': ['yen', 'jpy', '¥'],
    'CNY': ['yuan', 'cny', '¥'],
    'INR': ['rupee', 'rupees', 'inr', '₹'],
  };

  static String? detectCurrency(String text) {
    final lowerText = text.toLowerCase();
    for (final entry in currencyKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return 'USD'; // Default to USD
  }

  static String getSymbol(String currencyCode) {
    return currencyMap[currencyCode] ?? currencyCode;
  }
}
