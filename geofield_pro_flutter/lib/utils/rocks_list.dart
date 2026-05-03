/// Rock classification tree for GeoField Pro.
/// Professional geological nomenclature in Uzbek.
final Map<String, List<String>> rockTree = {
  'Magmatik': [
    'Granit',
    'Syenit',
    'Monzonit',
    'Diorit',
    'Gabbro',
    'Anortozit',
    'Peridotit',
    'Dunit',
    'Piroksinit',
    'Kimberlit',
    'Riolit',
    'Dakit',
    'Traxiandezit',
    'Andezit',
    'Trakiit',
    'Bazalt',
    'Fonolit',
    'Tefrit',
    'Pikrit',
    'Komatiit',
    'Lamprofir',
    'Obsidian',
    'Pemza',
    'Vulqon tufi',
    'Vulqon brekciyasi',
    'Pegmatit',
    'Aploit',
  ],
  'Cho\'kindi': [
    'Qumtosh',
    'Konglomerat',
    'Brekciya',
    'Arkilit',
    'Alevroli',
    'Gil slanes',
    'Ohaktosh',
    'Dolom it',
    'Mergel',
    'Bo\'r',
    'Radiolarit',
    'Flysh',
    'Oolitli ohaktosh',
    'Rif ohaktoshi',
    'Travertin',
    'Gips',
    'Angidrit',
    'Halitit (Tosh tuzi)',
    'Fosforitli slanes',
    'Ko\'mir',
    'Bitumli slanes',
    'Kremneviy jinslar (Flint/Chert)',
    'Yashma (Jasper)',
    'Diatomit',
  ],
  'Metamorfik': [
    'Gneys',
    'Granit-gneys',
    'Migmatit',
    'Slanets (Schist)',
    'Fillitu',
    'Zelenyoslanets (Greenschist)',
    'Ko\'k slanes (Blueschist)',
    'Eklogit',
    'Amfibolit',
    'Kvartsit',
    'Mramor',
    'Kalksilikatli jinslar',
    'Skarn',
    'Hornfels',
    'Serpentinit',
    'Talkslanets',
    'Granulit',
    'Milonit',
    'Psevdotaxilit',
    'Kataklazit',
  ],
  'Rudali va Minerallar (Ore)': [
    'Kvarts tomiri',
    'Sulfidli tomir',
    'Oksidli rudali zona',
    'Gidrotermal o\'zgargan zona',
    'Gossan (Temir shapkasi)',
    'Magnetitli skarn',
    'Kalioz (Gossanous zone)',
    'Xalkopirit',
    'Pirrotit',
    'Pirid (Pirit)',
    'Galenit',
    'Sfalerit',
    'Kassiterit (Qalay)',
    'Gematit',
    'Magnetit',
    'Limonit',
    'Molibdenit',
    'Volfremit',
    'Shelit',
  ],
};

List<String> getAllRocks() {
  return rockTree.values.expand((e) => e).toList();
}

/// AI qaytargan `rock_type` qatorini [rockTree] dagi kategoriya va kichik tur bilan moslashtirish.
({String category, String sub})? matchRockTreeFromAiLabel(String aiRockType) {
  final normalized = aiRockType.trim();
  if (normalized.isEmpty) return null;
  final lower = normalized.toLowerCase();
  if (lower.contains('noma\'lum') ||
      lower.contains("noma'lum") ||
      lower.contains('noma‘lum')) {
    return null;
  }

  String? bestCat;
  String? bestSub;
  var bestScore = 0;

  for (final e in rockTree.entries) {
    for (final sub in e.value) {
      final sl = sub.toLowerCase();
      var score = 0;
      if (lower == sl) {
        score = 1000 + sub.length;
      } else if (lower.contains(sl)) {
        score = 500 + sl.length;
      } else if (sl.contains(lower) && lower.length >= 3) {
        score = 400 + lower.length;
      } else if (_tokenOverlap(lower, sl)) {
        score = 100;
      }
      if (score > bestScore) {
        bestScore = score;
        bestCat = e.key;
        bestSub = sub;
      }
    }
  }

  if (bestCat != null && bestSub != null && bestScore >= 100) {
    return (category: bestCat, sub: bestSub);
  }
  return null;
}

bool _tokenOverlap(String a, String b) {
  final ta = a.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
  final tb = b.split(RegExp(r'\s+')).where((t) => t.length > 2).toSet();
  return ta.intersection(tb).isNotEmpty;
}
