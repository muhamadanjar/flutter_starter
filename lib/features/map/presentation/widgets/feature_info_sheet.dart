import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/map_layer.dart';

/// Get-info result for one layer.
class LayerInfoResult {
  const LayerInfoResult({required this.layer, required this.features});

  final MapLayer layer;
  final List<Map<String, dynamic>> features;
}

/// Bottom sheet listing identify results grouped per layer.
void showFeatureInfoSheet(BuildContext context, List<LayerInfoResult> results) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => _InfoContent(
        results: results,
        scrollController: scrollController,
      ),
    ),
  );
}

class _InfoContent extends StatelessWidget {
  const _InfoContent({required this.results, required this.scrollController});

  final List<LayerInfoResult> results;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final nonEmpty = results.where((r) => r.features.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.info_outline, size: 40, color: context.colors.textHint),
          const SizedBox(height: 12),
          const Center(child: Text('No features found at this location.')),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final result in nonEmpty) ...[
          Text(
            result.layer.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final feature in result.features) ...[
            _FeatureCard(layer: result.layer, attributes: feature),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.layer, required this.attributes});

  final MapLayer layer;
  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    // Esri results carry the sub-layer name in `_layer`; use it as title.
    final subLayer = attributes['_layer'] as String?;
    final rows = attributes.entries
        .where((e) =>
            e.key != '_layer' &&
            e.value != null &&
            '${e.value}'.isNotEmpty &&
            layer.isAttributeVisible(e.key))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subLayer != null) ...[
              Text(
                subLayer,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.colors.primary,
                    ),
              ),
              const SizedBox(height: 6),
            ],
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        layer.labelFor(row.key),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${row.value}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
