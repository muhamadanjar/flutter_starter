import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/layer_upload_providers.dart';
import 'layer_upload_sheet.dart';

/// Shown on `MapPage` when a previous session left a non-terminal upload
/// behind. Lets the user resume it (reopens the progress sheet) or discard
/// it outright (best-effort server cancel + local record removal).
class ResumeLayerUploadBanner extends ConsumerWidget {
  const ResumeLayerUploadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumableAsync = ref.watch(resumableLayerUploadsProvider);

    return resumableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (uploads) {
        if (uploads.isEmpty) return const SizedBox.shrink();
        final upload = uploads.first;

        return MaterialBanner(
          content: Text('Ada upload "${upload.filename}" yang belum selesai.'),
          actions: [
            TextButton(
              onPressed: () async {
                await ref.read(discardLayerUploadUseCaseProvider).call(upload.uploadId);
                ref.invalidate(resumableLayerUploadsProvider);
              },
              child: const Text('Buang'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(activeLayerUploadProvider.notifier).resume(upload.uploadId);
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const LayerUploadSheet(),
                );
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }
}
