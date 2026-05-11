// lib/shared/utils/input_formatter.dart

class InputFormatter {
  /// Format custom user input (vitamins, diseases, foods, etc.)
  /// Applies capitalization and replaces common slang with proper medical terms.
  static String formatHealthData(String input) {
    if (input.trim().isEmpty) return '';

    var result = input.trim().toLowerCase();

    // Замена витаминов и БАДов
    const Map<String, String> replacements = {
      'витамин ц': 'Витамин C',
      'витамин с': 'Витамин C',
      'ц': 'C',
      'д3': 'D3',
      'витамин д3': 'Витамин D3',
      'б12': 'B12',
      'витамин б12': 'Витамин B12',
      'омега 3': 'Омега-3',
      'омега-3': 'Омега-3',
      'витамин а': 'Витамин A',
      'витамин е': 'Витамин E',
    };

    if (replacements.containsKey(result)) {
      return replacements[result]!;
    }

    // Capitalize first letter if no specific replacement
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    // Replace basic inline phonetic replacements, e.g. "какой-то витамин ц"
    // Using RegExp for word boundaries
    result = result.replaceAll(RegExp(r'\bвитамин ц\b', caseSensitive: false), 'Витамин C');
    result = result.replaceAll(RegExp(r'\bд3\b', caseSensitive: false), 'D3');
    result = result.replaceAll(RegExp(r'\bвитамин д3\b', caseSensitive: false), 'Витамин D3');
    result = result.replaceAll(RegExp(r'\bб12\b', caseSensitive: false), 'B12');
    result = result.replaceAll(RegExp(r'\bвитамин б12\b', caseSensitive: false), 'Витамин B12');
    result = result.replaceAll(RegExp(r'\bомега 3\b', caseSensitive: false), 'Омега-3');

    return result;
  }
}
