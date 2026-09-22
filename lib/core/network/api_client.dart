import '../errors/exceptions.dart';

class ApiClient {
  Future<dynamic> get(String endpoint) async {
    try {
      // Placeholder for HTTP client implementation (e.g., http or dio)
      return {};
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      // Placeholder for HTTP client implementation (e.g., http or dio)
      return {};
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
