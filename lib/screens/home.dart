import 'package:flutter/material.dart';


class MyHomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
          child: Column(children: <Widget>[
          Image.asset("images/face.png"),
          FlatButton(
            child: Text("Take Picture", style: TextStyle(color: Colors.white)),
            color: Colors.blue, 
            onPressed: () {},
          )
        ]),
      )
    );

  }

}