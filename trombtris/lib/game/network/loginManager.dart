import 'package:nakama/nakama.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LoginManager {
  static const uuid = Uuid();
  late final networkClient;
  LoginManager(NakamaBaseClient nakamaClient) {
    networkClient = nakamaClient;
  }

  Future<Session?> signInMail(String email, String password) async {
    Session session;
    try {
      session = await networkClient.authenticateEmail(
        email: email,
        password: password,
        create: false,
      );
    } catch (e) {
      print(e);
      return null;
    }
    return session;
  }

  Future<Session?> createAccount(String email, String password,
      {String? username}) async {
    Session session;
    try {
      session = await networkClient.authenticateEmail(
        email: email,
        password: password,
        create: true,
        username: username,
      );
    } catch (e) {
      print(e);
      return null;
    }
    return session;
  }

  String generateDeviceUUID() {
    return uuid.v1();
  }

  Future<List> checkDeviceId() async {
    List response;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString("deviceId");
    if (uuid == null) {
      uuid = generateDeviceUUID();
      prefs.setString("deviceId", uuid);
      response = [uuid, true];
    } else {
      response = [uuid, false];
    }
    return response;
  }

  Future<Session?> signInDeviceId(String deviceId, {String? username}) async {
    Session session;
    try {
      session = await networkClient.authenticateDevice(
          deviceId: deviceId, create: true, username: username);
    } catch (e) {
      print("Username in use | Password must be minimum 8 characters");
      return null;
    }
    return session;
  }
}
