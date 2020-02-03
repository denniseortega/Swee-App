import 'dart:convert' show json;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';


class  UserInfoPage extends StatefulWidget {
  UserInfoPage({Key key}) : super(key: key);

  @override
  UserInfoPageState createState() => UserInfoPageState();
}

class UserInfoPageState extends State<UserInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: new Container(
      child: new Center(
        child: new FutureBuilder(
            future:
                DefaultAssetBundle.of(context).loadString('assets/users.json'),
            builder: (context, snapshot) {
              var users = json.decode(snapshot.data.toString());

              return new ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  var user = users[index];
                  return new Card(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        new Text("Name: " + user['name'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24)),
                        new Image.network(user['image'], height: 200)
                      ],
                    ),
                  );
                },
                itemCount: users == null ? 0 : users.length,
              );
            }),
      ),
    ));
  }
}

// class CameraState extends State<CameraWidget> {
//   final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
//   List<CameraDescription> cameras;
//   CameraController controller;
//   bool isReady = false;
//   bool showCamera = true;
//   String imagePath;
//   // Inputs
//   TextEditingController nameController = TextEditingController();
  
//   @override
//     void initState() {
//       super.initState();
//       setupCameras();
//     }

//     Future<void> setupCameras() async {
//       try {
//         cameras = await availableCameras();
//         controller = new CameraController(cameras[0], ResolutionPreset.medium);
//         await controller.initialize();
//       } on CameraException catch (_) {
//         setState(() {
//           isReady = false;
//         });
//       }
//       setState(() {
//         isReady = true;
//       });
//     }

//   Widget build(BuildContext context) {
//       return Scaffold(
//           key: scaffoldKey,
//           body: Center(
//               child: SingleChildScrollView(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: <Widget>[
//                 Center(
//                   child: showCamera
//                       ? Container(
//                           height: 290,
//                           child: Padding(
//                             padding: const EdgeInsets.only(top: 5),
//                             child: Center(child: cameraPreviewWidget()),
//                           ),
//                         )
//                       : Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: <Widget>[
//                               imagePreviewWidget(),
//                               editCaptureControlRowWidget(),
//                             ]),
//                 ),
//                 showCamera ? captureControlRowWidget() : Container(),
//                 cameraOptionsWidget(),
//                 userInfoInputsWidget()
//               ],
//             ),
//           )));
//     }

//   Widget cameraPreviewWidget() {
//       if (!isReady || !controller.value.isInitialized) {
//         return Container();
//       }
//       return AspectRatio(
//           aspectRatio: controller.value.aspectRatio,
//           child: CameraPreview(controller));
//     }

//   Widget imagePreviewWidget() {
//       return Container(
//           child: Padding(
//         padding: const EdgeInsets.only(top: 10),
//         child: Align(
//           alignment: Alignment.topCenter,
//           child: imagePath == null
//               ? null
//               : SizedBox(
//                   child: Image.file(File(imagePath)),
//                   height: 290.0,
//                 ),
//         ),
//       ));
//     }
  
//   Widget editCaptureControlRowWidget() {
//       return Padding(
//         padding: const EdgeInsets.only(top: 5),
//         child: Align(
//           alignment: Alignment.topCenter,
//           child: IconButton(
//             icon: const Icon(Icons.camera_alt),
//             color: Colors.blue,
//             onPressed: () => setState(() {
//                   showCamera = true;
//                 }),
//           ),
//         ),
//       );
//     }
 
