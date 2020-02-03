// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';

// List<CameraDescription> cameras;

// class CameraWidget extends StatefulWidget {
//   @override
//   CameraState createState() => CameraState();
// }

// class CameraState extends State<CameraWidget> {
//   List<CameraDescription> cameras;
//   CameraController controller;
//   bool isReady = false;
//   bool showCamera = true;
//   String imagePath;
//   //Inputs
//   TextEditingController nameController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     setupCameras();
//   }

//   Future<void> setupCameras() async {
//     try {
//       cameras = await availableCameras();
//       controller = new CameraController(cameras[0], ResolutionPreset.medium);
//       await controller.initialize();
//     } on CameraException catch (_) {
//       setState(() {
//         isReady = false;
//       });
//     }
//     setState(() {
//       isReady = true;
//     });
//   }

//   // Widget build(BuildContext context) {
//   //   if (!isReady && !controller.value.isInitialized) {
//   //     return Container();
//   //   }
//   //   return AspectRatio(
//   //       aspectRatio: controller.value.aspectRatio,
//   //       child: CameraPreview(controller));
//   // }

//    Widget build(BuildContext context) {
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

//   Widget captureControlRowWidget() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       mainAxisSize: MainAxisSize.max,
//       children: <Widget>[
//         IconButton(
//           icon: const Icon(Icons.camera_alt),
//           color: Colors.blue,
//           onPressed: controller != null && controller.value.isInitialized
//               ? onTakePictureButtonPressed
//               : null,
//         ),
//       ],
//     );
//   }
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

//   void onTakePictureButtonPressed() {
//     takePicture().then((String filePath) {
//       if (mounted) {
//         setState(() {
//           showCamera = false;
//           imagePath = filePath;
//         });
//       }
//     });
//   }

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

//   Future<String> takePicture() async {
//     if (!controller.value.isInitialized) {
//       return null;
//     }
//     final Directory extDir = await getApplicationDocumentsDirectory();
//     final String dirPath = '${extDir.path}/Pictures/flutter_test';
//     await Directory(dirPath).create(recursive: true);
//     final String filePath = '$dirPath/${timestamp()}.jpg';

//     if (controller.value.isTakingPicture) {
//       return null;
//     }

//     try {
//       await controller.takePicture(filePath);
//     } on CameraException catch (e) {
//       return null;
//     }
//     return filePath;
//   }

//   Widget cameraOptionsWidget() {
//     return Padding(
//       padding: const EdgeInsets.all(5.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: <Widget>[
//           showCamera ? cameraTogglesRowWidget() : Container(),
//         ],
//       ),
//     );
//   }

//   Widget cameraTogglesRowWidget() {
//     final List<Widget> toggles = <Widget>[];

//     if (cameras != null) {
//       if (cameras.isEmpty) {
//         return const Text('No camera found');
//       } else {
//         for (CameraDescription cameraDescription in cameras) {
//           toggles.add(
//             SizedBox(
//               width: 90.0,
//               child: RadioListTile<CameraDescription>(
//                 title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
//                 groupValue: controller?.description,
//                 value: cameraDescription,
//                 onChanged: controller != null ? onNewCameraSelected : null,
//               ),
//             ),
//           );
//         }
//       }
//     }

//     return Row(children: toggles);
//   }

  
//   void onNewCameraSelected(CameraDescription cameraDescription) async {
//     if (controller != null) {
//       await controller.dispose();
//     }
//     controller = CameraController(cameraDescription, ResolutionPreset.high);

//     controller.addListener(() {
//       if (mounted) setState(() {});
//       if (controller.value.hasError) {
//         showInSnackBar('Camera error ${controller.value.errorDescription}');
//       }
//     });

//     try {
//       await controller.initialize();
//     } on CameraException catch (e) {
//       showInSnackBar('Camera error ${e}');
//     }

//     if (mounted) {
//       setState(() {});
//     }
//   }


//  Widget userInfoInputsWidget() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 3, bottom: 4.0),
//           child: TextField(
//               controller: nameController,
//               onChanged: (v) => nameController.text = v,
//               decoration: InputDecoration(
//                 labelText: 'Name',
//               )),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Builder(
//             builder: (context) {
//               return RaisedButton(
//                 onPressed: () => {},
//                 color: Colors.lightBlue,
//                 child: Text('Add user'),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
  
// }
