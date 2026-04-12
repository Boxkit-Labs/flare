class StringUtils {
  /// Safely truncates a string to [maxLength].
  /// If the string is shorter than [maxLength], returns the original string.
  /// If [addEllipsis] is true, adds '...' to the end if truncated.
  static String truncate(String? text, int maxLength, {bool addEllipsis = true}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    final truncated = text.substring(0, maxLength);
    return addEllipsis ? '$truncated...' : truncated;
  }

  /// Formats a hash or address showing only the start and end.
  /// Example: 0x1234...efgh
  static String formatHash(String? hash, {int startLen = 8, int endLen = 8}) {
    if (hash == null || hash.isEmpty) return '';
    if (hash.length <= (startLen + endLen)) return hash;
    return '${hash.substring(0, startLen)}...${hash.substring(hash.length - endLen)}';
  }
}
