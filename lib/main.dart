import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';

void main() async {
  // Ensure FlutterDownloader is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // await FlutterDownloader.initialize(); // TODO: This doesn't seem to work with hot reload... but it seems to work fine through Runner?!

  runApp(
    // User a provider to provide variables across widgets
    ChangeNotifierProvider(
      create: (context) => SweeUser(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swee',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue[800],
        accentColor: Colors.cyan[600],

        //Default font family
        fontFamily: 'Roboto'
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
  bool flutterDownloaderInitialized = false;
  // var videoPaths = List();
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

  void setRegistration(registrationStatus) {
    isRegistered = registrationStatus;
    notifyListeners();
  }

  void setFlutterDownloaderInitialized(initStatus) {
    flutterDownloaderInitialized = initStatus;
    notifyListeners();
  }
}