import '../../firebase_runtime.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._services);

  final FirebaseAppServices _services;

  Future<void> logEvent(String name, [Map<String, Object?> parameters = const {}]) {
    return _services.logEvent(name, parameters);
  }

  Future<void> logScreen(String screenName) {
    return _services.logScreen(screenName);
  }
}