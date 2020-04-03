import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'user_info/user_form.dart';
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
    new VideoPlayerScreen(),
    new VideoLibrary(),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), title: Text('User Profile')),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), title: Text('Current Hole')),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), title: Text('Video Library')),
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