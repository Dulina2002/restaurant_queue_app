abstract class StorageService {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class StorageServiceImpl implements StorageService {
  final Map<String, String> _memoryStore = {};

  @override
  Future<void> setString(String key, String value) async {
    _memoryStore[key] = value;
  }

  @override
  Future<String?> getString(String key) async {
    return _memoryStore[key];
  }

  @override
  Future<void> remove(String key) async {
    _memoryStore.remove(key);
  }

  @override
  Future<void> clear() async {
    _memoryStore.clear();
  }
}
