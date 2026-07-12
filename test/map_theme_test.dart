import 'package:enterprise_flutter_app/features/map/data/models/map_layer_model.dart';
import 'package:enterprise_flutter_app/features/map/presentation/widgets/overlay_layers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlay builders handle all catalog layer shapes', () {
    final mvt = MapLayerModel.fromJson({
      'id': '20bafcf0-5f7a-4107-a6f5-b7dc71d53edc',
      'code': 'pt-kesuma',
      'layer_type': 'mvt',
      'filename': 'PT Kesuma.zip',
      'file_type': 'vector',
      'tile_url_template': '/tiles/20bafcf0/{z}/{x}/{y}.pbf',
      'status': 'done',
      'bbox': [106.8, -6.6, 106.9, -6.5],
      'file_metadata': {
        'style': {
          'Polygon': {
            'fillColor': [255, 0, 0],
            'strokeColor': [255, 255, 255],
            'strokeWidth': 1,
            'opacity': 0.95,
          },
        },
      },
    });
    expect(buildOverlayLayer(mvt, 'http://localhost:8050'), isNotNull);

    final esri = MapLayerModel.fromJson({
      'id': 'x',
      'layer_type': 'esri_mapserver',
      'filename': 'batas',
      'file_type': 'external',
      'tile_url_template': 'https://example.com/MapServer',
      'status': 'done',
      // esri layers ship `fields` as a map keyed by sublayer index, not a
      // list — parsing must not throw (regression: "is not subtype").
      'file_metadata': {
        'fields': {
          '1': {'fields': [], 'renderMode': 'fields'},
        },
      },
    });
    expect(esri.fields, isEmpty);
    expect(buildOverlayLayer(esri, 'http://localhost:8050'), isNotNull);

    final unknown = MapLayerModel.fromJson({
      'id': 'y',
      'layer_type': 'weird_future_type',
      'filename': 'f',
      'file_type': 'x',
      'tile_url_template': '',
      'status': 'done',
    });
    expect(buildOverlayLayer(unknown, 'http://localhost:8050'), isNull);

    final wmsNoParams = MapLayerModel.fromJson({
      'id': 'z',
      'layer_type': 'wms',
      'filename': 'w',
      'file_type': 'external',
      'tile_url_template': 'https://example.com/wms',
      'status': 'done',
    });
    expect(buildOverlayLayer(wmsNoParams, 'http://localhost:8050'), isNull, reason: 'defensive skip');
  });
}
