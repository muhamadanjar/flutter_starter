import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Floating zoom-in / zoom-out controls for a FlutterMap view.
///
/// Pass the same MapController instance used by the FlutterMap widget.
/// Tapping + / - moves the camera by `step` zoom levels, clamped to
/// minZoom / maxZoom (defaults mirror MapOptions in MapView).
///
/// Embed it inside the same Stack as the map:
///
/// ```dart
/// MapZoomControls(controller: _mapController),
/// ```
class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.controller,
    this.minZoom = 3,
    this.maxZoom = 20,
    this.step = 1,
    this.alignment = Alignment.centerRight,
    this.margin = const EdgeInsets.only(right: 12, bottom: 96),
  });

  final MapController controller;
  final double minZoom;
  final double maxZoom;
  final double step;
  final Alignment alignment;
  final EdgeInsets margin;

  void _zoom(bool inwards) {
    final camera = controller.camera;
    final target = (camera.zoom + (inwards ? step : -step))
        .clamp(minZoom, maxZoom);
    controller.move(camera.center, target);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: margin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom in',
                onPressed: () => _zoom(true),
              ),
              const SizedBox(height: 12),
              _ZoomButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom out',
                onPressed: () => _zoom(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: colorScheme.surface,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 22,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
