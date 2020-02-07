import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'user_info/user_info.dart';
import 'user_info/user_form.dart';
// import 'camera/camera.dart';
import 'imageselector/image_selector.dart';
import 'video/video.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final widgetOptions = [
    // new UserInfoPage(),
    new UserForm(),
    // new CameraWidget(),
    new ImageSelector(),
    new VideoPlayerScreen(),
    // Text('Swee Profile'),
    // Text('Add User'),
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
        backgroundColor: Colors.white,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text('Home')),
          BottomNavigationBarItem(icon: Icon(Icons.person), title: Text('New User')),
          // BottomNavigationBarItem(icon: Icon(Icons.person), title: Text('Profile')),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.add_a_photo), title: Text('Upload Photo')),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), title: Text('Video')),
          ],
        currentIndex: selectedIndex,
        fixedColor: Colors.deepPurple,
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