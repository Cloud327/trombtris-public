import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:nakama/src/api/proto/api/api.pb.dart';
import 'package:trombtris/game/network/networkManager.dart';
import 'package:trombtris/webpages/loginPopup.dart';
import 'package:trombtris/game/network/networkSocial.dart';
import 'package:trombtris/webpages/profilePageHelper.dart';

var userToken = user.token;
int friendCounter = 0;
String _username = "Username";
var user;
bool owner = true;

List<Widget> right = [Text("No friends")];

class ProfilePage extends StatefulWidget {
  const ProfilePage(
      {super.key,
      required this.user,
      required this.username,
      required this.isProfileOwner});
  final dynamic user;
  final String username;
  final bool isProfileOwner;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController usernameTEC = TextEditingController();
  late FocusNode _node;

  bool editable = false;
  InputBorder border = InputBorder.none;

  //late double usernameFontSize;
  late double statFontSize;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    userToken = user.token;
    owner = widget.isProfileOwner;

    _username = widget.username;
    usernameTEC.text = _username;
    _node = FocusNode();
    _node.addListener(_handleFocusChange);

    getFriends();
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 700;

  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    var deviceData = MediaQuery.of(context);

    double usernameFontSize;
    //double statFontSize;
    if (isDesktop(context)) {
      usernameFontSize = deviceData.size.width * 0.025;
      statFontSize = deviceData.size.width * 0.02;
    } else {
      usernameFontSize = deviceData.size.width * 0.05;
      statFontSize = deviceData.size.width * 0.04;
    }

    Color color1 = const Color.fromRGBO(50, 57, 63, 1); // gunmetal
    Color color4 = const Color.fromRGBO(192, 20, 113, 1);
    Color shade4 = Color.fromARGB(255, 253, 253, 253);

    Decoration listDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(5.0),
      gradient: LinearGradient(
          colors: [Colors.white, shade4],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      border: Border.all(color: color4, width: 1.0),
    );

    Decoration FriendsDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(5.0),
      gradient: LinearGradient(
          colors: [color4, color4],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      border: Border.all(color: color4, width: 1.0),
    );

    var leftStats = [
      "Games Played",
      "Highest Round",
      "High Score",
      "Lines Cleared",
      "Tetris Line Clears",
      "Lorem",
      "ipsum",
      "dolor",
    ];

    var leftValues = [
      "326",
      "18",
      "333",
      "22",
      "0",
      "Single Player",
      "1048",
      "12",
    ];

    var userIcon = Image.network(
        "https://cdn.pixabay.com/photo/2019/08/11/18/59/icon-4399701_1280.png");

//
//
//  testing
    leftValues[0] = "${user.userId}";
    leftValues[1] = "${user.token}";
//
//
//

// Left side
    Widget leftSide() {
      var textField = TextField(
          readOnly: !editable,
          controller: usernameTEC,
          focusNode: _node,
          onSubmitted: (value) {
            setState(() {
              editable = false;
              border = InputBorder.none;
            });
          },
          onEditingComplete: () async {
            await showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Change username'),
                  content: Text('Change username to "${usernameTEC.text}"?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          setUsername(usernameTEC.text);
                          owner = true;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          usernameTEC.text = _username;
                          owner = true;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          },
          style: TextStyle(
            fontSize: usernameFontSize,
            color: Colors.white,
          ),
          decoration: InputDecoration(border: border));
      //
      //
      return Padding(
          padding: const EdgeInsets.all(25),
          child: Row(
            children: [
              Expanded(flex: 1, child: Container()), // Spacer
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // Top - Pic, username
                    Expanded(flex: 1, child: Container()), // Spacer
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          // Pic
                          Expanded(
                            flex: 8,
                            child: Container(
                              alignment: Alignment.topLeft,
                              margin: const EdgeInsets.all(3.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                                /*
                                // Make pic clickable                                
                                child: TextButton(
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty
                                        .resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.hovered)) {
                                        return const Color.fromARGB(
                                            100, 0, 0, 0);
                                      }
                                    }),
                                  ),
                                  onPressed: () {
                                    changePic();
                                  },
                                  child: userIcon,                                 
                                ),
                                */
                                child: userIcon,
                              ),
                            ),
                          ),

                          Expanded(flex: 1, child: Container()), // Spacer

                          // Username
                          Expanded(
                            flex: 12,
                            child: Container(
                              alignment: Alignment.topLeft,
                              margin: const EdgeInsets.all(3.0),
                              child: textField,
                            ),
                          ),

                          // Edit name btn
                          Expanded(
                              flex: 2,
                              child: (!owner)
                                  ? Container()
                                  : Container(
                                      alignment: Alignment.topRight,
                                      child: IconButton(
                                        onPressed: _editName,
                                        icon: const Icon(Icons.edit),
                                      ),
                                    )),
                        ],
                      ),
                    ),

                    // Bottom - leftStat
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 15,
                        color: Colors.black,
                        child: Container(
                          margin: const EdgeInsets.all(3.0),
                          decoration: listDecoration,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 6.0),
                            children: List.generate(leftStats.length, (index) {
                              return Text(
                                leftStats[index] + ": " + leftValues[index],
                                style: TextStyle(fontSize: statFontSize),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),

                    Expanded(flex: 1, child: Container()), // Spacer
                  ],
                ),
              ),
              Expanded(flex: 1, child: Container()), // Spacer
            ],
          ));
    }

