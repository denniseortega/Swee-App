import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

File _pickedImage; // Moved this out here, which allows the selected image to persist when navigating between screens

class ImageSelector extends StatefulWidget {

  @override
  _ImageSelector createState() => _ImageSelector();
}

class _ImageSelector extends State<ImageSelector> {

  // File _pickedImage; // Moved the variable declaration outside of the class, see top of file

  void _pickImage() async {
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
        setState(() => _pickedImage = file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Image Selector"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget> [
          Center(
            child: _pickedImage == null ?
            Text("Select an image") :
            Image(image: FileImage(_pickedImage),height: 250,),
          ),
          SizedBox(height: 25),
          Center(
            child: _pickedImage == null ?
            Text("") : Text("File path: " + _pickedImage.path, textAlign: TextAlign.center,),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.image),
      ),
    );
  }
}