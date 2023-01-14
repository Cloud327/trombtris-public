import 'dart:math';

import 'package:trombtris/webpages/startPage.dart';
import 'package:flutter/material.dart';
import 'package:trombtris/game/network/networkManager.dart';

void main() async {
  final network = NetworkManager();
  int userNumber =
      100000 + Random().nextInt(999999 - 100000); //six digit random number
  try {
    //test connection to backend server and create a match
    network.initialAuth(username: "Guest-$userNumber");
  } catch (e) {
    print("Backend server cannot be reached.");
    print(e);
  }
  runApp(MaterialApp(home: StartPage()));
}
