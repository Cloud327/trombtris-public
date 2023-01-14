import 'dart:async';

import 'package:nakama/nakama.dart';
import 'package:nakama/rtapi.dart' as rt;
import 'package:trombtris/game/network/server_info.dart';

class MatchLogic {
  static initWebsocket(Session session) {
    NakamaWebsocketClient.init(
        host: serverIp, ssl: ssl, token: session.token);
  }

  static closeWebSocket() {
    NakamaWebsocketClient.instance.close();
  }

  static Future<rt.Match> joinMatch(String matchId, {String? token}) async {
    rt.Match match;
    if (matchId == "" && token == null) {
      throw Exception("Must have matchId or token");
    }
    if (matchId == "") {
      match =
          await NakamaWebsocketClient.instance.joinMatch(matchId, token: token);
    } else {
      match = await NakamaWebsocketClient.instance.joinMatch(matchId);
    }
    return match;
  }

  //Prints when people join/leave
  static listenPresenceEvents(String userId) {
    print("Listening to join events");
    NakamaWebsocketClient.instance.onMatchPresence.listen((event) {
      if (event.leaves.isNotEmpty) {
        print("${event.leaves.single.username} left");
      } else if (event.joins.single.userId != userId) {
        print("${event.joins.single.username} joined");
      }
    });
  }

  //General stream for match presences (join/leave events)
  static Stream<rt.MatchPresenceEvent> listenJoinEvents() {
    return NakamaWebsocketClient.instance.onMatchPresence;
  }

  //Creates match and returns it
  static Future<rt.Match> createMatch() async {
    var match = await NakamaWebsocketClient.instance.createMatch();
    print('MatchId: ${match.matchId}');
    return match;
  }

  static void leaveMatch(String matchId) {
    NakamaWebsocketClient.instance.leaveMatch(matchId);
  }

  static Future<rt.MatchmakerTicket> startMatchmake(
      {String query = "*", int maxPlayers = 2}) async {
    rt.MatchmakerTicket ticket = await NakamaWebsocketClient.instance
        .addMatchmaker(minCount: 2, maxCount: maxPlayers, query: query);
    return ticket;
  }

  static stopMatchmake(String ticket) {
    NakamaWebsocketClient.instance.removeMatchmaker(ticket);
  }

  //Waits for matchmaker to find a game and then joins the match
  static Future<rt.MatchmakerMatched> listenToMatchmakeEvents() async {
    rt.MatchmakerMatched matchResult =
        await NakamaWebsocketClient.instance.onMatchmakerMatched.first;
    print("Match found!");
    print("Token : ${matchResult.token} \nMatchId : ${matchResult.matchId}");
    for (var element in matchResult.users) {
      print(
          "Username/ID: ${element.presence.username} \t ${element.presence.userId}");
    }
    return matchResult;
  }

  //General stream for matchData
  static Stream<rt.MatchData> listenMatch() {
    return NakamaWebsocketClient.instance.onMatchData;
  }

  static void stopListening(StreamSubscription<dynamic> listener) {
    listener.cancel();
  }

  //Sends data as list of Ints, decode with utf8.decode on other end
  static sendMatchData(String matchId, String message, int opCode) async {
    await NakamaWebsocketClient.instance.sendMatchData(
      matchId: matchId,
      opCode: Int64(opCode),
      data: message.codeUnits,
    );
  }
}
