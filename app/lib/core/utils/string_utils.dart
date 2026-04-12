class StringUtils {

  static String truncate(String? text, int maxLength, {bool addEllipsis = true}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    final truncated = text.substring(0, maxLength);
    return addEllipsis ? '$truncated...' : truncated;
  }

  static String formatHash(String? hash, {int startLen = 8, int endLen = 8}) {
    if (hash == null || hash.isEmpty) return '';
    if (hash.length <= (startLen + endLen)) return hash;
    return '${hash.substring(0, startLen)}...${hash.substring(hash.length - endLen)}';
  }

  static String formatCurrency(double amount, {int decimals = 4}) {
     return '\$${amount.toStringAsFixed(decimals)}';
  }
}
