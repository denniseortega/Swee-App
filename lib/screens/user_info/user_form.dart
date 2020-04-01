import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/connectivity/wifi_dev.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  List<String> _registeredUsers = [];
  SnackBar _snackBarHttpTimeout = SnackBar(content: Text("A Swee server connection could not be established. Are you connected Swee wifi?"), action: SnackBarAction(label: 'Dismiss',onPressed: () {}));
  SnackBar _snackBarGoodName = SnackBar(content: Text("Good name!"), action: SnackBarAction(label: 'Dismiss',onPressed: () {}));
  String _mainNodeIP;
  Uri _uriUsers;
  final int _httpTimeoutTime = 2;

  @override
  void initState() {
    _initSharedPreferences();

    _mainNodeIP = Provider.of<SweeUser>(context,listen:false).mainNodeIP;
    _uriUsers = Uri.http('$_mainNodeIP','/users');

    super.initState();
  }

  @override
  void dispose() {
    _lastUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _returnScaffold();
  }

  // _showDialog(BuildContext context) {
  //   Scaffold.of(context).showSnackBar(SnackBar(content: Text('Submitting form')));
  // }

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
                        else if (_registeredUsers.contains(val)) {
                          return 'Username $val is already taken. Please enter a different username.';
                        }
                        return null;
                      },
                      onSaved: (val) =>
                        setState(() => _user.firstName = val),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                      child: RaisedButton(
                        onPressed: () async {                          
                          try {
                            final response = await http.get(_uriUsers).timeout(Duration(seconds:_httpTimeoutTime)); // Relatively fast timeout. If the user is connected to Swee, it should return really fast.
                            final UsersResponse registeredUserData = UsersResponse.fromJson(json.decode(response.body));
                            final List<String> registeredUsers = [];
                            for (UserInfo ui in registeredUserData.users) {
                              registeredUsers.add(ui.username);
                            }
                            _registeredUsers = registeredUsers;
                          }
                          on SocketException catch(_) {
                            log('SocketException');
                          }
                          catch (e) {
                            log('http call to /users timed out after $_httpTimeoutTime second');
                            Scaffold.of(context).showSnackBar(_snackBarHttpTimeout);
                          }
  
                          // await http.get(_uriUsers).timeout(Duration(seconds:_timeoutTime))
                          //   .then((response) {
                          //     final UsersResponse registeredUserData = UsersResponse.fromJson(json.decode(response.body));
                          //     log('http call to /users was successful');
                          //     final List<String> registeredUsers = [];
                          //     for (UserInfo ui in registeredUserData.users) {
                          //       registeredUsers.add(ui.username);
                          //     }
                          //     _registeredUsers = registeredUsers;
                          //   })
                          //   .catchError((e) {
                          //     log('http call to /users timed out after $_timeoutTime seconds');
                          //     Scaffold.of(context).showSnackBar(_snackBarHttpTimeout);
                          //   });

                          final form = _formKey.currentState;
                          if (form.validate()) {
                            form.save();
                            _user.save();
                            _saveSharedPreferences();
                            // _showDialog(context);
                            log('Username available!');
                            Scaffold.of(context).showSnackBar(_snackBarGoodName);
                          }
                        },
                        child: Text('Save')
                      )
                    ),
                    AppBar(title: Text('Upload 3 Selfies')),
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
            )
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