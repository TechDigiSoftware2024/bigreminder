
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage{
  static Future<void> saveToken(String token) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString("token", token);
  }

  static Future<String?> getToken(String token) async{
    final pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  static Future<void> clearToken() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
  }

}