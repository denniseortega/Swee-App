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
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:exif/exif.dart';

final _user = User(); // Moved this out here, which allows the user info to persist when navigating between screens
double _imageSize = 175;

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
  Timer _timer;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Dio dio = Dio();
  String _mainNodeIP;
  // String _secondaryNodeIP;
  SnackBar _snackBarNoImages = SnackBar(content: Text("No profile images were specified. Please select at least one profile image on the 'User Profile' page."));
  SnackBar _snackBarHttpTimeout = SnackBar(content: Text("A Swee server connection could not be established. Are you connected Swee wifi?"), action: SnackBarAction(label: 'Dismiss',onPressed: () {}));
  // SnackBar _snackBarGoodName = SnackBar(content: Text("Good name!"), action: SnackBarAction(label: 'Dismiss',onPressed: () {}));

  @override
  void initState() {
    _initSharedPreferences();
    _initSharedPrefsImagePaths();

    _mainNodeIP = Provider.of<SweeUser>(context,listen:false).mainNodeIP;
    _uriUsers = Uri.http('$_mainNodeIP','/users');

    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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
        // setState(() {
        //   _pickedImages[_pickedImageNum] = file;
        //   Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImageNum,_pickedImages[_pickedImageNum].path);
        // });
        Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImageNum,file.path);
        _saveSharedPrefsImagePaths();
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
        Provider.of<SweeUser>(context,listen:false).setWifiName(wifiName);
        Provider.of<SweeUser>(context,listen:false).setDeviceIP(wifiIP);

        break;
      case ConnectivityResult.mobile:
        log('Connection: Mobile Detected');
        setState(() => _connectionStatus = result.toString());
        _clearSweeUserWifiInfo();
        break;
      case ConnectivityResult.none:
        log('Connection: None Detected');
        setState(() => _connectionStatus = result.toString());
        _clearSweeUserWifiInfo();
        break;
      default:
        log('Connection: Failed to Get Connectivity');
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        _clearSweeUserWifiInfo();   
        break;
    }
  }

  void _clearSweeUserWifiInfo() {
    Provider.of<SweeUser>(context,listen:false).clearVideoPathsCurrentHole();
    Provider.of<SweeUser>(context,listen:false).setWifiName('');
    Provider.of<SweeUser>(context,listen:false).setDeviceIP('NaN.NaN.NaN.NaN'); 
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
      if (thisUser.deviceip==Provider.of<SweeUser>(context,listen:false).deviceIP) {
        SnackBar _snackBarAlreadyRegistered = SnackBar(content: Text("This device ($username, $deviceIP) is already registered with this Swee server."));
        Scaffold.of(context).showSnackBar(_snackBarAlreadyRegistered);
        log('registerUser: Already registered');
      }
      else {
        SnackBar _snackBarUsernameTaken = SnackBar(content: Text("The username $username is already registered with this Swee server with a different device IP address. Please choose a different username for this device."));
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
        Provider.of<SweeUser>(context,listen:false).clearVideoPaths();
        Provider.of<SweeUser>(context,listen:false).setRegistration(true);

        SnackBar _snackBarRegistrationSuccessful = SnackBar(content: Text("User ($username, $deviceIP) registration successful!"));
        Scaffold.of(context).showSnackBar(_snackBarRegistrationSuccessful);
        log('registerUser: $username ($deviceIP) successfully registered!');
      }
      else {
        Scaffold.of(context).showSnackBar(_snackBarNoImages);
        log('registerUser: No profile images to upload. Choose profile image(s) and try again.');
      }
    }
  }

  Future<void> unregisterUser(String username, String deviceIP) async {
    // Do something here
    try {
      var uri = Uri.parse('http://$_mainNodeIP/session/leave/$username');
      var response = await http.post(uri);
      if (response.statusCode == 200) log('$username left a Swee session!');
    }
    catch (_) {
      log('Error in unregisterUser');
    }
    Provider.of<SweeUser>(context,listen:false).setRegistration(false);

    SnackBar _snackBarUnregistrationSuccessful = SnackBar(content: Text("User ($username, $deviceIP) unregistration successful!"));
    Scaffold.of(context).showSnackBar(_snackBarUnregistrationSuccessful);
    log('registerUser: $username ($deviceIP) successfully unregistered!');
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
      int idx = 0;
      var uri = Uri.parse('http://$_mainNodeIP/upload_file');
      // Loop through the list of file paths. Upload them to the server one at a time.
      for (String fp in filePaths) {
        var request = http.MultipartRequest('POST', uri);
        request.fields['username'] = username;

        // Fix image rotation based on exif data      
        img.Image imageFixedRotation;
        try {
          imageFixedRotation = await fixExifRotation(fp);
        }
        catch (e_fixExifRotation) {
          log('Rotation correction failed (image $idx).'); // Note: Images previously rotated by fixExifRotation may not contain exif rotation data, which may cause fixExifRotation() to fail
          final originalFile = File(fp);
          List<int> imageBytes = await originalFile.readAsBytes();
          final originalImage = img.decodeImage(imageBytes);
          imageFixedRotation = img.copyRotate(originalImage, 0);
        }

        // Resize image
        img.Image thumbnail = img.copyResize(imageFixedRotation,width:182);
        String localPath = await _localPath;
        String filename = path.basename(fp);

        // Replace the last occurence of .
        int ind = filename.lastIndexOf(".");
        if (ind>0) {
          filename = filename.substring(0,ind) + '_resized' + filename.substring(ind,filename.length);
        }

        // Rewrite the resized image
        String fpNew = path.join(localPath, filename);
        File(fpNew)..writeAsBytesSync(img.encodePng(thumbnail));

        // Upload
        request.files.add(await http.MultipartFile.fromPath('file', fpNew));
        var response = await request.send();


        if (response.statusCode != 500) {
          log('Uploaded image to server: $fp');
        } 

        Provider.of<SweeUser>(context,listen:false).addImagePathRotated(idx, fpNew);
        idx++;
      }

      
    }
    catch (e) {
      log('Error in uploadImageToServer');
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
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
      appBar: AppBar(title: Text('User Profile')),
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
                      enabled: Provider.of<SweeUser>(context,listen:false).isRegistered? false:true,
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
                    SizedBox(height:25),
                    AppBar(title: Text('Upload 1-3 Selfies'), backgroundColor: Colors.grey,),
                    SizedBox(height:25),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling in this ListView instance, since the parent ListView srolls
                      shrinkWrap: true,
                      itemCount: Provider.of<SweeUser>(context,listen:false).imagePaths.length,
                      // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
                      itemBuilder: (BuildContext context,int index) {
                        String thisImagePath = Provider.of<SweeUser>(context,listen:false).imagePaths[index];
                        bool imageExists = false;
                        if (File(thisImagePath).existsSync()) {
                          imageExists = true;
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget> [
                            Center(
                              child: !imageExists?
                              FloatingActionButton(
                                onPressed: (){_pickImage(index);},
                                child: Icon(Icons.image),
                              ) :
                              Stack(
                                children: <Widget> [
                                  Image(
                                    image: FileImage(File(thisImagePath)),
                                    height: _imageSize,
                                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedButton(
                  onPressed: () async {         
                    if (Provider.of<SweeUser>(context,listen:false).isRegistered) { // User already registered, so unregister
                      unregisterUser(Provider.of<SweeUser>(context,listen:false).username,Provider.of<SweeUser>(context,listen:false).deviceIP);
                    } 
                    else { // Register user
                      try {
                        final response = await http.get(_uriUsers).timeout(Duration(seconds:_httpTimeoutTime)); // TODO: SocketException here that doesn't get caught for some reason? Is this a VSCode issue or an actual issue with the code?
                        final UsersResponse registeredUserData = UsersResponse.fromJson(json.decode(response.body));
                        final List<String> registeredUsers = [];
                        for (UserInfo ui in registeredUserData.users) {
                          registeredUsers.add(ui.username);
                        }
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

                        String _username = _user.firstName;
                        String _deviceIP = Provider.of<SweeUser>(context,listen:false).deviceIP;
                        List _imagePaths = Provider.of<SweeUser>(context,listen:false).imagePaths;

                        Provider.of<SweeUser>(context,listen:false).setUsername(_username);
                        _saveSharedPreferences();

                        if (_deviceIP==null) {
                          log('_deviceIP returned null. Why?');
                          _deviceIP = await GetIp.ipAddress;
                        }

                        await registerUser(_username, _deviceIP, _imagePaths);
                        
                        log('Username available!');
                        // Scaffold.of(context).showSnackBar(_snackBarGoodName);
                      }
                    }                
                  },
                  child: !Provider.of<SweeUser>(context,listen:true).isRegistered ? Text('Join Swee Session'):Text('Leave Swee Session'),
                )
              ],
            ),
            SizedBox(height:100),
            Center(child: 
              Text('Connection Status: $_connectionStatus')
            ),
          ]
        ),
      ),
    );
  }

  _initSharedPreferences() async {
    // log('_initSharedPreferences()');
    final prefs = await SharedPreferences.getInstance();
    final key = 'username';
    final value = prefs.getString(key) ?? 'Default User Name';
    _user.firstName = value; // Set the local variable
    Provider.of<SweeUser>(context,listen:false).setUsername(_user.firstName); // Set SweeUser (shared across multiple screens)
    // log('read: $value');
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

  _initSharedPrefsImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'imagePaths';
    final value = prefs.getStringList(key) ?? Provider.of<SweeUser>(context,listen:false).imagePaths;
    int idx = 0;
    bool valueChanged = false;
    for (String fp in value) {
      if (await File(fp).exists()) {
        log('_initSharedPrefsImagePaths: File exists');
      }
      else {
        if (value[idx]!="") {
          log('_initSharedPrefsImagePaths: File does not exist... Removing from list');
          value[idx] = "";
          valueChanged = true;
        }
      }
      idx++;
    }
    Provider.of<SweeUser>(context,listen:false).setImagePaths(value);

    if (valueChanged) {
      _saveSharedPrefsImagePaths();
    }
  }

  _saveSharedPrefsImagePaths() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'imagePaths';
    final value = Provider.of<SweeUser>(context,listen:false).imagePaths;
    prefs.setStringList(key, value);
  }

  Future<img.Image> fixExifRotation(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);

    // final height = originalImage.height;
    // final width = originalImage.width;

    // We'll use the exif package to read exif data
    // This is map of several exif properties
    // Let's check 'Image Orientation'
    final exifData = await readExifFromBytes(imageBytes);

    img.Image fixedImage;

    // TODO I think image rotation is based on a default orientation.
    // For iPhones, the default image rotation is landscape mode with the forward facing camera on the top-left (i.e. you rotate the phone 90 deg CCW)
    // For iPads, the default image rotation is portrait mode with the forward facing camera on the top-right (i.e. no rotation of device)
    // For rotation purposes, iPads already have the correct rotation. iPhones need a +90 deg rotation.
    final String imageModel = exifData['Image Model'].printable;
    if (imageModel.contains('iPhone 11')) {
      log('This is an iPhone. Correcting image rotation.');
      if (exifData['Image Orientation'].printable.contains('Horizontal')) { // CW landscape
        fixedImage = img.copyRotate(originalImage, 0);
      } else if (exifData['Image Orientation'].printable.contains('90 CW')) { // Normal portrait
        fixedImage = img.copyRotate(originalImage, 90);
      } else if (exifData['Image Orientation'].printable.contains('180')) { // CCW landscape
        fixedImage = img.copyRotate(originalImage, 180);
      } else if (exifData['Image Orientation'].printable.contains('CCW')) { // Upside down portrait
        fixedImage = img.copyRotate(originalImage, 270);
      } else {
        log('Rotation case not recognized.');
        fixedImage = img.copyRotate(originalImage, 0);
      }
    } else {
      if (imageModel.contains('iPad')) {
        log('This is an iPad. No rotation correction necessary.');
      } else if (imageModel.contains('iPhone X')) {
        log('This is an iPhone X. No rotation correction necessary.');
      } else {
        log('Device type case not recognized. No rotation correction applied.');
      }
      fixedImage = img.copyRotate(originalImage, 0);
    }

    return fixedImage;
  }
}














class VideoResponse {
  final List<String> filePaths;

  VideoResponse({this.filePaths});

  factory VideoResponse.fromJson(Map<String,dynamic> json) {
    return VideoResponse(filePaths: json['file_paths'].cast<String>());
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
