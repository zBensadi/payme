import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/formatters/amount_to_words_formatter.dart';

void main() {
  group('AmountToWordsFormatter', () {
    test('formats English correctly', () {
      expect(AmountToWordsFormatter.formatAmount(110000.50, 'en'), 'One hundred ten thousand Algerian dinars and fifty centimes');
      expect(AmountToWordsFormatter.formatAmount(0, 'en'), 'Zero Algerian dinars');
      expect(AmountToWordsFormatter.formatAmount(1, 'en'), 'One Algerian dinar');
      expect(AmountToWordsFormatter.formatAmount(1.01, 'en'), 'One Algerian dinar and one centime');
    });

    test('formats French correctly', () {
      expect(AmountToWordsFormatter.formatAmount(110000.50, 'fr'), 'Cent dix mille dinars algériens et cinquante centimes');
      expect(AmountToWordsFormatter.formatAmount(0, 'fr'), 'Zéro dinar algérien');
      expect(AmountToWordsFormatter.formatAmount(1, 'fr'), 'Un dinar algérien');
      expect(AmountToWordsFormatter.formatAmount(1.01, 'fr'), 'Un dinar algérien et un centime');
      expect(AmountToWordsFormatter.formatAmount(80, 'fr'), 'Quatre-vingts dinars algériens');
      expect(AmountToWordsFormatter.formatAmount(71, 'fr'), 'Soixante et onze dinars algériens');
    });

    test('formats Arabic correctly', () {
      expect(AmountToWordsFormatter.formatAmount(110000.50, 'ar'), 'مائة وعشرة ألف دينار جزائري وخمسون سنتيماً');
      expect(AmountToWordsFormatter.formatAmount(0, 'ar'), 'صفر دينار جزائري');
      expect(AmountToWordsFormatter.formatAmount(1, 'ar'), 'دينار جزائري واحد');
      expect(AmountToWordsFormatter.formatAmount(2, 'ar'), 'ديناران جزائريان');
      expect(AmountToWordsFormatter.formatAmount(1.01, 'ar'), 'دينار جزائري واحد وسنتيم واحد');
    });
  });
}
