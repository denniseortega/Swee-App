import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'user_info/user_form.dart';
import 'video/video.dart';
import 'video/video_library.dart';
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:get_ip/get_ip.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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
  String _mainNodeIP;
  Dio dio = Dio();

  @override
  void initState() {
    Timer.periodic(Duration(seconds: 5), (Timer t) => _checkForNewVideos());
    _mainNodeIP = Provider.of<SweeUser>(context,listen:false).mainNodeIP;
    _getDeviceIP();
    _initSharedPrefs();

    super.initState();
  }

  void _checkForNewVideos() async {
    String _now = new DateTime.now().toString();
    String _username = Provider.of<SweeUser>(context,listen:true).username;
    List _videoPaths = Provider.of<SweeUser>(context,listen:true).videoPaths;
    List _videoPathsCurrentHole = Provider.of<SweeUser>(context,listen:true).videoPathsCurrentHole;
    String _wifiName = Provider.of<SweeUser>(context,listen:true).wifiName;

    if (_wifiName=='swee') {
      if (Provider.of<SweeUser>(context,listen:false).isRegistered) {
        log('_checkForNewVideos: Video check for "$_username": $_now');

        try {
          var uriUser = Uri.http('$_mainNodeIP','/user',{'username':_username});
          var responseUser = await http.get(uriUser);

          if (responseUser.statusCode==204) {
            log('_checkForNewVideos: Connectivity check... $_username is no longer connected to swee');
            _showDialogLostConnection();
            Provider.of<SweeUser>(context,listen:false).setRegistration(false);
          }
          else {
            log('_checkForNewVideos: Connectivity check... $_username is connected to swee');
          }
        }
        catch(e) {
          log('_checkForNewVideos: Something when wrong when trying to determine user connectivity');
        }

        // log('_checkForNewVideos: current video paths:');
        // for (String fp in _videoPaths) {
        //   if (fp.isNotEmpty) {
        //     log('  $fp');
        //   }
        //   else {log('[]');}
        // }

        try {
          var uri = Uri.http('$_mainNodeIP','/user/video',{'username':_username});
          var response = await http.get(uri);
          if (response.statusCode==200) {
            try {
              // log('_checkForNewVideos: Response received: /users/video');
              // log(response.body);
              VideoResponse videoResponse = VideoResponse.fromJson(json.decode(response.body));
              List<String> videoPathsOnServer = videoResponse.filePaths;
              for (String vp in videoPathsOnServer) {
                String filename = path.basename(vp);
                var uriDownload = Uri.http('$_mainNodeIP','/downloads/$_username/$filename');
                String vpUrl = uriDownload.toString();
                var _dir = await _localPath;
                String _localPathFile = _dir+"/$filename";
                // log('$vpUrl');
                // log('Local app directory: $_dir');
                
                if (!_videoPathsCurrentHole.contains(vpUrl)) {
                  Provider.of<SweeUser>(context,listen:false).addVideoPathCurrentHole(vpUrl);
                }

                if (_videoPaths.contains(vpUrl)) { // check if the video has already been downloaded
                  log('_checkForNewVideos: $vpUrl has already been downloaded'); // If it already exists in SweeUser.videoPaths, that means the video has already been downloaded
                }
                else {
                  // Add the video to the list of all downloaded videos to prevent the next loop of this function from downloading the same video
                  // This is a hack of sorts since this function isn't a blocking until it complete
                  // Don't add to the videoPathsLocal until the video is actually downloaded
                  // This prevents it from being displayed on video_library.dart until it's actually ready
                  Provider.of<SweeUser>(context,listen:false).addVideoPath(vpUrl); // Add to the list of all videos ever downloaded
                  try {
                    await dio.download(uriDownload.toString(),_localPathFile);
                    Provider.of<SweeUser>(context,listen:false).addVideoPathLocal(_localPathFile); // Add to the list of videos to be displayed on video_library.dart
                    _saveSharedPrefs(Provider.of<SweeUser>(context,listen:false).videoPaths,Provider.of<SweeUser>(context,listen:false).videoPathsLocal); // Save shared prefs
                  }
                  catch (e) {
                    log('_checkForNewVideos: Something went wrong with a single file download');
                    try {
                      // The video download failed, so remove it from the list that you previously added it to
                      List videoPathsIn = Provider.of<SweeUser>(context,listen:false).videoPaths;
                      videoPathsIn.removeLast();
                      Provider.of<SweeUser>(context,listen:false).setVideoPaths(videoPathsIn);
                    }
                    catch (e) {
                      log('_checkForNewVideos: Something went wrong when trying to undo what you did lol');
                    }
                  }
                  log('_checkForNewVideos: Download complete');
                }
              }
            }
            catch (e) {
              log('_checkForNewVideos: Something went wrong when trying to download a batch of videos');
            }  
          }
          else {
            log('_checkForNewVideos: No response: /user/video');
          }
        }
        catch (e) {
          log('_checkForNewVideos: Something went wrong when trying to get an http response from /user/video');
        }
      }
      else {
        log('_checkForNewVideos: Not registered');
      }
    }
    else {
      log('_checkForNewVideos: Not connected to swee');
    }
    log(' '); // Print blank line
  }

  void _showDialogLostConnection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Swee Connection Lost"),
          content: Text ("You have been disconnected from the Swee session! You may want to try joining again."),
          actions: <Widget>[
            FlatButton(
              child: Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void _initSharedPrefs() async {
    log('home_screen: _initSharedPrefs');
    final prefs = await SharedPreferences.getInstance();

    final value0 = prefs.getStringList('videoPathsLocal') ?? [];
    int idx = 0;
    List<int> pendingRemovals = [];
    for (String fp in value0) {
      if (await File(fp).exists()) {
        log('home_screen/_initSharedPrefs: File exists');
      }
      else {
        log('home_screen/_initSharedPrefs: File does not exist... Removing from list');
        pendingRemovals.add(idx);
      }
      idx++;
    }
    for (int i in pendingRemovals.reversed) {
      value0.removeAt(i);
    }
    Provider.of<SweeUser>(context,listen:false).setVideoPathsLocal(value0);

    final value1 = prefs.getStringList('videoPaths') ?? [];
    Provider.of<SweeUser>(context,listen:false).setVideoPaths(value1);

    if (pendingRemovals.isNotEmpty) {
      _saveSharedPrefs(value1,value0); // Resave these because 
    }
  }

  void _saveSharedPrefs(videoPathsIn, videoPathsLocalIn) async {
    log('home_screen: _saveSharedPrefs');
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('videoPaths', videoPathsIn);
    prefs.setStringList('videoPathsLocal', videoPathsLocalIn);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _getDeviceIP() async {
    String deviceIP;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      deviceIP = await GetIp.ipAddress;
    } on PlatformException {
      deviceIP = 'Failed to get ipAdress.';
    }
    log('GetIp returned $deviceIP');
    // Set deviceIP for SweeUser
    Provider.of<SweeUser>(context,listen:false).setDeviceIP(deviceIP);
  }

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