import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class ResumeLayerUploadUseCase {
  ResumeLayerUploadUseCase(this._repository);

  final LayerUploadRepository _repository;

  Stream<Either<Failure, LayerUpload>> call(String uploadId) =>
      _repository.resumeUpload(uploadId);
}
