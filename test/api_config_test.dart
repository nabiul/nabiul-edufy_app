import 'package:flutter_test/flutter_test.dart';
import 'package:nabiul_edufy_app/src/config/api_config.dart';

void main() {
  tearDown(() => ApiConfig.setBaseUrl(null));

  test('saved API URL overrides default and trims trailing slash', () {
    ApiConfig.setBaseUrl(' http://192.168.1.20/nabiul-edufy/api/v1/ ');

    expect(ApiConfig.baseUrl, 'http://192.168.1.20/nabiul-edufy/api/v1');
  });
}
