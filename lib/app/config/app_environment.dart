enum Environment { dev, staging, prod }

class AppEnvironment {
  static Environment current = Environment.dev;

  static String get baseUrl {
    switch (current) {
      case Environment.dev:
        return 'https://api-dev.example.com';
      case Environment.staging:
        return 'https://api-staging.example.com';
      case Environment.prod:
        return 'https://api.example.com';
    }
  }
}
