import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/layer_upload.dart';
import '../providers/layer_upload_providers.dart';

/// Bottom sheet: pick a `.tif`/`.tiff`/`.geojson`/`.zip` file, confirm, then
/// show live upload/finalize progress driven by [activeLayerUploadProvider].
class LayerUploadSheet extends ConsumerStatefulWidget {
  const LayerUploadSheet({super.key});

  @override
  ConsumerState<LayerUploadSheet> createState() => _LayerUploadSheetState();
}

class _LayerUploadSheetState extends ConsumerState<LayerUploadSheet> {
  PlatformFile? _selected;
  bool _picking = false;

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        type: FileType.custom,
        allowedExtensions: const ['tif', 'tiff', 'geojson', 'zip'],
      );
      final file = result?.files.single;
      if (file != null && file.path != null) {
        setState(() => _selected = file);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _startUpload() {
    final file = _selected;
    if (file == null || file.path == null) return;
    ref.read(activeLayerUploadProvider.notifier).start(
          filePath: file.path!,
          filename: file.name,
          totalSize: file.size,
        );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeLayerUploadProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
          children: [
            Text('Upload Layer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (active == null) ...[
              OutlinedButton.icon(
                onPressed: _picking ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  _selected == null
                      ? 'Pilih file (.tif, .geojson, .zip)'
                      : _selected!.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _selected == null ? null : _startUpload,
                child: const Text('Upload'),
              ),
            ] else
              _UploadProgress(active),
          ],
        ),
      ),
    );
  }
}

class _UploadProgress extends ConsumerStatefulWidget {
  const _UploadProgress(this.state);

  final AsyncValue<LayerUpload> state;

  @override
  ConsumerState<_UploadProgress> createState() => _UploadProgressState();
}

class _UploadProgressState extends ConsumerState<_UploadProgress> {
  bool _publishing = false;

  Future<void> _publish(String uploadId) async {
    setState(() => _publishing = true);
    final result = await ref.read(publishLayerToGeoserverUseCaseProvider).call(uploadId);
    if (!mounted) return;
    setState(() => _publishing = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish gagal: ${failure.message}')),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layer dipublish')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upload gagal: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(activeLayerUploadProvider.notifier).clear(),
            child: const Text('Tutup'),
          ),
        ],
      ),
      data: (upload) {
        final label = switch (upload.status) {
          LayerUploadStatus.pending => 'Menyiapkan…',
          LayerUploadStatus.uploading =>
            'Mengunggah ${upload.uploadedChunkCount}/${upload.totalChunks} bagian',
          LayerUploadStatus.uploaded => 'Memproses…',
          LayerUploadStatus.processing => 'Memproses…',
          LayerUploadStatus.done => 'Layer siap',
          LayerUploadStatus.failed => upload.errorMessage ?? 'Gagal',
          LayerUploadStatus.cancelled => 'Dibatalkan',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: upload.isTerminal ? 1 : upload.progressPercent / 100,
            ),
            const SizedBox(height: 12),
            Text(label),
            const SizedBox(height: 16),
            if (upload.status == LayerUploadStatus.failed)
              FilledButton(
                onPressed: () =>
                    ref.read(activeLayerUploadProvider.notifier).retry(upload.uploadId),
                child: const Text('Coba Lagi'),
              )
            else if (!upload.isTerminal)
              OutlinedButton(
                onPressed: () => ref.read(activeLayerUploadProvider.notifier).cancel(),
                child: const Text('Batalkan'),
              ),
            if (upload.status == LayerUploadStatus.done) ...[
              if (upload.tileUrlTemplate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tile URL: ${upload.tileUrlTemplate}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _publishing ? null : () => _publish(upload.uploadId),
                child: _publishing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish ke Geoserver'),
              ),
            ],
            if (upload.isTerminal) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  ref.read(activeLayerUploadProvider.notifier).clear();
                  ref.invalidate(resumableLayerUploadsProvider);
                  Navigator.of(context).pop();
                },
                child: const Text('Selesai'),
              ),
            ],
          ],
        );
      },
    );
  }
}
