// Lots of connectivity package related code borrowed from connectivity docs: https://pub.dev/packages/connectivity

import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get_ip/get_ip.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
// import '../../screens/connectivity/wifi_dev.dart';
// import 'package:flutter/foundation.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';

final _user = User(); // Moved this out here, which allows the user info to persist when navigating between screens
double _imageSize = 175;
int _nImages = 3;
List<File> _pickedImages = List<File>.filled(_nImages,null,growable:false); // TODO: Add this to SharedPreferences

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _lastUsernameController;
  // List<String> _registeredUsers = [];
  Uri _uriUsers;
  final int _httpTimeoutTime = 2;
  String _connectionStatus = 'Unknown';
  String _wifiName = 'Unknown';
  Timer _timer;
  int _counter = 0;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Dio dio = Dio();
  String _mainNodeIP;
  // String _secondaryNodeIP;
  SnackBar _snackBarUsernameTaken;
  SnackBar _snackBarNoImages = SnackBar(content: Text("No profile images were specified. Please select at least one profile image on the 'User Profile' page."));
  SnackBar _snackBarAlreadyRegistered;
  SnackBar _snackBarRegistrationSuccessful;
  SnackBar _snackBarHttpTimeout = SnackBar(content: Text("A Swee server connection could not be established. Are you connected Swee wifi?"), action: SnackBarAction(label: 'Dismiss',onPressed: () {}));
  SnackBar _snackBarGoodName = SnackBar(content: Text("Good name!"), action: SnackBarAction(label: 'Dismiss',onPressed: () {}));

  @override
  void initState() {
    _initSharedPreferences();

    _mainNodeIP = Provider.of<SweeUser>(context,listen:false).mainNodeIP;
    _uriUsers = Uri.http('$_mainNodeIP','/users');

    initPlatformState();
    initConnectivity();
    buildSnackBars();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => checkForNewVideos(Provider.of<SweeUser>(context,listen:false).username,Provider.of<SweeUser>(context,listen:false).videoPaths));
    _mainNodeIP = Provider.of<SweeUser>(context,listen:false).mainNodeIP;
    // _secondaryNodeIP = Provider.of<SweeUser>(context,listen:false).secondaryNodeIP;

    super.initState();
  }

  @override
  void dispose() {
    _lastUsernameController.dispose();

    _connectivitySubscription.cancel();
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _returnScaffold();
  }

  void buildSnackBars() {
    String _username = Provider.of<SweeUser>(context,listen:false).username;
    String _deviceIP = Provider.of<SweeUser>(context,listen:false).deviceIP;
    _snackBarUsernameTaken = SnackBar(content: Text("The username $_username is already registered with this Swee server with a different device IP address. Please choose a different username for this device."));
    _snackBarAlreadyRegistered = SnackBar(content: Text("This device ($_username, $_deviceIP) is already registered with this Swee server."));
    _snackBarRegistrationSuccessful = SnackBar(content: Text("User ($_username, $_deviceIP) registration successful!"));
  }

  void checkForNewVideos(String username,List videoPaths) async {
    if (_wifiName=='swee') {
      _counter++;
      log('video check: $_counter for $username');
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

  void _pickImage(int _pickedImageNum) async {
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) =>
        AlertDialog(
          title: Text("Select the image source"),
          actions: <Widget>[
            MaterialButton(
              child: Text("Camera"),
              onPressed: () => Navigator.pop(context, ImageSource.camera),
            ),
            MaterialButton(
              child: Text("Gallery"),
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
            )
          ],
        )
    );
    
    if(imageSource != null) {
      final file = await ImagePicker.pickImage(source: imageSource);
      if(file != null) {
        setState(() {
          _pickedImages[_pickedImageNum] = file;
          Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImageNum,_pickedImages[_pickedImageNum].path);
        });
      }
    }
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
        log('Connection: Wifi Detected: $wifiName');
        setState(() {
          _connectionStatus = '$result\n'
              'Wifi Name: $wifiName\n'
              'Wifi BSSID: $wifiBSSID\n'
              'Wifi IP: $wifiIP';
        });
        setState((){_wifiName='$wifiName';});

        // await registerUser(Provider.of<SweeUser>(context,listen:false).username,
        //   Provider.of<SweeUser>(context,listen:false).deviceIP,
        //   Provider.of<SweeUser>(context,listen:false).imagePaths,
        // );
        // bool registrationStatus = true; // TODO: have registerUser return a true or false based on success
        // Provider.of<SweeUser>(context,listen:false).setRegistration(registrationStatus);
        // var regstat = Provider.of<SweeUser>(context,listen:false).isRegistered;
        // log('User is registered? $regstat');

        break;
      case ConnectivityResult.mobile:
        log('Connection: Mobile Detected');
        setState(() => _connectionStatus = result.toString());
        setState(() {_wifiName='N/A';});
        // setState((){_profileUploaded = false;});
        // _uploadProfile(result.toString());
        Provider.of<SweeUser>(context,listen:false).clearVideoPath();
        break;
      case ConnectivityResult.none:
        log('Connection: None Detected');
        setState(() => _connectionStatus = result.toString());
        setState(() {_wifiName='N/A';});
        // setState((){_profileUploaded = false;});
        // _uploadProfile(result.toString());
        Provider.of<SweeUser>(context,listen:false).clearVideoPath();
        break;
      default:
        log('Connection: Failed to Get Connectivity');
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        setState(() {_wifiName='N/A';});
        // setState((){_profileUploaded = false;});
        // _uploadProfile(result.toString());
        Provider.of<SweeUser>(context,listen:false).clearVideoPath();
        break;
    }
  }

  Future<void> registerUser(String username, String deviceIP, List<String> filePaths) async {
    // Check if user already exists
    var uri = Uri.http('$_mainNodeIP','/users');
    var response = await http.get(uri);
    UsersResponse registeredUserData = UsersResponse.fromJson(json.decode(response.body));
    List<String> registeredUsers = [];
    for (UserInfo ui in registeredUserData.users) {
      registeredUsers.add(ui.username);
    }

    if (registeredUsers.contains(username)) {
      // log('$username is already registered on the Swee server. Please choose a different username.');

      // If this is true, this username is already registered. Now check if the registered one matches this device's IP. If so, no need to re-register.
      var uri1 = Uri.http('$_mainNodeIP','/user',{'username':'$username'});
      var response1 = await http.get(uri1);
      Map thisUserData = json.decode(response1.body);
      UserInfo thisUser = UserInfo.fromJson(thisUserData['data']);
      if (thisUser.deviceip==Provider.of<SweeUser>(context,listen:false).deviceIP) { // TODO: as-coded, this doesn't allow the user to change their name mid session. changing the name will not successfully re-register the user. maybe use device IP instead of username as the key?
        Scaffold.of(context).showSnackBar(_snackBarAlreadyRegistered);
        log('registerUser: Already registered');
      }
      else {
        Scaffold.of(context).showSnackBar(_snackBarUsernameTaken);
        log('registerUser: Username taken');
      }
    }
    else {
      // Create a new, temporary, list without any empty "file paths"
      var filePathsTemp = new List<String>();
      for (String fp in filePaths) {
        if (fp.isNotEmpty) {
          filePathsTemp.add(fp);
        }
      }

      // TODO: check what images were uploaded already, and upload the NEW ones

      if (filePathsTemp.isNotEmpty) {
        // Create user
        await createUser(username,deviceIP);
        
        // Upload profile images to server
        await uploadImageToServer(username,filePathsTemp);

        // Upload image info to database
        await uploadImageToDB(username,filePathsTemp);

        // Join a session
        await joinSession(username);

        // Clear http videos
        Provider.of<SweeUser>(context,listen:false).clearVideoPath();
        
        Scaffold.of(context).showSnackBar(_snackBarRegistrationSuccessful);
        log('registerUser: $username ($deviceIP) successfully registered!');
      }
      else {
        Scaffold.of(context).showSnackBar(_snackBarNoImages);
        log('registerUser: No profile images to upload. Choose profile image(s) and try again.');
      }
    }
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

  Scaffold _returnScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Container(
        padding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: ListView(
          children: <Widget> [
            Builder(
              builder: (context) => Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _lastUsernameController,
                      decoration:
                        InputDecoration(
                          labelText: 'First name',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _lastUsernameController.clear();
                            }
                          ),
                        ),
                      validator: (val) {
                        if (val.isEmpty) {
                          return 'Please enter your first name';
                        }
                        // else if (_registeredUsers.contains(val)) {
                        //   return 'Username $val is already taken. Please enter a different username.';
                        // }
                        return null;
                      },
                      onSaved: (val) =>
                        setState(() => _user.firstName = val),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 300),
                      child: RaisedButton(
                        onPressed: () async {                          
                          try {
                            final response = await http.get(_uriUsers).timeout(Duration(seconds:_httpTimeoutTime)); // TODO: SocketException here that doesn't get caught for some reason? Is this a VSCode issue or an actual issue with the code?
                            final UsersResponse registeredUserData = UsersResponse.fromJson(json.decode(response.body));
                            final List<String> registeredUsers = [];
                            for (UserInfo ui in registeredUserData.users) {
                              registeredUsers.add(ui.username);
                            }
                            // _registeredUsers = registeredUsers;
                          }
                          on SocketException catch(_) {
                            log('SocketException');
                            return;
                          }
                          catch (e) {
                            log('http call to /users timed out after $_httpTimeoutTime second');
                            Scaffold.of(context).showSnackBar(_snackBarHttpTimeout);
                            return;
                          }

                          final form = _formKey.currentState;
                          if (form.validate()) {
                            form.save();
                            _user.save();
                            _saveSharedPreferences();
                            
                            await registerUser(Provider.of<SweeUser>(context,listen:false).username,
                              Provider.of<SweeUser>(context,listen:false).deviceIP,
                              Provider.of<SweeUser>(context,listen:false).imagePaths,
                            );
                            
                            _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => checkForNewVideos(Provider.of<SweeUser>(context,listen:false).username,Provider.of<SweeUser>(context,listen:false).videoPaths));
                            // _showDialog(context);
                            log('Username available!');
                            Scaffold.of(context).showSnackBar(_snackBarGoodName);
                          }
                        },
                        child: Text('Join Swee Session'),
                      )
                    ),
                    SizedBox(height:0),
                    Container(
                      padding: EdgeInsets.symmetric(vertical:8,horizontal:150),
                      child: AppBar(title: Text('Upload 1-3 Selfies'), backgroundColor: Colors.grey,),
                    ),
                    SizedBox(height:25),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling in this ListView instance, since the parent ListView srolls
                      shrinkWrap: true,
                      itemCount: _nImages,
                      // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
                      itemBuilder: (BuildContext context,int index){
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget> [
                            Center(
                              child: _pickedImages[index] == null ?
                              FloatingActionButton(
                                onPressed: (){_pickImage(index);},
                                child: Icon(Icons.image),
                              ) :
                              Stack(
                                children: <Widget> [
                                  Image(image: FileImage(_pickedImages[index]),height: _imageSize,),
                                  FloatingActionButton(
                                    onPressed: (){_pickImage(index);},
                                    child: Icon(Icons.image),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height:10),
                          ],
                        );
                      },
                    ),
                  ]
                )
              )
            ),
            SizedBox(height:25),
            Center(child: 
              Text('Connection Status: $_connectionStatus')
            ),
          ]
        ),
      ),
    );
  }

  _initSharedPreferences() async {
    log('_initSharedPreferences()');
    final prefs = await SharedPreferences.getInstance();
    final key = 'username';
    final value = prefs.getString(key) ?? 'Default User Name';
    _user.firstName = value; // Set the local variable
    Provider.of<SweeUser>(context,listen:false).setUsername(_user.firstName); // Set SweeUser (shared across multiple screens)
    log('read: $value');
    setState(() {
      _lastUsernameController = TextEditingController(text:value);
    });
  }

  _saveSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'username';
    final value = _user.firstName;
    prefs.setString(key, value);
    Provider.of<SweeUser>(context,listen:false).setUsername(_user.firstName); // Set SweeUser (shared across multiple screens)
    log('saved: $value');
  }
}














class VideoResponse {
  final List filePaths;

  VideoResponse({this.filePaths});

  factory VideoResponse.fromJson(Map<String,dynamic> json) {
    return VideoResponse(filePaths: json['file_paths']);
  }
}

class UserInfo {
  final List image;
  final String username;
  final String deviceip;
  final int session;
  final List video;
  final int id;

  UserInfo({this.image, this.username, this.deviceip, this.session, this.video, this.id});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      image: json['image'],
      username: json['username'],
      deviceip: json['device_ip'],
      session: json['session'],
      video: json['video'],
      id: json['id'],
    );
  }
}

class UsersResponse {
  final List<UserInfo> users;
  final int nUsers;

  UsersResponse({this.users,this.nUsers});

  factory UsersResponse.fromJson(Map<String,dynamic> json) {
    List<UserInfo> usersToAdd = [];
    List jsonData = json['data'];
    for (Map userData in jsonData) {//(var i = 0; i<jsonData.length; i++) {
      // Map userData = jsonData[i];
      usersToAdd.add(
        UserInfo.fromJson(userData),
      );
    }

    return UsersResponse(users: usersToAdd, nUsers: usersToAdd.length);
  }
}