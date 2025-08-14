/// Country data model with phone codes and formatting information
class CountryData {
  final String name;
  final String code; // ISO 3166-1 alpha-2
  final String phoneCode;
  final String flag;
  final String phoneFormat;
  final int phoneLength;
  final String phonePlaceholder;

  const CountryData({
    required this.name,
    required this.code,
    required this.phoneCode,
    required this.flag,
    required this.phoneFormat,
    required this.phoneLength,
    required this.phonePlaceholder,
  });

  /// Format phone number according to country format
  String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Apply country-specific formatting
    switch (code) {
      case 'US':
      case 'CA':
        if (digits.length >= 10) {
          return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
        }
        break;
      case 'KR':
        if (digits.length >= 10) {
          if (digits.startsWith('010') || digits.startsWith('011')) {
            return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
          }
        }
        break;
      case 'JP':
        if (digits.length >= 10) {
          return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
        }
        break;
      case 'CN':
        if (digits.length >= 11) {
          return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7, 11)}';
        }
        break;
      case 'GB':
        if (digits.length >= 10) {
          return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 10)}';
        }
        break;
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
        if (digits.length >= 10) {
          return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)}';
        }
        break;
    }
    
    // Default formatting - just add spaces every 3 digits
    if (digits.length > 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length > 3) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    
    return digits;
  }

  /// Validate phone number for this country
  bool isValidPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    switch (code) {
      case 'US':
      case 'CA':
        return digits.length == 10;
      case 'KR':
        return digits.length == 10 || digits.length == 11;
      case 'JP':
        return digits.length >= 10 && digits.length <= 11;
      case 'CN':
        return digits.length == 11;
      case 'GB':
        return digits.length >= 10 && digits.length <= 11;
      case 'DE':
        return digits.length >= 10 && digits.length <= 12;
      case 'FR':
        return digits.length == 10;
      case 'IT':
        return digits.length >= 9 && digits.length <= 11;
      case 'ES':
        return digits.length == 9;
      case 'AU':
        return digits.length == 10;
      case 'BR':
        return digits.length == 10 || digits.length == 11;
      case 'MX':
        return digits.length == 10;
      case 'IN':
        return digits.length == 10;
      case 'RU':
        return digits.length == 10;
      case 'NL':
        return digits.length == 9;
      case 'SE':
      case 'NO':
      case 'DK':
      case 'FI':
        return digits.length == 8;
      default:
        return digits.length >= 8 && digits.length <= 15;
    }
  }

  /// Get full phone number with country code
  String getFullPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return '+$phoneCode$digits';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryData &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$flag $name (+$phoneCode)';
}

