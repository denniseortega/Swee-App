import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';

void main() async {
  runApp(
    // User a provider to provide variables across widgets
    ChangeNotifierProvider(
      create: (context) => SweeUser(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swee',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue[800],
        accentColor: Colors.cyan[600],
        fontFamily: 'Roboto' //Default font family
      ),
      home: HomePage(),
    );
  }
}

// Define a "SweeUser" class that can be consumed by all of the MyApp's child widgets
class SweeUser with ChangeNotifier {
  String username = 'DefaultUsername';
  String deviceIP = 'Default.Device.IP';
  List<String> imagePaths = List.filled(3,'');
  List<String> imagePathsRotated = List.filled(3,'');
  bool isRegistered = false;
  List<String> videoPaths = []; // *all* videoPaths on the Swee server - used to keep track of which videos have been downloaded already
  List<String> videoPathsLocal = []; // videoPaths of videos that have been downloaded to the phone - used to build the video_library.dart
  List<String> videoPathsCurrentHole = []; // videoPaths on the Swee server for the *current hole* - used to build video.dart
  String mainNodeIP = '192.168.4.1:5001';
  String secondaryNodeIP = 'NaN.NaN.NaN.NaN';
  String wifiName = 'DefaultWifiName';
  
  void setUsername(name) {
    username = name;
    notifyListeners();
  }

  void setDeviceIP(ip) {
    deviceIP = ip;
    notifyListeners();
  }

  void addImagePath(index,path) {
    imagePaths[index]=path;
    notifyListeners();
  }

  void setImagePaths(List<String> imagePathsIn) {
    imagePaths = imagePathsIn;
    notifyListeners();
  }

  void addImagePathRotated(index,pathRotated) {
    imagePathsRotated[index]=pathRotated;
    notifyListeners();
  }

  void setImagePathsRotated(List<String> imagePathsRotatedIn) {
    imagePathsRotated = imagePathsRotatedIn;
    notifyListeners();
  }

  void addVideoPath(path) {
    videoPaths.add(path);
    notifyListeners();
  }

  void addVideoPathLocal(path) {
    videoPathsLocal.add(path);
    notifyListeners();
  }

  void addVideoPathCurrentHole(path) {
    videoPathsCurrentHole.add(path);
    notifyListeners();
  }

  void clearVideoPaths() {
    videoPaths = [];
    notifyListeners();
  }

  void clearVideoPathsLocal() {
    videoPathsLocal = [];
    notifyListeners();
  }

  void clearVideoPathsCurrentHole() {
    videoPathsCurrentHole = [];
    notifyListeners();
  }

  void setVideoPaths(List<String> videoPathsIn) {
    videoPaths = videoPathsIn;
    notifyListeners();
  }

  void setVideoPathsLocal(List<String> videoPathsLocalIn) {
    videoPathsLocal = videoPathsLocalIn;
    notifyListeners();
  }

  void setVideoPathsCurrentHole(List<String> videoPathsCurrentHoleIn) {
    videoPathsCurrentHole = videoPathsCurrentHoleIn;
    notifyListeners();
  }

  void setRegistration(registrationStatus) {
    isRegistered = registrationStatus;
    notifyListeners();
  }

  void setWifiName(wifiNameIn) {
    wifiName = wifiNameIn;
    notifyListeners();
  }
}