//
//
//
//
//
    Widget rightSide() {
      return Padding(
        padding: const EdgeInsets.all(25),
        child: Row(
          children: [
            Expanded(flex: 1, child: Container()), // Spacer
            // rightStats
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(flex: 1, child: Container()),
                  Expanded(
                    flex: 5,
                    child: Card(
                        elevation: 15,
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 67,
                              child: Container(
                                margin: const EdgeInsets.all(3.0),
                                decoration: FriendsDecoration,
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5.0, horizontal: 6.0),
                                  children: [
                                        const SizedBox(height: 10),
                                        Text(
                                          "Friends",
                                          style: TextStyle(
                                            fontSize: usernameFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                      ] +
                                      right,
                                ),
                              ),
                            ),
                            Expanded(flex: 1, child: Container()),
                            Expanded(
                              flex: 6,
                              child: (!owner)
                                  ? Container()
                                  : friend.addFriendsButton(
                                      this, userToken, context, statFontSize),
                            ),
                            Expanded(flex: 1, child: Container()),
                          ],
                        )),
                  ),
                  Expanded(flex: 1, child: Container()), // Spacer
                ],
              ),
            ),
            Expanded(flex: 1, child: Container()), // Spacer
          ],
        ),
      );
    }

//
//
//
//

    Widget desktopLayout() {
      return Stack(fit: StackFit.expand, children: [
        Positioned(
            // alignment: Alignment(-0.94, -0.88),
            top: 50,
            left: 50,
            child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image(
                      height: deviceData.size.height * 0.2,
                      image: AssetImage("tromb_logo_magenta_dye.png"),
                    )))),
        Row(
          children: [
            Expanded(flex: 1, child: Container()), // Spacer
            Expanded(flex: 5, child: leftSide()),
            Expanded(flex: 5, child: rightSide()),
            Expanded(flex: 1, child: Container()), // Spacer
          ],
        )
      ]);
    }

    Widget mobileLayout() {
      return ListView(
        children: [
          SizedBox(height: deviceData.size.height * 0.7, child: leftSide()),
          SizedBox(height: deviceData.size.height * 0.7, child: rightSide()),
        ],
      );
    }

    //
    //
    //
    //

    return MaterialApp(
        title: 'Trombtris',
        theme: ThemeData(
          fontFamily: 'Galano Grotesque',
        ),
        home: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("trombtrisbackground.png"),
                fit: BoxFit.cover),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: isDesktop(context) ? desktopLayout() : mobileLayout(),
          ),
        ));
  }

//
//
//

  void _editName() {
    setState(() {
      editable = true;
      border = const UnderlineInputBorder();
      _node.requestFocus();
      usernameTEC.clear();
    });
  }

//TODO connect to backend?
  void setUsername(String value) {
    setState(() {
      _username = value;
    });
  }

//Unplanned
  void changePic() {
    debugPrint("Change profile pic");
  }

  void _handleFocusChange() {
    if (!_node.hasFocus && editable) {
      setState(() {
        editable = false;
        border = InputBorder.none;
        usernameTEC.text = _username;
      });
    }
    ;
  }

  void getFriends() async {
    List<Widget> tmp = [];

    NetworkSocial.listFriends(userToken).then(
      (Friends response) => {
        for (var u in response.friends)
          {
            if (owner || u.state == 0)
              {
                tmp.add(friend.addFriend(
                    userToken: userToken,
                    friendUser: u,
                    statFontSize: statFontSize,
                    context: context,
                    isProfileOwner: owner,
                    sender: this)),
              }
          },
        setState(() {
          if (tmp != []) {
            right = tmp;
          }
        }),
      },
    );
  }
}
