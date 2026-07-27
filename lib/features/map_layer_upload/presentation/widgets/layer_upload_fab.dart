import 'package:flutter/material.dart';

import 'layer_upload_sheet.dart';

/// Floating action button that opens the layer-upload flow (pick file,
/// confirm, watch progress).
class LayerUploadFab extends StatelessWidget {
  const LayerUploadFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'layer-upload',
      tooltip: 'Upload layer',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const LayerUploadSheet(),
      ),
      child: const Icon(Icons.upload_file),
    );
  }
}
