/// Ghana Number Plate Validation.
///
/// Validates and normalizes Ghana vehicle registration plates.
/// Modern format (2009+): XX-NNNN-YY (Region-Number(1-4 digits)-Year).
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
  /// Plate format: 2 letters, optional separator, 1-4 digits,
  /// optional separator, 2 alphanumeric chars (digits or letters for older plates).
  static final RegExp _plateRegex = RegExp(
    r'^([A-Z]{2})[\s\-]?(\d{1,4})[\s\-]?([A-Z0-9]{2})$',
    caseSensitive: false,
  );

  /// All known DVLA region codes (including supplemental codes).
  static const Set<String> validRegions = {
    // Ashanti
    'AC', 'AE', 'AK', 'AP', 'AS', 'AW',
    // Bono / Brong Ahafo
    'BA', 'BR', 'BW',
    // Bono East
    'BT',
    // Ahafo
    'AH',
    // Central
    'CR',
    // Eastern
    'EN', 'ER', 'ES',
    // Greater Accra (including supplementals)
    'GA', 'GB', 'GC', 'GE', 'GG', 'GH', 'GL', 'GM', 'GN',
    'GR', 'GS', 'GT', 'GW', 'GX', 'GY',
    // Northern
    'NR',
    // North East
    'NE',
    // Savannah
    'SV',
    // Upper East
    'UE',
    // Upper West
    'UW',
    // Volta (including supplementals)
    'VA', 'VD', 'VR',
    // Oti
    'OR',
    // Western (including supplementals)
    'WR', 'WT',
    // Western North
    'WN',
    // Government / Special
    'GV', 'CD', 'CC',
    // Services (Armed Forces, Police, Fire, Prisons)
    'GP', 'FS', 'PS',
  };

  static const Map<String, String> regionNames = {
    // Ashanti
    'AC': 'Ashanti', 'AE': 'Ashanti', 'AK': 'Ashanti',
    'AP': 'Ashanti', 'AS': 'Ashanti', 'AW': 'Ashanti',
    // Bono / Brong Ahafo
    'BA': 'Bono', 'BR': 'Bono', 'BW': 'Bono',
    // Bono East
    'BT': 'Bono East',
    // Ahafo
    'AH': 'Ahafo',
    // Central
    'CR': 'Central',
    // Eastern
    'EN': 'Eastern', 'ER': 'Eastern', 'ES': 'Eastern',
    // Greater Accra
    'GA': 'Greater Accra', 'GB': 'Greater Accra', 'GC': 'Greater Accra',
    'GE': 'Greater Accra', 'GG': 'Greater Accra', 'GH': 'Greater Accra',
    'GL': 'Greater Accra', 'GM': 'Greater Accra', 'GN': 'Greater Accra',
    'GR': 'Greater Accra', 'GS': 'Greater Accra', 'GT': 'Greater Accra',
    'GW': 'Greater Accra', 'GX': 'Greater Accra', 'GY': 'Greater Accra',
    // Northern
    'NR': 'Northern',
    // North East
    'NE': 'North East',
    // Savannah
    'SV': 'Savannah',
    // Upper East
    'UE': 'Upper East',
    // Upper West
    'UW': 'Upper West',
    // Volta
    'VA': 'Volta', 'VD': 'Volta', 'VR': 'Volta',
    // Oti
    'OR': 'Oti',
    // Western
    'WR': 'Western', 'WT': 'Western',
    // Western North
    'WN': 'Western North',
    // Government / Special
    'GV': 'Government', 'CD': 'Corps Diplomatique', 'CC': 'Consular Corps',
    // Services
    'GP': 'Ghana Police', 'FS': 'Fire Service', 'PS': 'Prisons Service',
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
        'Expected format: GR-1234-24',
      );
    }

    final region = match.group(1)!;
    final number = match.group(2)!;
    final suffix = match.group(3)!;

    if (!validRegions.contains(region)) {
      return PlateValidationResult.invalid('Unknown region: $region');
    }

    // Accept any 2-char alphanumeric suffix without year validation.
    // Older plates (pre-2009) used letter codes, modern plates use
    // 2-digit years. We don't reject future years — they'll become
    // valid naturally.

    final formatted = '$region-$number-$suffix';
    return PlateValidationResult.valid(formatted, region);
  }

  /// Quick check if a string looks like a valid plate.
  static bool isValidFormat(String input) => validate(input).isValid;

  /// Normalize plate to consistent format (XX-NNNN-YY).
  static String? normalize(String input) => validate(input).formatted;
}
