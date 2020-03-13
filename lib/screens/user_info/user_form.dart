import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

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


  @override
  void initState() {
    // setState(() {
    //   _lastUsernameController = TextEditingController(text: "");
    // });

    _initSharedPreferences();
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