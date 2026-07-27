import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class UploadLayerFileUseCase {
  UploadLayerFileUseCase(this._repository);

  final LayerUploadRepository _repository;

  Stream<Either<Failure, LayerUpload>> call({
    required String filePath,
    required String filename,
    required int totalSize,
  }) =>
      _repository.uploadFile(filePath: filePath, filename: filename, totalSize: totalSize);
}
