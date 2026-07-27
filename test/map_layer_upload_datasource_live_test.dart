@Tags(['live'])
library;

import 'dart:typed_data';

import 'package:enterprise_flutter_app/core/network/external_dio_client.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/datasources/layer_upload_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _AlwaysOnline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  late LayerUploadRemoteDataSourceImpl ds;

  setUp(() {
    ds = LayerUploadRemoteDataSourceImpl(ExternalDioClient(
      baseUrl: 'https://tileserver.jattirayyakonsultindo.co.id',
      networkInfo: _AlwaysOnline(),
      enableLogging: false,
      enableRetry: false,
    ));
  });

  test('vector pipeline: init -> chunk -> save reaches status done', () async {
    const geojson =
        '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{},'
        '"geometry":{"type":"Point","coordinates":[106.05,-6.05]}}]}';
    final bytes = Uint8List.fromList(geojson.codeUnits);

    final init = await ds.initUpload(
      filename: 'live_test.geojson',
      totalSize: bytes.length,
      outputFormat: 'vector',
    );
    final uploadId = init['upload_id'] as String;
    expect(init['total_chunks'], 1);

    final chunkResult = await ds.sendChunk(uploadId: uploadId, chunkIndex: 0, bytes: bytes);
    expect(chunkResult['is_complete'], isTrue);

    final saveResult = await ds.saveGeojson(uploadId);
    expect(saveResult['status'], 'done');

    final status = await ds.getStatus(uploadId);
    expect(status['status'], 'done');
  });

  test('cancel on a fresh upload does not throw, and status confirms cancelled', () async {
    final init = await ds.initUpload(
      filename: 'live_cancel_test.tif',
      totalSize: 10,
      outputFormat: 'raster',
    );
    final uploadId = init['upload_id'] as String;

    // Per ADR 0002 this always 500s server-side even on success — the
    // datasource must not throw for this specific case.
    await ds.cancel(uploadId);

    final status = await ds.getStatus(uploadId);
    expect(status['status'], 'cancelled');
  });
}
