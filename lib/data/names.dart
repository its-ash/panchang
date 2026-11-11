/// A name in English (transliterated Sanskrit) and Hindi.
class Bi {
  const Bi(this.en, this.hi);

  final String en, hi;

  String of(bool hindi) => hindi ? hi : en;
}

/// Names of the elements of the panchang, in both languages.
abstract final class Names {
  static const tithi = <Bi>[
    Bi('Pratipada', 'प्रतिपदा'),
    Bi('Dwitiya', 'द्वितीया'),
    Bi('Tritiya', 'तृतीया'),
    Bi('Chaturthi', 'चतुर्थी'),
    Bi('Panchami', 'पंचमी'),
    Bi('Shashthi', 'षष्ठी'),
    Bi('Saptami', 'सप्तमी'),
    Bi('Ashtami', 'अष्टमी'),
    Bi('Navami', 'नवमी'),
    Bi('Dashami', 'दशमी'),
    Bi('Ekadashi', 'एकादशी'),
    Bi('Dwadashi', 'द्वादशी'),
    Bi('Trayodashi', 'त्रयोदशी'),
    Bi('Chaturdashi', 'चतुर्दशी'),
    Bi('Purnima', 'पूर्णिमा'),
  ];

  static const amavasya = Bi('Amavasya', 'अमावस्या');

  /// Tithi by index 0..29 (14 = Purnima, 29 = Amavasya).
  static Bi tithiOf(int index) => index == 29 ? amavasya : tithi[index % 15];

  static const paksha = [Bi('Shukla Paksha', 'शुक्ल पक्ष'), Bi('Krishna Paksha', 'कृष्ण पक्ष')];

  static const nakshatra = <Bi>[
    Bi('Ashwini', 'अश्विनी'),
    Bi('Bharani', 'भरणी'),
    Bi('Krittika', 'कृत्तिका'),
    Bi('Rohini', 'रोहिणी'),
    Bi('Mrigashira', 'मृगशिरा'),
    Bi('Ardra', 'आर्द्रा'),
    Bi('Punarvasu', 'पुनर्वसु'),
    Bi('Pushya', 'पुष्य'),
    Bi('Ashlesha', 'आश्लेषा'),
    Bi('Magha', 'मघा'),
    Bi('Purva Phalguni', 'पूर्वा फाल्गुनी'),
    Bi('Uttara Phalguni', 'उत्तरा फाल्गुनी'),
    Bi('Hasta', 'हस्त'),
    Bi('Chitra', 'चित्रा'),
    Bi('Swati', 'स्वाति'),
    Bi('Vishakha', 'विशाखा'),
    Bi('Anuradha', 'अनुराधा'),
    Bi('Jyeshtha', 'ज्येष्ठा'),
    Bi('Mula', 'मूल'),
    Bi('Purva Ashadha', 'पूर्वाषाढ़ा'),
    Bi('Uttara Ashadha', 'उत्तराषाढ़ा'),
    Bi('Shravana', 'श्रवण'),
    Bi('Dhanishta', 'धनिष्ठा'),
    Bi('Shatabhisha', 'शतभिषा'),
    Bi('Purva Bhadrapada', 'पूर्वभाद्रपदा'),
    Bi('Uttara Bhadrapada', 'उत्तरभाद्रपदा'),
    Bi('Revati', 'रेवती'),
  ];

  static const yoga = <Bi>[
    Bi('Vishkumbha', 'विष्कुम्भ'),
    Bi('Priti', 'प्रीति'),
    Bi('Ayushman', 'आयुष्मान'),
    Bi('Saubhagya', 'सौभाग्य'),
    Bi('Shobhana', 'शोभन'),
    Bi('Atiganda', 'अतिगण्ड'),
    Bi('Sukarma', 'सुकर्मा'),
    Bi('Dhriti', 'धृति'),
    Bi('Shula', 'शूल'),
    Bi('Ganda', 'गण्ड'),
    Bi('Vriddhi', 'वृद्धि'),
    Bi('Dhruva', 'ध्रुव'),
    Bi('Vyaghata', 'व्याघात'),
    Bi('Harshana', 'हर्षण'),
    Bi('Vajra', 'वज्र'),
    Bi('Siddhi', 'सिद्धि'),
    Bi('Vyatipata', 'व्यतीपात'),
    Bi('Variyana', 'वरीयान'),
    Bi('Parigha', 'परिघ'),
    Bi('Shiva', 'शिव'),
    Bi('Siddha', 'सिद्ध'),
    Bi('Sadhya', 'साध्य'),
    Bi('Shubha', 'शुभ'),
    Bi('Shukla', 'शुक्ल'),
    Bi('Brahma', 'ब्रह्म'),
    Bi('Indra', 'ऐन्द्र'),
    Bi('Vaidhriti', 'वैधृति'),
  ];

