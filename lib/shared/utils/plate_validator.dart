/// Ghana Number Plate Validation.
///
/// Validates and normalizes Ghana vehicle registration plates.
/// Format: XX-XXXX-XX (Region-Number-Year).
library;

/// Result of plate number validation.
class PlateValidationResult {
  final bool isValid;
  final String? formatted;
  final String? region;
  final String? error;

  const PlateValidationResult.valid(this.formatted, this.region)
      : isValid = true,
        error = null;

  const PlateValidationResult.invalid(this.error)
      : isValid = false,
        formatted = null,
        region = null;
}

class PlateValidator {
  /// 2 letters, optional separator, 4-5 digits, optional separator, 2 digits.
  static final RegExp _plateRegex = RegExp(
    r'^([A-Z]{2})[\s\-]?(\d{4,5})[\s\-]?(\d{2})$',
    caseSensitive: false,
  );

  static const Set<String> validRegions = {
    'GR', 'GA', 'AS', 'BA', 'AH', 'BO', 'BE', 'CR', 'ER',
    'NR', 'NE', 'SV', 'UE', 'UW', 'VR', 'OR', 'WR', 'WN',
    'GT', 'GV', 'CD', 'CC',
  };

  static const Map<String, String> regionNames = {
    'GR': 'Greater Accra',
    'GA': 'Greater Accra (old)',
    'AS': 'Ashanti',
    'BA': 'Brong Ahafo',
    'AH': 'Ahafo',
    'BO': 'Bono',
    'BE': 'Bono East',
    'CR': 'Central',
    'ER': 'Eastern',
    'NR': 'Northern',
    'NE': 'North East',
    'SV': 'Savannah',
    'UE': 'Upper East',
    'UW': 'Upper West',
    'VR': 'Volta',
    'OR': 'Oti',
    'WR': 'Western',
    'WN': 'Western North',
    'GT': 'Government',
    'GV': 'Government',
    'CD': 'Corps Diplomatique',
    'CC': 'Consular Corps',
  };

  /// Validates and normalizes a plate number.
  static PlateValidationResult validate(String input) {
    final normalized = input.toUpperCase().trim();

    if (normalized.isEmpty) {
      return const PlateValidationResult.invalid('Enter a plate number');
    }

    final match = _plateRegex.firstMatch(normalized);
    if (match == null) {
      return const PlateValidationResult.invalid(
        'Expected format: GR-1234-21',
      );
    }

    final region = match.group(1)!;
    final number = match.group(2)!;
    final year = match.group(3)!;

    if (!validRegions.contains(region)) {
      return PlateValidationResult.invalid('Unknown region: $region');
    }

    final yearNum = int.parse(year);
    if (yearNum < 90 && yearNum > 30) {
      return PlateValidationResult.invalid('Invalid year: $year');
    }

    final formatted = '$region-$number-$year';
    return PlateValidationResult.valid(formatted, region);
  }

  /// Quick check if a string looks like a valid plate.
  static bool isValidFormat(String input) => validate(input).isValid;

  /// Normalize plate to consistent format (XX-XXXX-XX).
  static String? normalize(String input) => validate(input).formatted;
}
