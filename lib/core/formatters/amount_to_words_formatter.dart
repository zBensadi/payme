// ignore_for_file: constant_identifier_names

class AmountToWordsFormatter {
  static const String DZD = 'DZD';

  static String formatAmount(double amount, String languageCode) {
    int dinars = amount.truncate();
    int centimes = ((amount - dinars) * 100).round();

    if (centimes == 100) {
      dinars += 1;
      centimes = 0;
    }

    switch (languageCode) {
      case 'fr':
        return _formatFr(dinars, centimes);
      case 'ar':
        return _formatAr(dinars, centimes);
      case 'en':
      default:
        return _formatEn(dinars, centimes);
    }
  }

  // --- ENGLISH ---
  static final List<String> _enOnes = [
    "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"
  ];
  static final List<String> _enTens = [
    "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"
  ];

  static String _convertEn(int n) {
    if (n < 20) return _enOnes[n];
    if (n < 100) return _enTens[n ~/ 10] + ((n % 10 != 0) ? "-${_enOnes[n % 10]}" : "");
    if (n < 1000) return "${_enOnes[n ~/ 100]} hundred" + ((n % 100 != 0) ? " ${_convertEn(n % 100)}" : "");
    if (n < 1000000) return "${_convertEn(n ~/ 1000)} thousand" + ((n % 1000 != 0) ? " ${_convertEn(n % 1000)}" : "");
    if (n < 1000000000) return "${_convertEn(n ~/ 1000000)} million" + ((n % 1000000 != 0) ? " ${_convertEn(n % 1000000)}" : "");
    return "${_convertEn(n ~/ 1000000000)} billion" + ((n % 1000000000 != 0) ? " ${_convertEn(n % 1000000000)}" : "");
  }

  static String _formatEn(int dinars, int centimes) {
    String res = "";
    if (dinars == 0) {
      res = "zero Algerian dinars";
    } else if (dinars == 1) {
      res = "one Algerian dinar";
    } else {
      res = "${_convertEn(dinars)} Algerian dinars";
    }

    if (centimes > 0) {
      if (centimes == 1) {
        res += " and one centime";
      } else {
        res += " and ${_convertEn(centimes)} centimes";
      }
    }
    // Capitalize first letter
    return res[0].toUpperCase() + res.substring(1);
  }

  // --- FRENCH ---
  static final List<String> _frOnes = [
    "", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf",
    "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize", "dix-sept", "dix-huit", "dix-neuf"
  ];
  static final List<String> _frTens = [
    "", "", "vingt", "trente", "quarante", "cinquante", "soixante", "soixante", "quatre-vingt", "quatre-vingt"
  ];

  static String _convertFr(int n) {
    if (n < 20) return _frOnes[n];
    if (n < 70) {
      int t = n ~/ 10;
      int r = n % 10;
      if (r == 1) return "${_frTens[t]} et un";
      return _frTens[t] + (r > 0 ? "-${_frOnes[r]}" : "");
    }
    if (n < 80) {
      int r = n % 20;
      if (r == 11) return "soixante et onze";
      return "soixante" + (r > 0 ? "-${_frOnes[r]}" : "");
    }
    if (n < 100) {
      int r = n % 20;
      if (n == 80) return "quatre-vingts";
      return "quatre-vingt" + (r > 0 ? "-${_frOnes[r]}" : "");
    }
    if (n < 1000) {
      int h = n ~/ 100;
      int r = n % 100;
      String hs = (h == 1) ? "cent" : "${_frOnes[h]} cent${r == 0 ? "s" : ""}";
      return hs + (r > 0 ? " ${_convertFr(r)}" : "");
    }
    if (n < 1000000) {
      int t = n ~/ 1000;
      int r = n % 1000;
      String ts = (t == 1) ? "mille" : "${_convertFr(t)} mille";
      return ts + (r > 0 ? " ${_convertFr(r)}" : "");
    }
    if (n < 1000000000) {
      int m = n ~/ 1000000;
      int r = n % 1000000;
      String ms = "${_convertFr(m)} million${m > 1 ? "s" : ""}";
      return ms + (r > 0 ? " ${_convertFr(r)}" : "");
    }
    return n.toString(); // Fallback for very large numbers
  }

  static String _formatFr(int dinars, int centimes) {
    String res = "";
    if (dinars == 0) {
      res = "zéro dinar algérien";
    } else if (dinars == 1) {
      res = "un dinar algérien";
    } else {
      res = "${_convertFr(dinars)} dinars algériens";
    }

    if (centimes > 0) {
      if (centimes == 1) {
        res += " et un centime";
      } else {
        res += " et ${_convertFr(centimes)} centimes";
      }
    }
    return res[0].toUpperCase() + res.substring(1);
  }

  // --- ARABIC ---
  static final List<String> _arOnes = [
    "", "واحد", "اثنان", "ثلاثة", "أربعة", "خمسة", "ستة", "سبعة", "ثمانية", "تسعة",
    "عشرة", "أحد عشر", "اثنا عشر", "ثلاثة عشر", "أربعة عشر", "خمسة عشر", "ستة عشر", "سبعة عشر", "ثمانية عشر", "تسعة عشر"
  ];
  static final List<String> _arTens = [
    "", "عشرة", "عشرون", "ثلاثون", "أربعون", "خمسون", "ستون", "سبعون", "ثمانون", "تسعون"
  ];
  static final List<String> _arHundreds = [
    "", "مائة", "مائتان", "ثلاثمائة", "أربعمائة", "خمسمائة", "ستمائة", "سبعمائة", "ثمانمائة", "تسعمائة"
  ];

  static String _convertAr(int n) {
    if (n < 20) return _arOnes[n];
    if (n < 100) {
      int t = n ~/ 10;
      int r = n % 10;
      if (r == 0) return _arTens[t];
      return "${_arOnes[r]} و${_arTens[t]}";
    }
    if (n < 1000) {
      int h = n ~/ 100;
      int r = n % 100;
      if (r == 0) return _arHundreds[h];
      return "${_arHundreds[h]} و${_convertAr(r)}";
    }
    if (n < 1000000) {
      int t = n ~/ 1000;
      int r = n % 1000;
      String ts;
      if (t == 1) ts = "ألف";
      else if (t == 2) ts = "ألفان";
      else if (t >= 3 && t <= 10) ts = "${_convertAr(t)} آلاف";
      else ts = "${_convertAr(t)} ألف";
      if (r == 0) return ts;
      return "$ts و${_convertAr(r)}";
    }
    if (n < 1000000000) {
      int m = n ~/ 1000000;
      int r = n % 1000000;
      String ms;
      if (m == 1) ms = "مليون";
      else if (m == 2) ms = "مليونان";
      else if (m >= 3 && m <= 10) ms = "${_convertAr(m)} ملايين";
      else ms = "${_convertAr(m)} مليون";
      if (r == 0) return ms;
      return "$ms و${_convertAr(r)}";
    }
    return n.toString();
  }

  static String _formatAr(int dinars, int centimes) {
    String res = "";
    if (dinars == 0) {
      res = "صفر دينار جزائري";
    } else if (dinars == 1) {
      res = "دينار جزائري واحد";
    } else if (dinars == 2) {
      res = "ديناران جزائريان";
    } else {
      res = "${_convertAr(dinars)} دينار جزائري";
    }

    if (centimes > 0) {
      if (centimes == 1) {
        res += " وسنتيم واحد";
      } else if (centimes == 2) {
        res += " وسنتيمان";
      } else {
        res += " و${_convertAr(centimes)} سنتيماً";
      }
    }
    return res;
  }
}
