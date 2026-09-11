class NumberToWords {
  NumberToWords._();

  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  /// Converts a number to Indian Currency words (e.g., "Rupees One Lakh Twenty-Five Thousand Only")
  static String convertToIndianRupees(double amount) {
    if (amount == 0) return 'Rupees Zero Only';

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    String result = 'Rupees ${_convert(rupees)}';

    if (paise > 0) {
      result += ' and ${_convert(paise)} Paise';
    }

    return '$result Only'.trim();
  }

  static String _convert(int n) {
    if (n == 0) return '';
    if (n < 20) return _units[n];

    if (n < 100) {
      final rem = n % 10;
      return '${_tens[n ~/ 10]}${rem > 0 ? "-${_units[rem]}" : ""}'.trim();
    }

    if (n < 1000) {
      final rem = n % 100;
      return '${_units[n ~/ 100]} Hundred${rem > 0 ? " ${_convert(rem)}" : ""}'.trim();
    }

    if (n < 100000) {
      final rem = n % 1000;
      return '${_convert(n ~/ 1000)} Thousand${rem > 0 ? " ${_convert(rem)}" : ""}'.trim();
    }

    if (n < 10000000) {
      final rem = n % 100000;
      return '${_convert(n ~/ 100000)} Lakh${rem > 0 ? " ${_convert(rem)}" : ""}'.trim();
    }

    final rem = n % 10000000;
    return '${_convert(n ~/ 10000000)} Crore${rem > 0 ? " ${_convert(rem)}" : ""}'.trim();
  }
}
