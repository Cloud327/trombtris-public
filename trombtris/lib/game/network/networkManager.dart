import 'dart:async';

import 'package:nakama/api.dart' as api;
import 'package:nakama/nakama.dart';
import 'package:nakama/rtapi.dart' as rt;
import 'package:trombtris/game/board/board.dart';
import 'package:trombtris/game/network/loginManager.dart';
import 'package:trombtris/game/network/matchLogic.dart';
import 'package:trombtris/game/network/networkSocial.dart';
import 'package:trombtris/game/network/server_info.dart';

class NetworkManager {
  static NetworkManager? _instance;

  late final NakamaBaseClient _nakamaClient;
  Session? _session;
  late final LoginManager loginManager;
  late rt.MatchmakerTicket _matchMakeTicket;
  String _currentMatchId = "";

  NetworkManager._() {
    _nakamaClient = getNakamaClient(
      host: serverIp,
      ssl: ssl,
      serverKey: 'defaultkey',
    );

    loginManager = LoginManager(_nakamaClient);
  }

  factory NetworkManager() {
    _instance ??= NetworkManager._(); //if null create instance
    return _instance!;
  }

  shutdown() {
    MatchLogic.closeWebSocket();
    api.SessionLogoutRequest();
  }

  //Checks if there is already a UUID stored on the device,
  //if it doesn't exists this generates a new one and then authenticates with Nakama
  //Takes an optional username
  Future<bool> initialAuth({String? username}) async {
    var uuid = await loginManager.checkDeviceId();
    _session = await loginManager.signInDeviceId(uuid[0], username: username);
    MatchLogic.initWebsocket(_session!);
    return uuid[1];
  }

  //Just generates a new device UUID, does not check for existing
  newDeviceId() async {
    var uuid = loginManager.generateDeviceUUID();
    _session = await loginManager.signInDeviceId(uuid);
    MatchLogic.initWebsocket(_session!);
  }

  Future<bool> createAccount(String email, String password,
      {String? username}) async {
    _session =
        await loginManager.createAccount(email, password, username: username);
    if (_session == null) {
      print("Something went wrong (Email already in use?)");
      return false;
    }
    MatchLogic.initWebsocket(_session!);
    return true;
  }

  //Returns 2 lists, first is the top 10 scores in descending order
  //and the second is the usernames linked to those scores
  Future<List> frontPageLeaderboard() async {
    try {
      var records = await getLeaderboardRecord("points", limit: 9);
      var scores = records.records.map((e) => e.score).toList();
      var usernames = records.records.map((e) => e.username).toList();
      return [scores, usernames];
    } catch (e) {
      rethrow;
    }
  }

  joinMatch(String matchId) async {
    _currentMatchId = matchId;
    return await MatchLogic.joinMatch(matchId);
  }

  listenPresenceEvents() {
    MatchLogic.listenPresenceEvents(_session!.userId);
  }

  Future<String> createMatch() async {
    var match = await MatchLogic.createMatch();
    _currentMatchId = match.matchId;
    return _currentMatchId;
  }

  void leaveMatch() {
    MatchLogic.leaveMatch(_currentMatchId);
  }

  //Used to detect when opponent has joined game
  Stream<rt.MatchPresenceEvent> listenPresence() {
    return MatchLogic.listenJoinEvents();
  }

  //Send data on matchId
  void sendData(String data, int opCode) async {
    await MatchLogic.sendMatchData(_currentMatchId, data, opCode);
  }

  //Send score to backend server
  sendScoreData(int gamemode, int score, int lines) {
    String leaderboardId;
    switch (gamemode) {
      case 1:
        leaderboardId = "points";
        break;
      default:
        leaderboardId = "points";
    }
    _nakamaClient.writeLeaderboardRecord(
        session: _session!,
        leaderboardId: leaderboardId,
        score: score,
        subscore: lines);
  }

  Stream<rt.MatchData> listenMatch() {
    return MatchLogic.listenMatch();
  }

  stopListenMatch(StreamSubscription<rt.MatchData> listener) {
    MatchLogic.stopListening(listener);
  }

  startMatchmake() async {
    _matchMakeTicket =
        await MatchLogic.startMatchmake(); //Can stop matchmaking with ticket
  }

  Future<List<String>> listenMatchmake() async {
    rt.MatchmakerMatched matchResult =
        await MatchLogic.listenToMatchmakeEvents();
    print("MATCH ID ${matchResult.matchId}");
    var match = await MatchLogic.joinMatch(matchResult.matchId,
        token: matchResult.token);
    _currentMatchId = match.matchId;
    return matchResult.users.map((e) => e.presence.username).toList();
  }

  stopMatchMake() {
    MatchLogic.stopMatchmake(_matchMakeTicket.ticket);
  }

  setUsername(String username) {
    NetworkSocial.setUsername(_nakamaClient, _session!, username);
  }

  Future<String> getUsername() async {
    return await NetworkSocial.getUsername(_nakamaClient, _session!);
  }

  Future<Groups> listGroups(token) async {
    var response = await NetworkSocial.listGroups(token);
    for (var group in response.groups) {
      print("Group name ${group.name} \tID ${group.id}");
    }
    return response;
  }

  Future<api.LeaderboardRecordList> getLeaderboardRecord(String leaderboardName,
      {int limit = 20}) async {
    try {
      return await _nakamaClient.listLeaderboardRecords(
          session: _session!, leaderboardName: leaderboardName, limit: limit);
    } catch (e) {
      rethrow;
    }
  }

  Future<Session?> logInAccount(String email, String password) async {
    api.SessionLogoutRequest();
    _session = await loginManager.signInMail(email, password);
    if (_session == null) {
      print("Something went wrong signing in");
      return null;
    }
    MatchLogic.initWebsocket(_session!);
    return _session;
  }
}
