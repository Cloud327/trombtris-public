import 'dart:convert';
import 'dart:io';

import 'package:nakama/api.dart' as api;
import 'package:nakama/nakama.dart';
import 'package:nakama/rtapi.dart' as rt;
import 'package:http/http.dart' as http;
import 'package:trombtris/game/network/server_info.dart';

class NetworkSocial {
  static Future<Groups> listGroups(String token,
      {int limit = 20, String filter = "", int cursor = 0}) async {
    String uri = 'http://137.135.221.12:7350/v2/group?limit=$limit';
    if (filter != "") {
      uri = '$uri&name=$filter';
    }
    if (cursor != 0) {
      uri = '$uri&cursor=$cursor';
    }
    final response = await http.get(
        Uri.parse('$uri&accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    Map<String, dynamic> groupMap = jsonDecode(response.body);
    print(groupMap);
    return Groups.fromJson(groupMap); //Return groups
  }

  static listMyGroups(String token, String userId) async {
    final response = await http.get(
        Uri.parse(
            'http://$serverIp:7350/v2/user/$userId/group?accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    return response.body;
  }

  static createGroup(NakamaBaseClient client, String token, String name,
      {String description = "", bool open = true}) async {
    final response = await http.post(
      Uri.parse(
          'http://137.135.221.12:7350/v2/group?Accept=application/json&Content-Type=application/json'),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $token",
      },
      body: jsonEncode(<String, String>{
        "name": name,
        "description": description,
        "lang_tag": "en_US",
        "open": open.toString()
      }),
    );
    return response.body;
  }

  static joinGroup(String token, String groupId) async {
    final response = await http.post(
        Uri.parse(
            '137.135.221.12:7350/v2/group/$groupId/join?Accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    return response.body;
  }

  static leaveGroup(String token, String groupId) {
    final response = http.post(
        Uri.parse(
            '137.135.221.12:7350/v2/group/$groupId/leave?Accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    return response;
  }

  static Future<Friends> listFriends(String token,
      {int limit = 20, state = 0}) async {
    String uri = 'http://137.135.221.12:7350/v2/friend?limit=$limit';
    if (state != 0) {
      uri = '$uri&state=$state';
    }
    final response = await http.get(
        Uri.parse('$uri&accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    Map<String, dynamic> friendMap = jsonDecode(response.body);
    return Friends.fromJson(friendMap);
  }

  static Future<http.Response> addFriend(String token,
      {String? userId, String? username}) async {
    String uri = 'http://137.135.221.12:7350/v2/friend?';
    if (userId == null && username == null) {
      throw Exception("No users given");
    }
    if (userId != null) {
      uri = '$uri&ids=$userId';
    }
    if (username != null) {
      uri = '$uri&usernames=$username';
    }
    final response = await http.post(
        Uri.parse('$uri&Accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    return response;
  }

  static Future<http.Response> removeFriend(String token,
      {String? userId, String? username}) async {
    String uri = 'http://137.135.221.12:7350/v2/friend?';
    if (userId == null && username == null) {
      throw Exception("No users given");
    }
    if (userId != null) {
      uri = '$uri&ids=$userId';
    }
    if (username != null) {
      uri = '$uri&usernames=$username';
    }
    final response = await http.delete(
        Uri.parse('$uri&Accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    return response;
  }

  static Future<http.Response> blockFriend(String token,
      {String? userId, String? username}) async {
    String uri = 'http://137.135.221.12:7350/v2/friend/block?';
    if (userId == null && username == null) {
      throw Exception("No users given");
    }
    if (userId != null) {
      uri = '$uri&ids=$userId';
    }
    if (username != null) {
      uri = '$uri&usernames=$username';
    }
    final response = await http.post(
        Uri.parse('$uri&Accept=application/json&Content-Type=application/json'),
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
        });
    return response;
  }

  // 1 = Room, 2 = Direct Message, 3 = Group
  static Future<rt.Channel?> joinChat(String chatId, int type,
      {hidden = false}) async {
    rt.ChannelJoin_Type chatType;
    switch (type) {
      case 1:
        chatType = rt.ChannelJoin_Type.ROOM;
        break;
      case 2:
        chatType = rt.ChannelJoin_Type.DIRECT_MESSAGE;
        break;
      case 3:
        chatType = rt.ChannelJoin_Type.GROUP;
        break;
      default:
        throw const FormatException("Invalid channeltype");
    }
    rt.Channel? channel = await NakamaWebsocketClient.instance.joinChannel(
        target: chatId, type: chatType, persistence: true, hidden: hidden);
    return channel;
  }

  static Future<rt.ChannelMessageAck?> sendChatMessage(
      String chatId, String message) async {
    Map<String, String> content = {"Message": message};
    rt.ChannelMessageAck? ack = await NakamaWebsocketClient.instance
        .sendMessage(channelId: chatId, content: content);
    return ack;
  }

  static Future<api.ChannelMessageList?> getChatHistory(
      String chatId, NakamaBaseClient client, Session session,
      {int numMessages = 20}) async {
    return await client.listChannelMessages(
        session: session, channelId: chatId, limit: numMessages);
  }

  static void setUsername(
      NakamaBaseClient client, Session session, String username) {
    client.updateAccount(
        session: session, username: username, displayName: username);
  }

  static Future<String> getUsername(NakamaBaseClient client, Session session) async{
    var account = await client.getAccount(session);
    return account.user.displayName;
  }
}


class Groups {
  final List<Group> groups;

  Groups({
    required this.groups,
  });

  factory Groups.fromJson(Map<String, dynamic> json) {
    final groupData = json['groups'] as List<dynamic>?;
    final groups = groupData != null
        ? groupData.map((groupData) => Group.fromJson(groupData)).toList()
        : <Group>[];
    return Groups(groups: groups);
  }
}

class Group {
  Group(
      {this.id,
      this.creatorId,
      this.name,
      this.description,
      this.langTag,
      this.open,
      this.edgeCount,
      this.maxCount,
      this.createTime,
      this.updateTime,
      this.metadata});
  final String? id;
  final String? creatorId;
  final String? name;
  final String? description;
  final String? langTag;
  final String? metadata;
  final bool? open;
  final int? edgeCount;
  final int? maxCount;
  final String? createTime;
  final String? updateTime;

  factory Group.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final creatorId = json['creatorId'] as String?;
    final name = json['name'] as String?;
    final description = json['description'] as String?;
    final langTag = json['langTag'] as String?;
    final metadata = json['metadata'] as String?;
    final open = json['open'] as bool?;
    final edgeCount = json['edgeCount'] as int?;
    final maxCount = json['maxCount'] as int?;
    final createTime = json['createTime'] as String?;
    final updateTime = json['updateTime'] as String?;

    return Group(
      id: id,
      creatorId: creatorId,
      name: name,
      description: description,
      langTag: langTag,
      metadata: metadata,
      open: open,
      edgeCount: edgeCount,
      maxCount: maxCount,
      createTime: createTime,
      updateTime: updateTime,
    );
  }
}

class Friends {
  final List<User> friends;

  Friends({
    required this.friends,
  });

  factory Friends.fromJson(Map<String, dynamic> json) {
    final friendData = json['friends'] as List<dynamic>?;
    final users = friendData != null
        ? friendData.map((friendData) => User.fromJson(friendData)).toList()
        : <User>[];
    return Friends(friends: users);
  }
}

//Sista (-id) vi vill presentera kommer härifrån
class User {
  User({this.id, this.username, this.state});
  final String? id;
  final String? username;
  final int? state;

  factory User.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final id = user['id'] as String?;
    final username = user['username'] as String?;
    final state = json['state'];
    return User(id: id, username: username, state: state);
  }
}
