// Lots of connectivity package related code borrowed from connectivity docs: https://pub.dev/packages/connectivity
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
import 'package:provider/provider.dart';
import '../../main.dart';
import 'dart:developer';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

String _mainNodeIP = '192.168.4.1:5001';//'127.0.0.1:5001'; // TODO: make this part of SweeUser?
// String _secondaryNodeIP = 'NaN.NaN.NaN.NaN';

class WifiDev extends StatefulWidget {
  WifiDev({Key key}) : super(key: key);

  @override
  WifiDevState createState() => WifiDevState();
}

class WifiDevState extends State<WifiDev> {
  int selectedIndex = 0;
  List<String> _imagePaths = ['phone/folder/path1','phone/folder/path2','phone/folder/path3'];
  String _connectionStatus = 'Unknown';
  String _wifiName = 'Unknown';
  bool _profileUploaded = false;
  Future<Post> post;
  Timer _timer;
  int _counter = 0;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String _lastTaskId;

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
    // post = fetchPost();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    initFlutterDownloader();
    _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => checkForNewVideos(Provider.of<SweeUser>(context,listen:false).username,Provider.of<SweeUser>(context,listen:false).videoPaths));
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }
  void initFlutterDownloader() async {
    // Make sure FlutterDownloader is only initialized once
    if (!Provider.of<SweeUser>(context,listen:false).flutterDownloaderInitialized) {
      await FlutterDownloader.initialize();
      Provider.of<SweeUser>(context,listen:false).setFlutterDownloaderInitialized(true);
    }
  }
  void checkForNewVideos(String username,List videoPaths) async {
    if (_wifiName=='swee') {

    
    _counter++;
    log('video check: $_counter');
    log('username: $username');
    log('current video paths:');
    for (String fp in videoPaths) {
      if (fp.isNotEmpty) {
        log('$fp');
      }
      else {log('[]');}
    }


    try {
      // final response = await http.get('https://jsonplaceholder.typicode.com/posts/1');
      var uri = Uri.http('$_mainNodeIP','/user/video',{'username':username});
      log('$uri');
      var response = await http.get(uri);
      if (response.statusCode==200) {
        log('response: /users/video');
        log(response.body);
        VideoResponse videoResponse = VideoResponse.fromJson(json.decode(response.body));
        List videoPathsOnServer = videoResponse.filePaths;
        for (String vp in videoPathsOnServer) {
          log('$vp');

          if (videoPaths.contains(vp)) {
            log('$vp already exists in SweeUser.videoPaths');
          }
          else {
            // Add vp to SweeUser.videoPaths, and download the video
            Provider.of<SweeUser>(context,listen:false).addVideoPath(vp);
            log('$vp added to SweeUser.videoPaths');
            // var uriDownload = Uri.http('$_mainNodeIP','/user/video',{'username':username});
            String filename = path.basename(vp);
            log('$filename');
            var uriDownload = Uri.http('$_mainNodeIP','/downloads/$username/$filename');
            final taskId = await FlutterDownloader.enqueue(url: uriDownload.toString(), savedDir: await _localPath);
            setState(() {
              _lastTaskId = taskId;
            });
            log('Task $taskId successfully downloaded!');
          }
        }
      }
      else {
        log('no response: /user/video');
      }
      }
    catch (_) {
      log('oh no');
      }
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      log(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String deviceIP;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      deviceIP = await GetIp.ipAddress;
    } on PlatformException {
      deviceIP = 'Failed to get ipAdress.';
    }
    log('get_ip returned $deviceIP');
    // Set deviceIP for SweeUser
    Provider.of<SweeUser>(context,listen:false).setDeviceIP(deviceIP);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wifi Dev'),
      ),
      body: Column(children:<Widget>[Center(child: Text('Connection Status: $_connectionStatus')),
        SizedBox(height:25),
        Consumer<SweeUser>(
          builder: (context,sweeuser,child) =>Text('SweeUser.deviceIP: ${sweeuser.deviceIP}'),
        ),
        SizedBox(height:25),
        IconButton(
          icon: Icon(Icons.videocam),
          onPressed:(){
            return FlutterDownloader.open(taskId: _lastTaskId);
          }
        ),
        Text('Last download task ID: $_lastTaskId')
        // Center(child: FutureBuilder<Post>(
        //   future: post,
        //   builder: (context, snapshot) {
        //     if (snapshot.hasData) {
        //       return Text(snapshot.data.title);
        //     } else if (snapshot.hasError) {
        //       return Text("${snapshot.error}");
        //     }
        //     // By default, show a loading spinner.
        //     return CircularProgressIndicator();
        //   },
        // ),
        // )
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
          log(e.toString());
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
          log(e.toString());
          wifiBSSID = "Failed to get Wifi BSSID";
        }

        try {
          wifiIP = await _connectivity.getWifiIP();
        } on PlatformException catch (e) {
          log(e.toString());
          wifiIP = "Failed to get Wifi IP";
        }
        log('$wifiIP');
        log('Connection: Wifi Detected');
        setState(() {
          _connectionStatus = '$result\n'
              'Wifi Name: $wifiName\n'
              'Wifi BSSID: $wifiBSSID\n'
              'Wifi IP: $wifiIP';
        });
        setState((){_wifiName='$wifiName';});

        if (_profileUploaded) {
          _uploadProfile(result.toString());
        }
        setState((){_profileUploaded = true;});

      // for (var interface in await NetworkInterface.list()) {
      //   log('== Interface: ${interface.name} ==');
      //   for (var addr in interface.addresses) {
      //     log('${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
      //   }
      // }
      await registerUser(Provider.of<SweeUser>(context,listen:false).username,
        Provider.of<SweeUser>(context,listen:false).deviceIP,
        Provider.of<SweeUser>(context,listen:false).imagePaths,
      );
      bool registrationStatus = true; // TODO: have registerUser return a true or false based on success
      Provider.of<SweeUser>(context,listen:false).setRegistration(registrationStatus);

      var regstat = Provider.of<SweeUser>(context,listen:false).isRegistered;
      log('User is registered? $regstat');


        break;
      case ConnectivityResult.mobile:
        log('Connection: Mobile Detected');
        setState(() => _connectionStatus = result.toString());
        setState(() {_wifiName='N/A';});
        setState((){_profileUploaded = false;});
        _uploadProfile(result.toString());
        break;
      case ConnectivityResult.none:
        log('Connection: None Detected');
        setState(() => _connectionStatus = result.toString());
        setState(() {_wifiName='N/A';});
        setState((){_profileUploaded = false;});
        _uploadProfile(result.toString());
        break;
      default:
        log('Connection: Failed to Get Connectivity');
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        setState(() {_wifiName='N/A';});
        setState((){_profileUploaded = false;});
        _uploadProfile(result.toString());
        break;
    }
  }

  Future<void> _uploadProfile(result) async {
    if (result=='ConnectivityResult.wifi') {
      // print('User: $_username');
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




















Future<void> registerUser(String username, String deviceIP, List<String> filePaths) async {
  // TODO: error checking for inputs? make sure username is valid and filePaths has elements?

  // Create user
  await createUser(username,deviceIP);

  // Create a new, temporary, list without any empty "file paths"
  var filePathsTemp = new List<String>();
  for (String fp in filePaths) {
    if (fp.isNotEmpty) {
      filePathsTemp.add(fp);
    }
  }


  // Upload profile images to server, and image information to the database
  if (filePathsTemp.isNotEmpty) {
    // Upload profile images to server
    await uploadImageToServer(username,filePathsTemp);

    // Upload image info to database
    await uploadImageToDB(username,filePathsTemp);
  }
  else{
    log('No profile images to upload.');
  }

  // Join a session
  await joinSession(username);


  log('$username ($deviceIP) successfully registered!');
}

Future<void> createUser(String username, String deviceIP) async {
  try {
    var uri = Uri.parse('http://$_mainNodeIP/user');
    var response = await http.post(uri,body:{'username':username,'device_ip':deviceIP});
    if (response.statusCode == 201) log('User with username $username created!');
  }
  catch (_) {
    log('Error in createUser');
  }
}

Future<void> uploadImageToServer(String username, List<String> filePaths) async {
  try {
    var uri = Uri.parse('http://$_mainNodeIP/upload_file');
    // Loop through the list of file paths. Upload them to the server one at a time.
    // TODO: error checking for file type?
    for (String fp in filePaths) {
      var request = http.MultipartRequest('POST', uri);
      request.fields['username'] = username;
      request.files.add(await http.MultipartFile.fromPath('file', fp));
      var response = await request.send();
      if (response.statusCode != 500) log('Uploaded image to server: $fp');
    }
  }
  catch (_) {
    log('Error in uploadImageToServer');
  }
}

Future<void> uploadImageToDB(String username, List<String> filePaths) async {
  try {
    var uri = Uri.parse('http://$_mainNodeIP/user/image');
    for (String fp in filePaths) {
      // TODO: why doesn't this work with a list of file paths? the server is configured to accept lists...
      var response = await http.post(uri,body:{'username':username,'file_paths':fp});
      if (response.statusCode == 201) log('Wrote to database: $fp');
    }
    log('Uploaded $username image information to database!');
  }
  catch (_) {
    log('Error in uploadImageToDB');
  }
}

Future<void> joinSession(String username) async {
  try {
    var uri = Uri.parse('http://$_mainNodeIP/session/join/$username');
    var response = await http.post(uri);
    if (response.statusCode == 202) log('$username joined a Swee session!');
  }
  catch (_) {
    log('Error in joinSession');
  }
}

class VideoResponse {
  final List filePaths;

  VideoResponse({this.filePaths});

  factory VideoResponse.fromJson(Map<String,dynamic> json) {
    return VideoResponse(filePaths: json['file_paths']);
  }
}