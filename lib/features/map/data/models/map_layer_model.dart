import 'package:latlong2/latlong.dart';

import '../../domain/entities/map_layer.dart';

class MapLayerModel extends MapLayer {
  const MapLayerModel({
    required super.id,
    required super.code,
    required super.name,
    required super.kind,
    required super.rawType,
    required super.status,
    super.tileUrlTemplate,
    super.sourceUrl,
    super.params,
    super.bbox,
    super.styles,
    super.fields,
  });

  factory MapLayerModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['layer_type'] as String? ?? '';
    final meta = json['file_metadata'] as Map<String, dynamic>? ?? const {};
    final styleJson = meta['style'] as Map<String, dynamic>? ?? const {};
    // `fields` is a list for uploaded layers, but a map keyed by sublayer
    // index for esri external layers — only the list form is usable here.
    final rawFields = meta['fields'];
    final fieldsJson = rawFields is List ? rawFields : const [];
    final tileUrl = json['tile_url_template'] as String? ?? '';
    final isExternal = tileUrl.startsWith('http');

    return MapLayerModel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: (json['filename'] as String?)?.replaceAll(
            RegExp(r'\.(zip|geojson|json|shp|kml|gpkg)$', caseSensitive: false),
            '',
          ) ??
          json['code'] as String? ??
          'Layer',
      kind: switch (rawType) {
        'tile' || 'xyz' => MapLayerKind.rasterTile,
        'mvt' => MapLayerKind.vectorTile,
        'wms' => MapLayerKind.wms,
        'esri_mapserver' => MapLayerKind.esriMapServer,
        _ => MapLayerKind.unknown,
      },
      rawType: rawType,
      status: json['status'] as String? ?? '',
      tileUrlTemplate: isExternal ? null : tileUrl.isEmpty ? null : tileUrl,
      sourceUrl: isExternal ? tileUrl : null,
      params: (meta['params'] ?? json['params']) as Map<String, dynamic>?,
      bbox: _parseBbox(json['bbox']),
      styles: {
        for (final e in styleJson.entries)
          if (e.value is Map<String, dynamic>)
            e.key: _parseStyle(e.value as Map<String, dynamic>),
      },
      fields: [
        for (final f in fieldsJson)
          if (f is Map<String, dynamic>) _parseField(f),
      ],
    );
  }

  static LayerGeometryStyle _parseStyle(Map<String, dynamic> json) {
    List<int>? rgb(dynamic v) =>
        v is List ? v.map((e) => (e as num).toInt()).toList() : null;
    return LayerGeometryStyle(
      fillColor: rgb(json['fillColor']),
      strokeColor: rgb(json['strokeColor']),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
      pointRadius: (json['pointRadius'] as num?)?.toDouble(),
    );
  }

  static LayerField _parseField(Map<String, dynamic> json) => LayerField(
        original: json['original'] as String? ?? '',
        label: json['label'] as String? ?? json['original'] as String? ?? '',
        visible: json['visible'] as bool? ?? true,
      );

  static List<LatLng>? _parseBbox(dynamic raw) {
    if (raw is! List || raw.length != 4) return null;
    final nums = raw.map((e) => (e as num).toDouble()).toList();
    return [LatLng(nums[1], nums[0]), LatLng(nums[3], nums[2])];
  }
}
