import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/technician_dashboard_model.dart';

abstract class TechnicianDashboardLocalDataSource {
  Future<void> cacheDashboard(TechnicianDashboardModel dashboard);
  Future<TechnicianDashboardModel?> getCachedDashboard();
}

class TechnicianDashboardLocalDataSourceImpl
    implements TechnicianDashboardLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _cacheKey = 'CACHED_TECHNICIAN_DASHBOARD';

  TechnicianDashboardLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheDashboard(TechnicianDashboardModel dashboard) async {
    final jsonString = jsonEncode(dashboard.toJson());
    await sharedPreferences.setString(_cacheKey, jsonString);
  }

  @override
  Future<TechnicianDashboardModel?> getCachedDashboard() async {
    final jsonString = sharedPreferences.getString(_cacheKey);
    if (jsonString != null) {
      return TechnicianDashboardModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}
