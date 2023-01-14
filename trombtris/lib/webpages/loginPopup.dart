import 'package:flutter/material.dart';
import 'package:nakama/api.dart';
import 'package:trombtris/game/network/networkManager.dart';
import 'package:trombtris/webpages/registerPopup.dart';
import 'package:trombtris/webpages/profilePage.dart';

import 'package:nakama/nakama.dart';

var usernameTEC = TextEditingController();
var passwordTEC = TextEditingController();
NetworkManager network = NetworkManager();
var user;

Future<bool> signIn(String username, String password) async {
  //user = await network.loginManager.signInMail(username, password);
  user = await network.logInAccount(username, password);
  if (user == null) {
    return false;
  }
  return true;
}

// Popup
class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  State<LoginPopup> createState() => _LoginPopup();
}

class _LoginPopup extends State<LoginPopup> {
  var usernameTEC = TextEditingController();
  var passwordTEC = TextEditingController();

  var errText = ""; //"wrong username/password";

  Color blueDarker = const Color(0xFF2095A7);
  Color blue = const Color.fromRGBO(50, 194, 216, 1);

  @override
  Widget build(BuildContext context) {
    //
    // submit button
    var submitButton = ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(blue),
        elevation: MaterialStateProperty.all(10),
        shadowColor: MaterialStateProperty.all<Color>(blueDarker),
      ),
      onPressed: () {
        signIn(usernameTEC.text, passwordTEC.text).then((value) => {
              if (value)
                {
                  Navigator.of(context).pop(),
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (buildContext) => ProfilePage(
                              user: user,
                              username: usernameTEC.text,
                              isProfileOwner: true,
                            )),
                  ),
                }
              else
                {
                  setState(() {
                    errText = "wrong username/password";
                  }),
                }
            });
      },
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Text("Log in", style: TextStyle(color: Colors.white)),
      ),
    );

    //
    // popup window
    var loginWindow = Container(
      alignment: Alignment.center,
      child: Container(
        width: 400,
        height: 280.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF2095A7),
            title: const Text("Login"),
          ),
          body: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 8.0,
            ),
            child: Column(
              children: [
                inputField('Username', "Enter Username", usernameTEC),
                const SizedBox(height: 6.0), // spacers
                inputField('Password', "Enter Password", passwordTEC,
                    obscureText: true),
                const SizedBox(height: 5.0), // spacers
                Text(errText, style: TextStyle(color: Colors.red)),
                const SizedBox(height: 5.0), // spacers
                submitButton,
                const SizedBox(height: 5.0), // spacers
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.transparent),
                    shadowColor:
                        MaterialStateProperty.all<Color>(Colors.transparent),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return RegisterPopup();
                      },
                    );
                  },
                  child: Text("Register",
                      style: TextStyle(color: Colors.blue[700])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return loginWindow;
  }

  Flexible inputField(
      String? labelText, String? hintText, TextEditingController? controller,
      {bool obscureText = false}) {
    return Flexible(
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: labelText,
          hintText: hintText,
        ),
      ),
    );
  }
}
