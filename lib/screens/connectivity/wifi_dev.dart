import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_ip/get_ip.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Lots of connectivity package related code borrowed from connectivity docs: https://pub.dev/packages/connectivity

String _mainNodeIP = '192.168.0.183';//'127.0.0.1:5001';
// String _secondaryNodeIP = 'NaN';

class WifiDev extends StatefulWidget {
  WifiDev({Key key}) : super(key: key);

  @override
  WifiDevState createState() => WifiDevState();
}

class WifiDevState extends State<WifiDev> {
  int selectedIndex = 0;
  String _deviceIP = 'Default Device IP';
  List<String> _imagePaths = ['phone/folder/path1','phone/folder/path2','phone/folder/path3'];
  String _connectionStatus = 'Unknown';
  bool _profileUploaded = false;
  String _username = 'Default User Name';
  Future<Post> post;
  Timer _timer;
  int _counter = 0;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final widgetOptions = [
//    new UserListPage(),
//    new CameraWidget(),
//    Text('Swee Profile'),
//    Text('Add User'),
  ];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initConnectivity();
    post = fetchPost();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) => checkForNewVideos());
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void checkForNewVideos() async {
    _counter++;
    print('video check: $_counter');
    // var uri = Uri.parse('http://$_mainNodeIP/user/video');
    // var response = await http.post(uri,body:{'username':_username});

    // if (response.statusCode==200) {
      // print('new video found');

      // insert call here to download video
    // }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

//    await _getDeviceIP();

    return _updateConnectionStatus(result);
  }

//   Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String ipAddress;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      ipAddress = await GetIp.ipAddress;
    } on PlatformException {
      ipAddress = 'Failed to get ipAdress.';
    }

    if (!mounted) return;

    setState(() {
      _deviceIP = ipAddress;
    });

    print('Device IP is: $_deviceIP');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wifi Dev'),
      ),
      body: Column(children:<Widget>[Center(child: Text('Connection Status: $_connectionStatus')),
        SizedBox(height:25),
        Center(child: Text('There should be something else here.')),
        SizedBox(height:25),
        Center(child: FutureBuilder<Post>(
          future: post,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.title);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            // By default, show a loading spinner.
            return CircularProgressIndicator();
          },
        ),
        )
      ]),
    );
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        String wifiName, wifiBSSID, wifiIP;

        try {
          if (Platform.isIOS) {
            LocationAuthorizationStatus status =
            await _connectivity.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status =
              await _connectivity.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiName = await _connectivity.getWifiName();
            } else {
              wifiName = await _connectivity.getWifiName();
            }
          } else {
            wifiName = await _connectivity.getWifiName();
          }
        } on PlatformException catch (e) {
          print(e.toString());
          wifiName = "Failed to get Wifi Name";
        }

        try {
          if (Platform.isIOS) {
            LocationAuthorizationStatus status =
            await _connectivity.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status =
              await _connectivity.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiBSSID = await _connectivity.getWifiBSSID();
            } else {
              wifiBSSID = await _connectivity.getWifiBSSID();
            }
          } else {
            wifiBSSID = await _connectivity.getWifiBSSID();
          }
        } on PlatformException catch (e) {
          print(e.toString());
          wifiBSSID = "Failed to get Wifi BSSID";
        }

        try {
          wifiIP = await _connectivity.getWifiIP();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiIP = "Failed to get Wifi IP";
        }

        print('set state');
        setState(() {
          _connectionStatus = '$result\n'
              'Wifi Name: $wifiName\n'
              'Wifi BSSID: $wifiBSSID\n'
              'Wifi IP: $wifiIP';
        });

        if (_profileUploaded) {
          _uploadProfile(result.toString());
        }
        setState((){_profileUploaded = true;});
        break;
      case ConnectivityResult.mobile:
        setState(() => _connectionStatus = result.toString());
        setState((){_profileUploaded = false;});
        _uploadProfile(result.toString());
        break;
      case ConnectivityResult.none:
        setState(() => _connectionStatus = result.toString());
        setState((){_profileUploaded = false;});
        _uploadProfile(result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        setState((){_profileUploaded = false;});
        _uploadProfile(result.toString());
        break;
    }
  }

  Future<void> _uploadProfile(result) async {
    if (result=='ConnectivityResult.wifi') {
      print('User: $_username');
      print('Device IP: $_deviceIP');
      for(var i = 0; i<_imagePaths.length; i++){
        String p = _imagePaths[i];
        print('Uploaded $p\n');
        sleep(const Duration(seconds: 1));
      }
    }
    else {
      print('Nothing to see here!!!!');
    }
  }
}

Future<Post> fetchPost() async {
  // Demo function for http fetching a post
  final response =
  await http.get('https://jsonplaceholder.typicode.com/posts/1');

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON.
    return Post.fromJson(json.decode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

class Post {
  // Post class associated with fetchPost() demo function
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({this.userId, this.id, this.title, this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

fetchVideo() {
  const period = const Duration(seconds: 5);
  new Timer.periodic(period,(Timer t) => _fetchVideo());
}

Future<Video> _fetchVideo() async {
  final response =
      await http.get('https://jsonplaceholder.typicode.com/posts/1');

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON.
    return Video.fromJson(json.decode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

class Video {
  final int userId;
  final int id;
  final String title;
  final String body;

  Video({this.userId, this.id, this.title, this.body});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}



















Future<void> registerUser(String username, String deviceIP, List<String> filePaths) async {
  // TODO: error checking for inputs? make sure username is valid and filePaths has elements?

  // Create user
  await createUser(username,deviceIP);

  // Upload profile images to server
  await uploadImageToServer(username,filePaths);

  // Upload image info to database
  await uploadImageToDB(username,filePaths);

  // Join a session
  await joinSession(username);
}

Future<void> createUser(String username, String deviceIP) async {
  var uri = Uri.parse('http://$_mainNodeIP/user');
  var response = await http.post(uri,body:{'username':username,'device_ip':deviceIP});
  if (response.statusCode == 200) print('User with username $username created!');
}

Future<void> uploadImageToServer(String username, List<String> filePaths) async {
  var uri = Uri.parse('http://$_mainNodeIP/upload_file');

  // Loop through the list of file paths. Upload them to the server one at a time.
  // TODO: error checking for file type?
  for (String fp in filePaths) {
    var request = http.MultipartRequest('POST', uri);
    request.fields['username'] = username;
    request.files.add(await http.MultipartFile.fromPath('file', fp));
    var response = await request.send();
    if (response.statusCode == 200) print('Uploaded image(s) to server!');
  }

  // After uploading the images to the server (above), add the paths to database
  uploadImageToDB(username,filePaths);
}

Future<void> uploadImageToDB(String username, List filePaths) async {
  var uri = Uri.parse('http://$_mainNodeIP/user/image');
  var response = await http.post(uri,body:{'username':username,'file_paths':filePaths});
  if (response.statusCode == 200) print('Uploaded $username image information to database!');
}

Future<void> joinSession(String username) async {
  var uri = Uri.parse('http://$_mainNodeIP/session/join/$username');
  var response = await http.post(uri);
  if (response.statusCode == 200) print('$username joined a Swee session!');
}