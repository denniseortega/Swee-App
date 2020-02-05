import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class UserInfoPage extends StatefulWidget {
  UserInfoPage({Key key}) : super(key: key);

  @override
  UserInfoPageState createState() => UserInfoPageState();
}

class UserInfoPageState extends State<UserInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: new Container(
      child: new Center(
        child: new FutureBuilder(
            future:
                DefaultAssetBundle.of(context).loadString('assets/users.json'),
            builder: (context, snapshot) {
              var users = json.decode(snapshot.data.toString());

              return new ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  var user = users[index];
                  return new Card(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        new Text("Name: " + user['name'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24)),
                        new Image.network(user['image'], height: 200)
                      ],
                    ),
                  );
                },
                itemCount: users == null ? 0 : users.length,
              );
            }),
      ),
    ));
  }
}








































