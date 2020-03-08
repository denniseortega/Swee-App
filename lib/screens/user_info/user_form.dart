import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

final _user = User(); // Moved this out here, which allows the user info to persist when navigating between screens
File _pickedImage1; // Leave this here so it persists when you switch between screens
File _pickedImage2;
File _pickedImage3; // IF YOU CHANGE THE NUMBER OF IMAGES, DON'T FORGET TO UPDATE THE "IMAGEPATHS" LIST INTIALIZATION IN MAIN/SWEEUSER()
double _imageSize = 175;

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _initSharedPreferences(); // TODO: revamp with FutureBuilder, see https://stackoverflow.com/questions/49930180/flutter-render-widget-after-async-call
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Container(
        padding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Builder(
          builder: (context) => Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: _user.firstName,
                  decoration:
                    InputDecoration(labelText: 'First name'),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter your first name';
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
                    onPressed: () {
                      final form = _formKey.currentState;
                      if (form.validate()) {
                        form.save();
                        _user.save();
                        // Provider.of<SweeUser>(context,listen:false).setUsername(_user.firstName);
                        _saveSharedPreferences();
                        _showDialog(context);
                      }
                    },
                    child: Text('Save')
                  )
                ),
                Consumer<SweeUser>(
                  builder: (context,sweeuser,child) => Text('This is the value saved to SweeUser.username: ${sweeuser.username}'),
                ),
                SizedBox(height:50),
                AppBar(title: Text('Upload 3 Selfies')),
                SizedBox(height:50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget> [
                        Center(
                          child: _pickedImage1 == null ?
                          FloatingActionButton(
                            onPressed: (){_pickImage(1);},
                            child: Icon(Icons.image),
                          ) :
                          Image(image: FileImage(_pickedImage1),height: _imageSize,),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget> [
                        Center(
                          child: _pickedImage2 == null ?
                          FloatingActionButton(
                            onPressed: (){_pickImage(2);},
                            child: Icon(Icons.image),
                          ) :
                          Image(image: FileImage(_pickedImage2),height: _imageSize,),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget> [
                        Center(
                          child: _pickedImage3 == null ?
                          FloatingActionButton(
                            onPressed: (){_pickImage(3);},
                            child: Icon(Icons.image),
                          ) :
                          Image(image: FileImage(_pickedImage3),height: _imageSize,),
                        ),
                      ],
                    ),
                  ],
                ),
              ]
            )
          )
        )
      )
    );
  }

  _showDialog(BuildContext context) {
    Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Submitting form')));
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
        switch(_pickedImageNum) {
          case 1: {
            setState(() {
              _pickedImage1 = file;
              Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImageNum,_pickedImage1.path);
            });
          }
          break;

          case 2: {
            setState(() {
              _pickedImage2 = file;
              Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImageNum,_pickedImage2.path);
            });
          }
          break;      

          case 3: {
            setState(() {
              _pickedImage3 = file;
              Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImageNum,_pickedImage3.path);
            });
          }
          break;

          default: {
            log('Case not recognized.');
          }
          break;
        }
      }
    }
  }

  _initSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'username';
    final value = prefs.getString(key) ?? 'Default User Name';
    _user.firstName = value; // Set the local variable
    Provider.of<SweeUser>(context,listen:false).setUsername(_user.firstName); // Set SweeUser (shared across multiple screens)
    log('read: $value');
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