enum AppEnvironment {
  development,
  production,
}

class EnvironmentConfig {
  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  static bool get isDevelopment => currentEnvironment == AppEnvironment.development;
  static bool get isProduction => currentEnvironment == AppEnvironment.production;
}
