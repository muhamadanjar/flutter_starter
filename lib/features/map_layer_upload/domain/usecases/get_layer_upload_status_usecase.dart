import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class GetLayerUploadStatusUseCase {
  GetLayerUploadStatusUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, LayerUpload>> call(String uploadId) => _repository.getStatus(uploadId);
}
