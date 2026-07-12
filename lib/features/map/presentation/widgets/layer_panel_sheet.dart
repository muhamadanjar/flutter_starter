import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/basemap.dart';
import '../../domain/entities/map_layer.dart';
import '../providers/map_providers.dart';

/// Bottom sheet with basemap selection and overlay layer toggles.
void showLayerPanelSheet(BuildContext context, MapController mapController) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => _LayerPanel(
        scrollController: scrollController,
        mapController: mapController,
      ),
    ),
  );
}

class _LayerPanel extends ConsumerWidget {
  const _LayerPanel({
    required this.scrollController,
    required this.mapController,
  });

  final ScrollController scrollController;
  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basemap = ref.watch(basemapProvider);
    final catalog = ref.watch(mapCatalogProvider);
    final visibleIds = ref.watch(visibleLayerIdsProvider);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('Basemap', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final option in Basemap.values)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(option.label),
            trailing: option == basemap
                ? Icon(Icons.check_rounded, color: context.colors.primary)
                : null,
            onTap: () => ref.read(basemapProvider.notifier).select(option),
          ),
        const Divider(height: 24),
        Text('Layers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        catalog.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Failed to load layers: $error',
                  style: TextStyle(color: context.colors.error),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(mapCatalogProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (layers) => Column(
            children: [
              for (final layer in layers.where((l) => l.isReady))
                _LayerTile(
                  layer: layer,
                  visible: visibleIds.contains(layer.id),
                  mapController: mapController,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LayerTile extends ConsumerWidget {
  const _LayerTile({
    required this.layer,
    required this.visible,
    required this.mapController,
  });

  final MapLayer layer;
  final bool visible;
  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderable = layer.isRenderable;
    return SwitchListTile(
      value: visible,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(layer.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          _TypeBadge(kind: layer.kind, rawType: layer.rawType),
          if (layer.bbox != null)
            IconButton(
              icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: 'Zoom to layer',
              onPressed: () {
                mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(layer.bbox!),
                    padding: const EdgeInsets.all(40),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      onChanged: !renderable
          ? null
          : (on) {
              final ids = {...ref.read(visibleLayerIdsProvider)};
              on ? ids.add(layer.id) : ids.remove(layer.id);
              ref.read(visibleLayerIdsProvider.notifier).state = ids;
            },
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.kind, required this.rawType});

  final MapLayerKind kind;
  final String rawType;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      MapLayerKind.rasterTile => 'XYZ',
      MapLayerKind.vectorTile => 'MVT',
      MapLayerKind.wms => 'WMS',
      MapLayerKind.esriMapServer => 'ESRI',
      MapLayerKind.unknown => rawType.toUpperCase(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.primary,
            ),
      ),
    );
  }
}
