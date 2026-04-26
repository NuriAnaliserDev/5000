class MunsellColor {
  final String code;
  final String name;
  final int hex;

  const MunsellColor(this.code, this.name, this.hex);
}

const List<MunsellColor> geologicalMunsellColors = [
  MunsellColor('N 1', 'Black', 0xFF000000),
  MunsellColor('N 5', 'Medium Grey', 0xFF777777),
  MunsellColor('N 8', 'Light Grey', 0xFFCCCCCC),
  MunsellColor('5R 4/4', 'Reddish Brown', 0xFF8B4513),
  MunsellColor('10R 4/6', 'Red', 0xFFAA3333),
  MunsellColor('5YR 6/4', 'Yellowish Brown', 0xFFB8860B),
  MunsellColor('10YR 8/2', 'Pale Yellow', 0xFFEEE8AA),
  MunsellColor('5Y 7/3', 'Pale Olive', 0xFFC0C080),
  MunsellColor('10Y 6/2', 'Greyish Green', 0xFF8FBC8F),
  MunsellColor('5G 5/2', 'Greenish Grey', 0xFF6B8E23),
  MunsellColor('5B 6/1', 'Bluish Grey', 0xFF708090),
  MunsellColor('5GY 7/2', 'Pale Green', 0xFF98FB98),
  MunsellColor('10GY 5/2', 'Greyish Green', 0xFF556B2F),
];
