import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

File _pickedImage; // Leave this here so it persists when you switch between screens

class ImageSelector extends StatefulWidget {

  @override
  _ImageSelector createState() => _ImageSelector();
}

class _ImageSelector extends State<ImageSelector> {
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
        setState(() {
          _pickedImage = file;
          // Provider.of<SweeUser>(context,listen:false).addImagePath(_pickedImage.path);
        });
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
            child: Consumer<SweeUser>(builder:(context,sweeuser,child)=>Text("This is the value saved to SweeUser.imagePaths: ${sweeuser.imagePaths}", textAlign: TextAlign.center,))
          //   child: _pickedImage == null ?
          //   Text("Select an image") :
          //   Image(image: FileImage(_pickedImage),height: 250,),
          // ),
          // SizedBox(height: 25),
          // Center(
          //   child: _pickedImage == null ?
          //   Text("") : Consumer<SweeUser>(builder:(context,sweeuser,child)=>Text("This is the value saved to SweeUser.imagePaths: ${sweeuser.imagePaths}", textAlign: TextAlign.center,)),
          ),
          Center(
            child: Consumer<SweeUser>(builder:(context,sweeuser,child)=>Text("This is the value saved to SweeUser.videoPaths: ${sweeuser.videoPaths}", textAlign: TextAlign.center,))
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

















// import 'package:flutter/material.dart';
// import 'dart:async';

// import 'package:multi_image_picker/multi_image_picker.dart';

// void main() => runApp(new MyApp());

// class ImageSelector extends StatefulWidget {

//   @override
//   _ImageSelector createState() => _ImageSelector();
// }

// class _ImageSelector extends State<ImageSelector> {
//   List<Asset> images = List<Asset>();
//   String _error = 'No Error Dectected';

//   @override
//   void initState() {
//     super.initState();
//   }

//   Widget buildGridView() {
//     return GridView.count(
//       crossAxisCount: 3,
//       children: List.generate(images.length, (index) {
//         Asset asset = images[index];
//         return AssetThumb(
//           asset: asset,
//           width: 300,
//           height: 300,
//         );
//       }),
//     );
//   }

//   Future<void> loadAssets() async {
//     List<Asset> resultList = List<Asset>();
//     String error = 'No Error Dectected';

//     try {
//       resultList = await MultiImagePicker.pickImages(
//         maxImages: 300,
//         enableCamera: true,
//         selectedAssets: images,
//         cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
//         materialOptions: MaterialOptions(
//           actionBarColor: "#abcdef",
//           actionBarTitle: "Example App",
//           allViewTitle: "All Photos",
//           useDetailsView: false,
//           selectCircleStrokeColor: "#000000",
//         ),
//       );
//     } on Exception catch (e) {
//       error = e.toString();
//     }

//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) return;

//     setState(() {
//       images = resultList;
//       _error = error;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return new MaterialApp(
//       home: new Scaffold(
//         appBar: new AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         body: Column(
//           children: <Widget>[
//             Center(child: Text('Error: $_error')),
//             RaisedButton(
//               child: Text("Pick images"),
//               onPressed: loadAssets,
//             ),
//             Expanded(
//               child: buildGridView(),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
