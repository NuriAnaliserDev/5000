/// Rock classification tree for GeoField Pro.
/// Professional geological nomenclature in Uzbek.
final Map<String, List<String>> rockTree = {
  'Magmatik': [
    'Granit', 'Syenit', 'Monzonit', 'Diorit', 'Gabbro', 'Anortozit',
    'Peridotit', 'Dunit', 'Piroksinit', 'Kimberlit',
    'Riolit', 'Dakit', 'Traxiandezit', 'Andezit', 'Trakiit', 'Bazalt',
    'Fonolit', 'Tefrit', 'Pikrit', 'Komatiit', 'Lamprofir',
    'Obsidian', 'Pemza', 'Vulqon tufi', 'Vulqon brekciyasi',
    'Pegmatit', 'Aploit',
  ],
  'Cho\'kindi': [
    'Qumtosh', 'Konglomerat', 'Brekciya', 'Arkilit', 'Alevroli', 'Gil slanes',
    'Ohaktosh', 'Dolom it', 'Mergel', 'Bo\'r', 'Radiolarit',
    'Flysh', 'Oolitli ohaktosh', 'Rif ohaktoshi', 'Travertin',
    'Gips', 'Angidrit', 'Halitit (Tosh tuzi)', 'Fosforitli slanes',
    'Ko\'mir', 'Bitumli slanes',
    'Kremneviy jinslar (Flint/Chert)', 'Yashma (Jasper)', 'Diatomit',
  ],
  'Metamorfik': [
    'Gneys', 'Granit-gneys', 'Migmatit',
    'Slanets (Schist)', 'Fillitu', 'Zelenyoslanets (Greenschist)',
    'Ko\'k slanes (Blueschist)', 'Eklogit', 'Amfibolit',
    'Kvartsit', 'Mramor', 'Kalksilikatli jinslar', 'Skarn', 'Hornfels',
    'Serpentinit', 'Talkslanets', 'Granulit',
    'Milonit', 'Psevdotaxilit', 'Kataklazit',
  ],
  'Rudali va Minerallar (Ore)': [
    'Kvarts tomiri', 'Sulfidli tomir', 'Oksidli rudali zona',
    'Gidrotermal o\'zgargan zona', 'Gossan (Temir shapkasi)',
    'Magnetitli skarn', 'Kalioz (Gossanous zone)',
    'Xalkopirit', 'Pirrotit', 'Pirid (Pirit)',
    'Galenit', 'Sfalerit', 'Kassiterit (Qalay)',
    'Gematit', 'Magnetit', 'Limonit',
    'Molibdenit', 'Volfremit', 'Shelit',
  ],
};

List<String> getAllRocks() {
  return rockTree.values.expand((e) => e).toList();
}
