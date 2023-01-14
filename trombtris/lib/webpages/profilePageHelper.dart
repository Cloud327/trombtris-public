import 'package:flutter/material.dart';
import 'package:nakama/api.dart';
import 'package:trombtris/game/network/networkManager.dart';
import 'package:trombtris/game/network/networkSocial.dart';
import 'package:trombtris/webpages/profilePage.dart';

NetworkManager network = NetworkManager();

class friend {
  static Widget addFriend({
    required userToken,
    required friendUser,
    required statFontSize,
    required BuildContext context,
    required isProfileOwner,
    required sender,
  }) {
    return _friendWidget(
        sender, friendUser, context, statFontSize, isProfileOwner);
  }

//
//
//
//
//
//

  static Future<void> _addNewFriends(sender, userToken, context) async {
    TextEditingController friendTEC = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
              controller: friendTEC,
              decoration: InputDecoration(labelText: "Username")),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                NetworkSocial.addFriend(userToken, username: friendTEC.text)
                    .then((value) => sender.getFriends());

                Navigator.pop(context);
              },
              child: const Text('Send Friend Request'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

//
//
//
//
//
//

  static Widget addFriendsButton(sender, senderToken, context, statFontSize) {
    Color color5 = const Color.fromRGBO(50, 194, 216, 1); // sky blue crayola
    Color shade5 = const Color(0xFF65D1E2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        gradient: LinearGradient(
          colors: [shade5, color5],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(color5),
          elevation: MaterialStateProperty.all(10),
          shadowColor: MaterialStateProperty.all<Color>(shade5),
        ),
        onPressed: () async {
          await _addNewFriends(sender, senderToken, context);
        },
        child: Text(
          "Add Friends",
          style: TextStyle(
            fontSize: statFontSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

//
//
//
//
//
  static Future<void> _friendWidgetDialog(
      sender, friendUser, isProfileOwner, context) async {
    // Remove friend / Reject request
    SimpleDialogOption removeFriend = SimpleDialogOption(
      onPressed: () {
        NetworkSocial.removeFriend(userToken, username: friendUser.username)
            .then((value) => sender.getFriends());
        Navigator.pop(context);
      },
      child: (friendUser.state == 2)
          ? const Text('Reject Friend Request')
          : const Text('Remove Friend'),
    );

    // Add friend / Accept request
    var addFriend = (friendUser.state == 2)
        ? SimpleDialogOption(
            onPressed: () {
              NetworkSocial.addFriend(userToken, username: friendUser.username)
                  .then((value) => sender.getFriends());
              Navigator.pop(context);
            },
            child: const Text('Accept Friend Request'),
          )
        : Container();

    SimpleDialogOption blockFriend = SimpleDialogOption(
      onPressed: () {
        NetworkSocial.blockFriend(userToken, username: friendUser.username)
            .then((value) => sender.getFriends());
        Navigator.pop(context);
      },
      child: const Text('Block User'),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(friendUser.username),
          children: <Widget>[
            /*
            // Goto profile page
            SimpleDialogOption(
              onPressed: () {
                // Need session for listFriends()
                // Temp solution only for testing
                network
                    .logInAccount(friendUser.username + "@test.com", "password")
                    .then((value) => {
                          Navigator.pop(context),
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (buildContext) => ProfilePage(
                                user: value,
                                username: friendUser.username,
                                isProfileOwner: false,
                              ),
                            ),
                          )
                        });
              },
              child: const Text('Goto profile'),
            ),
            isProfileOwner ? dialog2 : Container(),
            */
            addFriend,
            removeFriend,
            blockFriend
          ],
        );
      },
    );
  }
//
//
//
//
//

  static Widget _friendWidget(
      sender, friendUser, context, statFontSize, isProfileOwner) {
    var textStyle = TextStyle(
      fontSize: statFontSize,
      overflow: TextOverflow.ellipsis,
      color: Colors.black,
    );

    statusStyle(status) {
      Color c = Colors.black;

      if (status == 0) c = Colors.green;
      if (status == 1) c = Colors.blue;
      if (status == 2) c = Colors.purple;
      if (status == 3) c = Colors.red;

      return TextStyle(
        fontSize: statFontSize / 2,
        overflow: TextOverflow.ellipsis,
        color: isProfileOwner ? c : Colors.transparent,
      );
    }

    Color color3 = const Color.fromRGBO(242, 170, 0, 1);
    Color shade3 = const Color(0xFFFFC234);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        gradient: LinearGradient(
          colors: [shade3, color3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: shade3,
          width: 1.0,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(
        vertical: 1.0,
        horizontal: 6.0,
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
          elevation: MaterialStateProperty.all(10),
          shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () {
          _friendWidgetDialog(sender, friendUser, isProfileOwner, context);
        },
        child: Row(
          children: [
            Expanded(
                flex: 6,
                child: Text(friendUser.username,
                    style: textStyle, textAlign: TextAlign.left)),
            Expanded(
                flex: 4,
                child: Text(_getStatus(friendUser.state),
                    style: statusStyle(friendUser.state),
                    textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }
}

String _getStatus(int status) {
  //State, 0 = vänner, 1 = väntar svar från vännen,
  //2 = tagit emot vänförfrågan men ej svarat,
  //3 = blockat användaren.
  switch (status) {
    case 0:
      return "friends";
    case 1:
      return "request sent";
    case 2:
      return "request received";
    case 3:
      return "blocked";
    default:
      return "";
  }
}
