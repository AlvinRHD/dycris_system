// auth_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthHelper {
  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      return JwtDecoder.decode(token);
    }
    return null;
  }
}
