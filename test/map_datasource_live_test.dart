@Tags(['live'])
library;

import 'package:enterprise_flutter_app/core/network/external_dio_client.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:enterprise_flutter_app/features/map/data/datasources/map_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _AlwaysOnline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  test('getLayers parses live catalog', () async {
    final ds = MapRemoteDataSourceImpl(ExternalDioClient(
      baseUrl: 'http://localhost:8050',
      networkInfo: _AlwaysOnline(),
      enableLogging: false,
    ));
    final layers = await ds.getLayers();
    // ignore: avoid_print
    print('parsed ${layers.length} layers: ${layers.map((l) => l.rawType).toSet()}');
    expect(layers, isNotEmpty);

    final identify = await ds.identify(
      layerId: layers.first.id,
      lon: 106.685,
      lat: -6.368,
    );
    // ignore: avoid_print
    print('identify ok, ${identify.length} features');
  });
}
