import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/logger/index.dart';
import '../providers/map_providers.dart';
import 'feature_info_sheet.dart';
import 'layer_panel_sheet.dart';
import 'overlay_layers.dart';

/// Shared, reusable map widget.
///
/// Renders the selected basemap plus all visible catalog overlays
/// (raster XYZ, MVT vector tiles, WMS, esri MapServer export), handles
/// tap-to-identify against every visible layer, and hosts the layer
/// panel button. Embed it in any page:
///
/// ```dart
/// MapView(
///   initialCenter: LatLng(-6.5, 106.8),
///   initialZoom: 12,
///   myLocation: currentLatLng, // optional blue marker
/// )
/// ```
class MapView extends ConsumerStatefulWidget {
  const MapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 12,
    this.myLocation,
    this.controller,
    this.showLayerButton = true,
    this.enableIdentify = true,
  });

  final LatLng initialCenter;
  final double initialZoom;

  /// Current device position; rendered as a blue dot when set.
  final LatLng? myLocation;

  /// Pass a controller to move the camera from outside (e.g. recenter).
  final MapController? controller;
  final bool showLayerButton;
  final bool enableIdentify;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  late final MapController _mapController =
      widget.controller ?? MapController();
  bool _identifying = false;

  @override
  void dispose() {
    if (widget.controller == null) _mapController.dispose();
    super.dispose();
  }

  Future<void> _identify(LatLng point) async {
    if (!widget.enableIdentify || _identifying) return;

    final visibleIds = ref.read(visibleLayerIdsProvider);
    final catalog = ref.read(mapCatalogProvider).valueOrNull ?? const [];
    final layers = catalog.where((l) => visibleIds.contains(l.id)).toList();
    if (layers.isEmpty) return;

    setState(() => _identifying = true);
    final identifyFeatures = ref.read(identifyFeaturesUseCaseProvider);
    try {
      final results = await Future.wait(layers.map((layer) async {
        final result = await identifyFeatures(
          layerId: layer.id,
          lon: point.longitude,
          lat: point.latitude,
        );
        return result.fold(
          (failure) {
            log.w('Identify failed for layer ${layer.code}: ${failure.message}');
            return LayerInfoResult(layer: layer, features: const []);
          },
          (features) => LayerInfoResult(layer: layer, features: features),
        );
      }));
      if (mounted) showFeatureInfoSheet(context, results);
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final basemap = ref.watch(basemapProvider);
    final visibleIds = ref.watch(visibleLayerIdsProvider);
    final catalog = ref.watch(mapCatalogProvider).valueOrNull ?? const [];
    final tileServerBaseUrl = ref.watch(tileServerBaseUrlProvider);

    final overlays = <Widget>[
      for (final layer in catalog)
        if (visibleIds.contains(layer.id))
          if (buildOverlayLayer(layer, tileServerBaseUrl)
              case final Widget overlay)
            overlay,
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 20,
            onTap: (_, point) => _identify(point),
          ),
          children: [
            TileLayer(
              urlTemplate: basemap.urlTemplate,
              maxNativeZoom: basemap.maxZoom,
              userAgentPackageName: 'com.enterprise.flutter_app',
            ),
            ...overlays,
            if (widget.myLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.myLocation!,
                    width: 20,
                    height: 20,
                    child: const _MyLocationDot(),
                  ),
                ],
              ),
          ],
        ),
        if (widget.showLayerButton)
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'map-layers',
              tooltip: 'Layers & basemap',
              onPressed: () => showLayerPanelSheet(context, _mapController),
              child: const Icon(Icons.layers_outlined),
            ),
          ),
        if (_identifying)
          const Positioned(
            top: 16,
            left: 16,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
    );
  }
}