/// Available countries with phone codes and formatting
class CountryService {
  static const List<CountryData> availableCountries = [
    CountryData(
      name: '미국',
      code: 'US',
      phoneCode: '1',
      flag: '🇺🇸',
      phoneFormat: '(###) ###-####',
      phoneLength: 10,
      phonePlaceholder: '(555) 123-4567',
    ),
    CountryData(
      name: '캐나다',
      code: 'CA',
      phoneCode: '1',
      flag: '🇨🇦',
      phoneFormat: '(###) ###-####',
      phoneLength: 10,
      phonePlaceholder: '(555) 123-4567',
    ),
    CountryData(
      name: '영국',
      code: 'GB',
      phoneCode: '44',
      flag: '🇬🇧',
      phoneFormat: '#### ### ###',
      phoneLength: 10,
      phonePlaceholder: '7700 900123',
    ),
    CountryData(
      name: '호주',
      code: 'AU',
      phoneCode: '61',
      flag: '🇦🇺',
      phoneFormat: '### ### ###',
      phoneLength: 10,
      phonePlaceholder: '412 345 678',
    ),
    CountryData(
      name: '독일',
      code: 'DE',
      phoneCode: '49',
      flag: '🇩🇪',
      phoneFormat: '### ### ####',
      phoneLength: 11,
      phonePlaceholder: '151 23456789',
    ),
    CountryData(
      name: '프랑스',
      code: 'FR',
      phoneCode: '33',
      flag: '🇫🇷',
      phoneFormat: '## ## ## ## ##',
      phoneLength: 10,
      phonePlaceholder: '06 12 34 56 78',
    ),
    CountryData(
      name: '일본',
      code: 'JP',
      phoneCode: '81',
      flag: '🇯🇵',
      phoneFormat: '###-####-####',
      phoneLength: 11,
      phonePlaceholder: '090-1234-5678',
    ),
    CountryData(
      name: '대한민국',
      code: 'KR',
      phoneCode: '82',
      flag: '🇰🇷',
      phoneFormat: '###-####-####',
      phoneLength: 11,
      phonePlaceholder: '010-1234-5678',
    ),
    CountryData(
      name: '브라질',
      code: 'BR',
      phoneCode: '55',
      flag: '🇧🇷',
      phoneFormat: '(##) #####-####',
      phoneLength: 11,
      phonePlaceholder: '(11) 91234-5678',
    ),
    CountryData(
      name: '멕시코',
      code: 'MX',
      phoneCode: '52',
      flag: '🇲🇽',
      phoneFormat: '### ### ####',
      phoneLength: 10,
      phonePlaceholder: '551 234 5678',
    ),
    CountryData(
      name: '인도',
      code: 'IN',
      phoneCode: '91',
      flag: '🇮🇳',
      phoneFormat: '##### #####',
      phoneLength: 10,
      phonePlaceholder: '98765 43210',
    ),
    CountryData(
      name: '중국',
      code: 'CN',
      phoneCode: '86',
      flag: '🇨🇳',
      phoneFormat: '### #### ####',
      phoneLength: 11,
      phonePlaceholder: '138 0013 8000',
    ),
    CountryData(
      name: '러시아',
      code: 'RU',
      phoneCode: '7',
      flag: '🇷🇺',
      phoneFormat: '### ###-##-##',
      phoneLength: 10,
      phonePlaceholder: '912 345-67-89',
    ),
    CountryData(
      name: '이탈리아',
      code: 'IT',
      phoneCode: '39',
      flag: '🇮🇹',
      phoneFormat: '### ### ####',
      phoneLength: 10,
      phonePlaceholder: '320 123 4567',
    ),
    CountryData(
      name: '스페인',
      code: 'ES',
      phoneCode: '34',
      flag: '🇪🇸',
      phoneFormat: '### ## ## ##',
      phoneLength: 9,
      phonePlaceholder: '612 34 56 78',
    ),
    CountryData(
      name: '네덜란드',
      code: 'NL',
      phoneCode: '31',
      flag: '🇳🇱',
      phoneFormat: '## #### ####',
      phoneLength: 9,
      phonePlaceholder: '06 1234 5678',
    ),
    CountryData(
      name: '스웨덴',
      code: 'SE',
      phoneCode: '46',
      flag: '🇸🇪',
      phoneFormat: '## ### ## ##',
      phoneLength: 8,
      phonePlaceholder: '70 123 45 67',
    ),
    CountryData(
      name: '노르웨이',
      code: 'NO',
      phoneCode: '47',
      flag: '🇳🇴',
      phoneFormat: '### ## ###',
      phoneLength: 8,
      phonePlaceholder: '412 34 567',
    ),
    CountryData(
      name: '덴마크',
      code: 'DK',
      phoneCode: '45',
      flag: '🇩🇰',
      phoneFormat: '## ## ## ##',
      phoneLength: 8,
      phonePlaceholder: '20 12 34 56',
    ),
    CountryData(
      name: '핀란드',
      code: 'FI',
      phoneCode: '358',
      flag: '🇫🇮',
      phoneFormat: '## ### ####',
      phoneLength: 8,
      phonePlaceholder: '40 123 4567',
    ),
  ];

  /// Get country by name
  static CountryData? getCountryByName(String name) {
    try {
      return availableCountries.firstWhere((country) => country.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get country by code
  static CountryData? getCountryByCode(String code) {
    try {
      return availableCountries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get default country (South Korea)
  static CountryData get defaultCountry {
    return getCountryByCode('KR') ?? availableCountries.first;
  }

  /// Get country names for dropdown
  static List<String> get countryNames {
    return availableCountries.map((country) => country.name).toList();
  }
}