  static const _karanaCycle = <Bi>[
    Bi('Bava', 'बव'),
    Bi('Balava', 'बालव'),
    Bi('Kaulava', 'कौलव'),
    Bi('Taitila', 'तैतिल'),
    Bi('Gara', 'गर'),
    Bi('Vanija', 'वणिज'),
    Bi('Vishti (Bhadra)', 'विष्टि (भद्रा)'),
  ];

  /// Karana by index 0..59 (half-tithis from Shukla Pratipada).
  static Bi karana(int index) {
    switch (index) {
      case 0:
        return const Bi('Kimstughna', 'किंस्तुघ्न');
      case 57:
        return const Bi('Shakuni', 'शकुनि');
      case 58:
        return const Bi('Chatushpada', 'चतुष्पाद');
      case 59:
        return const Bi('Naga', 'नाग');
    }
    return _karanaCycle[(index - 1) % 7];
  }

  static const rashi = <Bi>[
    Bi('Mesha (Aries)', 'मेष'),
    Bi('Vrishabha (Taurus)', 'वृषभ'),
    Bi('Mithuna (Gemini)', 'मिथुन'),
    Bi('Karka (Cancer)', 'कर्क'),
    Bi('Simha (Leo)', 'सिंह'),
    Bi('Kanya (Virgo)', 'कन्या'),
    Bi('Tula (Libra)', 'तुला'),
    Bi('Vrishchika (Scorpio)', 'वृश्चिक'),
    Bi('Dhanu (Sagittarius)', 'धनु'),
    Bi('Makara (Capricorn)', 'मकर'),
    Bi('Kumbha (Aquarius)', 'कुंभ'),
    Bi('Meena (Pisces)', 'मीन'),
  ];

  static const month = <Bi>[
    Bi('Chaitra', 'चैत्र'),
    Bi('Vaishakha', 'वैशाख'),
    Bi('Jyeshtha', 'ज्येष्ठ'),
    Bi('Ashadha', 'आषाढ़'),
    Bi('Shravana', 'श्रावण'),
    Bi('Bhadrapada', 'भाद्रपद'),
    Bi('Ashwin', 'आश्विन'),
    Bi('Kartika', 'कार्तिक'),
    Bi('Margashirsha', 'मार्गशीर्ष'),
    Bi('Pausha', 'पौष'),
    Bi('Magha', 'माघ'),
    Bi('Phalguna', 'फाल्गुन'),
  ];

  /// Indexed by [DateTime.weekday]: 1 Monday ... 7 Sunday.
  static const vaar = <int, Bi>{
    1: Bi('Monday (Somavara)', 'सोमवार'),
    2: Bi('Tuesday (Mangalavara)', 'मंगलवार'),
    3: Bi('Wednesday (Budhavara)', 'बुधवार'),
    4: Bi('Thursday (Guruvara)', 'गुरुवार'),
    5: Bi('Friday (Shukravara)', 'शुक्रवार'),
    6: Bi('Saturday (Shanivara)', 'शनिवार'),
    7: Bi('Sunday (Ravivara)', 'रविवार'),
  };

  static const vaarShort = <int, Bi>{
    1: Bi('Mon', 'सोम'),
    2: Bi('Tue', 'मंगल'),
    3: Bi('Wed', 'बुध'),
    4: Bi('Thu', 'गुरु'),
    5: Bi('Fri', 'शुक्र'),
    6: Bi('Sat', 'शनि'),
    7: Bi('Sun', 'रवि'),
  };

  static const ritu = <Bi>[
    Bi('Vasanta (Spring)', 'वसंत'),
    Bi('Grishma (Summer)', 'ग्रीष्म'),
    Bi('Varsha (Monsoon)', 'वर्षा'),
    Bi('Sharad (Autumn)', 'शरद'),
    Bi('Hemanta (Pre-winter)', 'हेमंत'),
    Bi('Shishira (Winter)', 'शिशिर'),
  ];

  static const uttarayana = Bi('Uttarayana', 'उत्तरायण');
  static const dakshinayana = Bi('Dakshinayana', 'दक्षिणायन');

  static const choghadiya = <Bi>[
    Bi('Udveg', 'उद्वेग'),
    Bi('Chal', 'चल'),
    Bi('Labh', 'लाभ'),
    Bi('Amrit', 'अमृत'),
    Bi('Kaal', 'काल'),
    Bi('Shubh', 'शुभ'),
    Bi('Rog', 'रोग'),
  ];

  static const monthNames = <Bi>[
    Bi('January', 'जनवरी'),
    Bi('February', 'फ़रवरी'),
    Bi('March', 'मार्च'),
    Bi('April', 'अप्रैल'),
    Bi('May', 'मई'),
    Bi('June', 'जून'),
    Bi('July', 'जुलाई'),
    Bi('August', 'अगस्त'),
    Bi('September', 'सितंबर'),
    Bi('October', 'अक्टूबर'),
    Bi('November', 'नवंबर'),
    Bi('December', 'दिसंबर'),
  ];
}
