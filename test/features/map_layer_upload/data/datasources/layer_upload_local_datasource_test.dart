import 'dart:io';

import 'package:enterprise_flutter_app/features/map_layer_upload/data/datasources/layer_upload_local_datasource.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/data/models/layer_upload_model.dart';
import 'package:enterprise_flutter_app/features/map_layer_upload/domain/entities/layer_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

LayerUploadModel _model(String id, {LayerUploadStatus status = LayerUploadStatus.uploading}) {
  return LayerUploadModel(
    uploadId: id,
    layerId: 'layer-$id',
    filename: '$id.tif',
    filePath: '/tmp/$id.tif',
    totalSize: 100,
    chunkSize: 50,
    totalChunks: 2,
    outputFormat: LayerOutputFormat.raster,
    status: status,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late Directory tempDir;
  late LayerUploadLocalDataSourceImpl dataSource;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('layer_upload_test');
    Hive.init(tempDir.path);
    dataSource = LayerUploadLocalDataSourceImpl(boxName: 'layer_uploads_test');
    await dataSource.openBox();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('layer_uploads_test');
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('getAll returns empty list when nothing saved', () async {
    expect(await dataSource.getAll(), isEmpty);
  });

  test('save then getById returns the saved record', () async {
    await dataSource.save(_model('u1'));
    final loaded = await dataSource.getById('u1');
    expect(loaded, isNotNull);
    expect(loaded!.layerId, 'layer-u1');
  });

  test('save with an existing uploadId overwrites, does not duplicate', () async {
    await dataSource.save(_model('u1', status: LayerUploadStatus.uploading));
    await dataSource.save(_model('u1', status: LayerUploadStatus.done));
    final all = await dataSource.getAll();
    expect(all, hasLength(1));
    expect(all.single.status, LayerUploadStatus.done);
  });

  test('delete removes the record', () async {
    await dataSource.save(_model('u1'));
    await dataSource.delete('u1');
    expect(await dataSource.getById('u1'), isNull);
  });

  test('getResumable excludes terminal statuses', () async {
    await dataSource.save(_model('u1', status: LayerUploadStatus.uploading));
    await dataSource.save(_model('u2', status: LayerUploadStatus.done));
    await dataSource.save(_model('u3', status: LayerUploadStatus.cancelled));
    final resumable = await dataSource.getResumable();
    expect(resumable.map((u) => u.uploadId), ['u1']);
  });
}
