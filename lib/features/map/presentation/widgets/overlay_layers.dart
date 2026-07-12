import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import '../../domain/entities/map_layer.dart';

/// Builds the flutter_map child widget for one catalog overlay layer,
/// or null when the layer cannot be rendered (unknown type, missing
/// config — defensive against future server-side layer types).
///
/// [tileServerBaseUrl] prefixes the server-relative tile templates.
Widget? buildOverlayLayer(MapLayer layer, String tileServerBaseUrl) {
  switch (layer.kind) {
    case MapLayerKind.rasterTile:
      if (layer.tileUrlTemplate == null) return null;
      return TileLayer(
        urlTemplate: '$tileServerBaseUrl${layer.tileUrlTemplate}',
        userAgentPackageName: 'com.enterprise.flutter_app',
        maxNativeZoom: 19,
      );

    case MapLayerKind.vectorTile:
      if (layer.tileUrlTemplate == null) return null;
      return VectorTileLayer(
        theme: _vectorThemeFor(layer),
        tileOffset: TileOffset.DEFAULT,
        tileProviders: TileProviders({
          _vectorSourceName: NetworkVectorTileProvider(
            urlTemplate: '$tileServerBaseUrl${layer.tileUrlTemplate}',
            maximumZoom: 19,
          ),
        }),
      );

    case MapLayerKind.wms:
      final url = layer.sourceUrl;
      final wmsLayers = layer.params?['layers'];
      if (url == null || wmsLayers is! String || wmsLayers.isEmpty) {
        return null;
      }
      return TileLayer(
        userAgentPackageName: 'com.enterprise.flutter_app',
        wmsOptions: WMSTileLayerOptions(
          baseUrl: url.contains('?') ? url : '$url?',
          layers: wmsLayers.split(','),
          format: layer.params?['format'] as String? ?? 'image/png',
          version: layer.params?['version'] as String? ?? '1.1.1',
          transparent: true,
        ),
      );

    case MapLayerKind.esriMapServer:
      if (layer.sourceUrl == null) return null;
      return TileLayer(
        // Placeholder template: the provider builds the real export URL.
        urlTemplate: '${layer.sourceUrl}/export/{z}/{x}/{y}',
        userAgentPackageName: 'com.enterprise.flutter_app',
        tileProvider: EsriExportTileProvider(layer.sourceUrl!),
      );

    case MapLayerKind.unknown:
      return null;
  }
}

const _vectorSourceName = 'layer';

/// Generates a Mapbox GL style theme for one MVT layer from the server's
/// simple style. The source-layer inside the pbf is named after the layer
/// UUID (server tiling convention).
vtr.Theme _vectorThemeFor(MapLayer layer) {
  String rgba(List<int>? c, double? opacity, List<int> fallback) {
    final rgb = (c != null && c.length >= 3) ? c : fallback;
    final a = opacity ?? 1.0;
    return 'rgba(${rgb[0]},${rgb[1]},${rgb[2]},$a)';
  }

  final polygon = layer.styles['Polygon'] ?? const LayerGeometryStyle();
  final line = layer.styles['LineString'] ?? const LayerGeometryStyle();
  final point = layer.styles['Point'] ?? const LayerGeometryStyle();

  final style = {
    'version': 8,
    'id': layer.id,
    'sources': {
      _vectorSourceName: {'type': 'vector'},
    },
    'layers': [
      {
        'id': '${layer.id}-fill',
        'type': 'fill',
        'source': _vectorSourceName,
        'source-layer': layer.id,
        'filter': ['==', r'$type', 'Polygon'],
        'paint': {
          'fill-color': rgba(polygon.fillColor, polygon.opacity, [74, 144, 226]),
          'fill-outline-color':
              rgba(polygon.strokeColor, polygon.opacity, [255, 255, 255]),
        },
      },
      {
        'id': '${layer.id}-line',
        'type': 'line',
        'source': _vectorSourceName,
        'source-layer': layer.id,
        'filter': ['==', r'$type', 'LineString'],
        'paint': {
          'line-color': rgba(line.strokeColor, line.opacity, [74, 144, 226]),
          'line-width': line.strokeWidth ?? 2,
        },
      },
      {
        'id': '${layer.id}-point',
        'type': 'circle',
        'source': _vectorSourceName,
        'source-layer': layer.id,
        'filter': ['==', r'$type', 'Point'],
        'paint': {
          'circle-color': rgba(point.fillColor, point.opacity, [74, 144, 226]),
          'circle-radius': point.pointRadius ?? 5,
          'circle-stroke-color':
              rgba(point.strokeColor, point.opacity, [255, 255, 255]),
          'circle-stroke-width': point.strokeWidth ?? 1,
        },
      },
    ],
  };

  return vtr.ThemeReader().read(style);
}

/// Tile provider for non-cached ArcGIS MapServer services: computes the
/// EPSG:3857 bbox of each tile and requests it via the `/export` endpoint
/// (`singleFusedMapCache: false` services have no `/tile/{z}/{y}/{x}`).
class EsriExportTileProvider extends NetworkTileProvider {
  EsriExportTileProvider(this.serviceUrl);

  final String serviceUrl;

  static const double _originShift = 20037508.342789244;

  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    final tiles = math.pow(2, coordinates.z).toDouble();
    final tileSpan = 2 * _originShift / tiles;
    final minX = -_originShift + coordinates.x * tileSpan;
    final maxX = minX + tileSpan;
    final maxY = _originShift - coordinates.y * tileSpan;
    final minY = maxY - tileSpan;
    return '$serviceUrl/export'
        '?bbox=$minX,$minY,$maxX,$maxY'
        '&bboxSR=3857&imageSR=3857&size=256,256'
        '&format=png32&transparent=true&f=image';
  }
}
