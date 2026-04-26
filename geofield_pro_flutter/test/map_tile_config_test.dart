import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/screens/map/map_tile_config.dart';

void main() {
  test('mapTileUrlTemplate: satellit va subdomenlar', () {
    expect(mapTileUrlTemplate('opentopomap'), contains('opentopomap'));
    expect(mapTileUrlTemplate('osm'), contains('basemaps.cartocdn'));
    expect(mapTileSubdomains('satellite'), isEmpty);
    expect(mapTileSubdomains('osm').length, 4);
  });
}
