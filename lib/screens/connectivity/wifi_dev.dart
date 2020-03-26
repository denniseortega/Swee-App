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
import 'package:video_player/video_player.dart';
import '../../main.dart';
import 'dart:developer';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:chewie/chewie.dart';

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
  Timer _timer;
  int _counter = 0;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  // String _lastTaskId;
  // List<String> _tasks = [];
  Dio dio = Dio();
  String _mainNodeIP;
  // String _secondaryNodeIP;

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
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // initFlutterDownloader();
    _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => checkForNewVideos(Provider.of<SweeUser>(context,listen:false).username,Provider.of<SweeUser>(context,listen:false).videoPaths));
    _mainNodeIP = Provider.of<SweeUser>(context,listen:false).mainNodeIP;
    // _secondaryNodeIP = Provider.of<SweeUser>(context,listen:false).secondaryNodeIP;
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // void initFlutterDownloader() async {
  //   // Make sure FlutterDownloader is only initialized once
  //   if (!Provider.of<SweeUser>(context,listen:false).flutterDownloaderInitialized) {
  //     await FlutterDownloader.initialize();
  //     Provider.of<SweeUser>(context,listen:false).setFlutterDownloaderInitialized(true);
  //   }
  // }

  void checkForNewVideos(String username,List videoPaths) async {
    if (_wifiName=='swee') {
      _counter++;
      log('video check: $_counter');
      log('username: $username');
      log('current video paths:');
      for (String fp in videoPaths) {
        if (fp.isNotEmpty) {
          log('  $fp');
        }
        else {log('[]');}
      }

      try {
        var uri = Uri.http('$_mainNodeIP','/user/video',{'username':username});
        log('$uri');
        var response = await http.get(uri);
        if (response.statusCode==200) {
          try {
            log('Response received: /users/video');
            log(response.body);
            VideoResponse videoResponse = VideoResponse.fromJson(json.decode(response.body));
            List videoPathsOnServer = videoResponse.filePaths;
            for (String vp in videoPathsOnServer) {
              String filename = path.basename(vp);
              var uriDownload = Uri.http('$_mainNodeIP','/downloads/$username/$filename');
              String vpUrl = uriDownload.toString();
              var _dir = await _localPath;
              String _localPathFile = _dir+"/$filename";
              log('$vpUrl');
              log('Local app directory: $_dir');
              
              if (videoPaths.contains(vpUrl)) {
                log('$vpUrl already exists in SweeUser.videoPaths');
              }
              else {
                // // Add vp to SweeUser.videoPaths, and download the video
                // Provider.of<SweeUser>(context,listen:false).addVideoPath(vpUrl);
                // log('$vp added to SweeUser.videoPaths as $vpUrl');
                // final taskId = await FlutterDownloader.enqueue(url: uriDownload.toString(), savedDir: await _localPath);
                // setState(() {
                //   _lastTaskId = taskId;
                //   _tasks.add(taskId);
                // });
                // log('Task $taskId successfully downloaded!');

                try {
                  await dio.download(uriDownload.toString(),_localPathFile);//, onProgress:(rec,total){log("Rec: $rec, Total: $total");});
                  Provider.of<SweeUser>(context,listen:false).addVideoPath(vpUrl);
                  Provider.of<SweeUser>(context,listen:false).addVideoPathLocal(_localPathFile);
                }
                catch (e) {
                  log(e);
                }
                log('Download complete');
              }
            }
          }
          catch (_) {
            log('Something went wrong when trying to download new videos');
          }  
        }
        else {
          log('No response: /user/video');
        }
      }
      catch (_) {
        log('Something went wrong when trying to check for new videos');
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
      body: Column(
        children:<Widget>[Center(child: Text('Connection Status: $_connectionStatus')),
          // SizedBox(height:25),
          // Text('Last download task ID: $_lastTaskId'),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling in this ListView instance, since the parent ListView srolls
            shrinkWrap: true,
            itemCount: Provider.of<SweeUser>(context,listen:true).videoPathsLocal.length,
            itemBuilder: (BuildContext context,int index){
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget> [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget> [
                      Text('Course: Test, Hole: -1, Shot: -2'),
                      RaisedButton(
                        child: Icon(Icons.movie),
                        onPressed: () {
                          Navigator.push(context,MaterialPageRoute(builder: (context) => VidPlay(videoPath: Provider.of<SweeUser>(context,listen:true).videoPathsLocal[index])));
                        },
                      ),
                    ]
                  ),
                ],
              );
            },
          ),
          SizedBox(height:25),
          RaisedButton(
            child: Text('Open Test Video Player'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VidPlay()),
              );
            },
          ),
        ]
      ),
    );
  }

  // Future<void> _refresh() async {
  //   log('Refreshing wifi_dev');
  // }

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
        log('$wifiName');
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

        await registerUser(Provider.of<SweeUser>(context,listen:false).username,
          Provider.of<SweeUser>(context,listen:false).deviceIP,
          Provider.of<SweeUser>(context,listen:false).imagePaths,
        );
        // bool registrationStatus = true; // TODO: have registerUser return a true or false based on success
        // Provider.of<SweeUser>(context,listen:false).setRegistration(registrationStatus);
        // var regstat = Provider.of<SweeUser>(context,listen:false).isRegistered;
        // log('User is registered? $regstat');

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
}

class VidPlay extends StatefulWidget {
  final String videoPath;

  VidPlay({Key key, this.videoPath}) : super(key: key);

  @override
  VidPlayState createState() => VidPlayState();
}

class VidPlayState extends State<VidPlay> {
  VideoPlayerController _videoPlayerController1;
  ChewieController _chewieController;

  @override
  void initState() {
    // _videoPlayerController1 = VideoPlayerController.network(
    //     'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
    if (widget.videoPath==null) {
      _videoPlayerController1 = VideoPlayerController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4');
    }
    else {
      String _localVideoPath = 'file://'+widget.videoPath;
      // String _localVideoPath = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
      log('local video path: $_localVideoPath');
      _videoPlayerController1 = VideoPlayerController.network(
        _localVideoPath);
    }


    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: false,
      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      autoInitialize: true,
    );

    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Player"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: <Widget> [
          // Center(
          //   child: RaisedButton(
          //     onPressed: () {
          //       Navigator.pop(context);
          //     },
          //     child: Text('Go back to wifi_dev!'),
          //   ),
          // ),
          Chewie(controller: _chewieController,),
        ]
      )
    );
  }
}

class VideoResponse {
  final List filePaths;

  VideoResponse({this.filePaths});

  factory VideoResponse.fromJson(Map<String,dynamic> json) {
    return VideoResponse(filePaths: json['file_paths']);
  }
}




