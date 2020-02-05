import 'package:flutter/material.dart';
import 'app.dart';

void main() => runApp(MyApp());





































// import 'package:flutter/material.dart';
// import 'app.dart';

// void main() => runApp(App());


// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Swee',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {

//   File _pickedImage;

//   void _pickImage() async {
//     final imageSource = await showDialog<ImageSource>(
//         context: context,
//         builder: (context) =>
//             AlertDialog(
//               title: Text("Select the image source"),
//               actions: <Widget>[
//                 MaterialButton(
//                   child: Text("Camera"),
//                   onPressed: () => Navigator.pop(context, ImageSource.camera),
//                 ),
//                 MaterialButton(
//                   child: Text("Gallery"),
//                   onPressed: () => Navigator.pop(context, ImageSource.gallery),
//                 )
//               ],
//             )
//     );

//     if(imageSource != null) {
//       final file = await ImagePicker.pickImage(source: imageSource);
//       if(file != null) {
//         setState(() => _pickedImage = file);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Swee"),
//       ),
//       body: Center(
//         child: _pickedImage == null ?
//         Text("Nothing to show") :
//         Image(image: FileImage(_pickedImage)),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _pickImage,
//         child: Icon(Icons.image),
//       ),
//     );
//   }
// }
































// import 'package:flutter/material.dart';


// class MyHomePage extends StatelessWidget {

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       body: SafeArea(
//           child: Column(children: <Widget>[
//           Image.asset("images/manface.png"),
//           FlatButton(
//             child: Text("Take Picture", style: TextStyle(color: Colors.white)),
//             color: Colors.blue, 
//             onPressed: () {},
//           )
//         ]),
//       )
//     );

//   }

// }