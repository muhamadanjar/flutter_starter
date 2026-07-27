import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/layer_upload_repository.dart';

class PublishLayerToGeoserverUseCase {
  PublishLayerToGeoserverUseCase(this._repository);

  final LayerUploadRepository _repository;

  Future<Either<Failure, Unit>> call(String uploadId) => _repository.publishToGeoserver(uploadId);
}
