import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'user_info/user_form.dart';
import 'imageselector/image_selector.dart';
import 'video/video.dart';
import 'connectivity/wifi_dev.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final widgetOptions = [
    new UserForm(),
    new ImageSelector(),
    new VideoPlayerScreen(),
    new WifiDev(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swee App'),
      ),
      body: Center(
        child: widgetOptions.elementAt(selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[800],
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.person), title: Text('Home')),
          BottomNavigationBarItem(icon: Icon(Icons.person), title: Text('New User')),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), title: Text('Video')),
          BottomNavigationBarItem(icon: Icon(Icons.network_wifi), title: Text('WifiDev')),
          ],
        currentIndex: selectedIndex,
        fixedColor: Colors.deepPurple[300],
        onTap: onItemTapped,
      ),
    );
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }
}





























































// import 'package:flutter/material.dart';


// class MyHomePage extends StatelessWidget {

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       body: SafeArea(
//           child: Column(children: <Widget>[
//           Image.asset("images/manface.png"),
//           FlatButton(
//             child: Text("Take Picture", style: TextStyle(color: Colors.white)),
//             color: Colors.blue, 
//             onPressed: () {},
//           )
//         ]),
//       )
//     );

//   }

// }