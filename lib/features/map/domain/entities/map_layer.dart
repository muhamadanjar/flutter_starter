import 'package:latlong2/latlong.dart';

/// How a catalog layer is rendered on the map.
///
/// `unknown` covers any `layer_type` string the app does not recognise;
/// such layers are listed but cannot be toggled on.
enum MapLayerKind { rasterTile, vectorTile, wms, esriMapServer, unknown }

/// Per-geometry simple style provided by the tile server.
class LayerGeometryStyle {
  const LayerGeometryStyle({
    this.fillColor,
    this.strokeColor,
    this.strokeWidth,
    this.opacity,
    this.pointRadius,
  });

  final List<int>? fillColor;
  final List<int>? strokeColor;
  final double? strokeWidth;
  final double? opacity;
  final double? pointRadius;
}

/// Attribute field descriptor (display label and visibility).
class LayerField {
  const LayerField({
    required this.original,
    required this.label,
    required this.visible,
  });

  final String original;
  final String label;
  final bool visible;
}

/// One entry of the tile server layer catalog.
class MapLayer {
  const MapLayer({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    required this.rawType,
    required this.status,
    this.tileUrlTemplate,
    this.sourceUrl,
    this.params,
    this.bbox,
    this.styles = const {},
    this.fields = const [],
  });

  final String id;
  final String code;
  final String name;
  final MapLayerKind kind;
  final String rawType;
  final String status;

  /// Server-relative template (`/tiles/{id}/{z}/{x}/{y}.png|.pbf`).
  final String? tileUrlTemplate;

  /// Absolute URL for external services (esri MapServer, WMS base).
  final String? sourceUrl;
  final Map<String, dynamic>? params;
  final List<LatLng>? bbox;
  final Map<String, LayerGeometryStyle> styles;
  final List<LayerField> fields;

  bool get isReady => status == 'done';
  bool get isRenderable => kind != MapLayerKind.unknown && isReady;

  /// Display label for attributes: `fields` mapping when present.
  String labelFor(String attribute) {
    for (final f in fields) {
      if (f.original == attribute) return f.label;
    }
    return attribute;
  }

  /// Whether an attribute should appear in get-info results.
  bool isAttributeVisible(String attribute) {
    if (fields.isEmpty) return true;
    for (final f in fields) {
      if (f.original == attribute) return f.visible;
    }
    return true;
  }
}
