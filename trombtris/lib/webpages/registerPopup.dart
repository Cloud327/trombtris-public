import 'dart:html';

import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:trombtris/game/network/networkManager.dart';
import 'package:trombtris/webpages/startPage.dart';
import 'package:trombtris/webpages/profilePage.dart';

NetworkManager network = NetworkManager();
var user;

// TODO: connect to backend
Future<bool> signUp(String username, String email, String password) async {
  user = await network.loginManager
      .createAccount(email, password, username: username);

  if (user == null) {
    return false;
  }

  return true;
}

// Popup
class RegisterPopup extends StatefulWidget {
  const RegisterPopup({super.key});

  @override
  State<RegisterPopup> createState() => _RegisterPopup();
}

class _RegisterPopup extends State<RegisterPopup> {
  var usernameTEC = TextEditingController();
  var passwordTEC = TextEditingController();
  var emailTEC = TextEditingController();

  Color blueDarker = const Color(0xFF2095A7);
  Color blue = const Color.fromRGBO(50, 194, 216, 1);

  var errText = ""; // "invalid username/email/password";
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
        signUp(usernameTEC.text, emailTEC.text, passwordTEC.text)
            .then((value) => {
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
                        errText = "invalid username/email/password";
                      }),
                    }
                });
      },
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Text("Sign up", style: TextStyle(color: Colors.white)),
      ),
    );

    //
    // popup window
    var registerWindow = Container(
      alignment: Alignment.center,
      child: Container(
        width: 400.0,
        height: 330.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(
            color: Colors.black38,
            width: 2.0,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: blueDarker,
            title: const Text("Signup"),
          ),
          body: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 8.0,
            ),
            child: Column(
              children: [
                inputField('Username', "Enter Username!", usernameTEC),
                const SizedBox(height: 6.0), // spacers
                inputField('Email', "Enter email address!", emailTEC),
                const SizedBox(height: 6.0), // spacers
                inputField('Password', "Enter Password!", passwordTEC,
                    obscureText: true),
                const SizedBox(height: 5.0), // spacers
                Text(errText, style: TextStyle(color: Colors.red)),
                const SizedBox(height: 5.0), // spacers

                submitButton,
              ],
            ),
          ),
        ),
      ),
    );

    return registerWindow;
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
