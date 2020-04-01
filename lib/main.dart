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
  String username = 'Default User Name';
  String deviceIP = 'Default.Device.IP';
  List<String> imagePaths = List.filled(3,'');//[];
  bool isRegistered = false;
  List<String> videoPaths = [];
  List<String> videoPathsLocal = [];
  String mainNodeIP = '192.168.4.1:5001';
  String secondaryNodeIP = 'NaN.NaN.NaN.NaN';

  
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

  void addVideoPath(path) {
    videoPaths.add(path);
    notifyListeners();
  }

  void addVideoPathLocal(path) {
    videoPathsLocal.add(path);
    notifyListeners();
  }

  void clearVideoPath() {
    videoPaths = [];
    notifyListeners();
  }

  void clearVideoPathLocal() {
    videoPathsLocal = [];
    notifyListeners();
  }

  void setRegistration(registrationStatus) {
    isRegistered = registrationStatus;
    notifyListeners();
  }
}