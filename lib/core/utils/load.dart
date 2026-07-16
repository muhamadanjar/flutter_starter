import 'package:enterprise_flutter_app/core/utils/retry.dart';

class Load<T> {
  const Load._();

  const factory Load.initial() = Initial<T>;

  const factory Load.loading() = Loading<T>;

  const factory Load.success(T value) = Success<T>;

  const factory Load.error(Exception error) = Error<T>;

  static Future<bool> call<T>({
    required Future<T> Function() block,
    required Function(Load<T> load) onLoad,
    int retryTimes = 0,
    Function(Exception error)? onError,
  }) async {
    try {
      await retry(retryTimes, () async {
        onLoad.call(const Load.loading());
        final response = await block();
        onLoad.call(Load.success(response));
      });
      return Future.value(true);
    } on Exception catch (e) {
      onLoad.call(Load<T>.error(e));
      if (onError != null) {
        onError.call(e);
      }
      return Future.value(false);
    }
  }

}

class Initial<T> extends Load<T> {
  const Initial() : super._();
}

class Loading<T> extends Load<T> {
  const Loading() : super._();
}

class Error<T> extends Load<T> {
  const Error(this.error) : super._();

  final Exception error;
}

class Success<T> extends Load<T> {
  const Success(this.data) : super._();

  final T data;
}

extension AsyncExt<T> on Load<T> {
  bool get isLoading => this is Loading;

  bool get isSuccess => this is Success;

  bool get isError => this is Error;

  bool get isInitial => this is Initial;

  bool get isInitialOrLoading => this is Initial || this is Loading;

  T get data => (this as Success).data;

  T? get dataOrNull => this is Success ? data : null;

  Exception get error => (this as Error).error;
}
