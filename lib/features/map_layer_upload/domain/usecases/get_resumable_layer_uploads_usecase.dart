import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/layer_upload.dart';
import '../repositories/layer_upload_repository.dart';

class GetResumableLayerUploadsUseCase {
  GetResumableLayerUploadsUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, List<LayerUpload>>> call() => _repository.getResumableUploads();
}
