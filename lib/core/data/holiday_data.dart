/// Indian Festivals and Holidays for 2025
/// Pre-populated holidays that appear in calendar
class HolidayData {
  HolidayData._();

  /// Get holidays for a specific date
  static String? getHoliday(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _holidays2025[key];
  }

  /// Check if date is a holiday
  static bool isHoliday(DateTime date) => getHoliday(date) != null;

  /// Get all holidays for a month
  static Map<int, String> getHolidaysForMonth(int year, int month) {
    final holidays = <int, String>{};
    for (final entry in _holidays2025.entries) {
      final parts = entry.key.split('-');
      if (int.parse(parts[0]) == year && int.parse(parts[1]) == month) {
        holidays[int.parse(parts[2])] = entry.value;
      }
    }
    return holidays;
  }

  // 2025 Indian Holidays & Festivals
  static const Map<String, String> _holidays2025 = {
    // January
    '2025-01-01': 'New Year',
    '2025-01-13': 'Lohri',
    '2025-01-14': 'Makar Sankranti / Pongal',
    '2025-01-26': 'Republic Day',

    // February
    '2025-02-02': 'Basant Panchami',
    '2025-02-12': 'Guru Ravidas Jayanti',
    '2025-02-14': 'Valentine\'s Day',
    '2025-02-26': 'Maha Shivaratri',

    // March
    '2025-03-14': 'Holi',
    '2025-03-30': 'Ugadi / Gudi Padwa',
    '2025-03-31': 'Eid ul-Fitr',

    // April
    '2025-04-06': 'Ram Navami',
    '2025-04-10': 'Mahavir Jayanti',
    '2025-04-13': 'Baisakhi',
    '2025-04-14': 'Ambedkar Jayanti',
    '2025-04-18': 'Good Friday',
    '2025-04-20': 'Easter',

    // May
    '2025-05-01': 'May Day',
    '2025-05-12': 'Buddha Purnima',
    '2025-05-11': 'Mother\'s Day',

    // June
    '2025-06-07': 'Eid ul-Adha',
    '2025-06-15': 'Father\'s Day',
    '2025-06-21': 'International Yoga Day',

    // July
    '2025-07-06': 'Muharram',
    '2025-07-17': 'Guru Purnima',

    // August
    '2025-08-09': 'Raksha Bandhan',
    '2025-08-15': 'Independence Day',
    '2025-08-16': 'Janmashtami',
    '2025-08-27': 'Onam',

    // September
    '2025-09-05': 'Teacher\'s Day',
    '2025-09-16': 'Milad un-Nabi',
    '2025-09-29': 'Navratri Begins',

    // October
    '2025-10-02': 'Gandhi Jayanti',
    '2025-10-07': 'Dussehra',
    '2025-10-20': 'Karwa Chauth',
    '2025-10-25': 'Diwali',
    '2025-10-27': 'Govardhan Puja',
    '2025-10-28': 'Bhai Dooj',
    '2025-10-31': 'Halloween',

    // November
    '2025-11-01': 'All Saints\' Day',
    '2025-11-05': 'Guru Nanak Jayanti',
    '2025-11-14': 'Children\'s Day',

    // December
    '2025-12-25': 'Christmas',
    '2025-12-31': 'New Year\'s Eve',
  };
}
