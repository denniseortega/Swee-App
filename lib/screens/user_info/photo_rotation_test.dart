import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'dart:io';
import 'package:flutter/widgets.dart';

class PhotoRotationTest extends StatefulWidget {
  @override
  _PhotoRotationTestState createState() => _PhotoRotationTestState();
}

class _PhotoRotationTestState extends State<PhotoRotationTest> {
  double _imageSize = 175;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('This screen displays the exact images uploaded to the Swee server (after rotation correction and resizing)'),
        SizedBox(height:25),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling in this ListView instance, since the parent ListView srolls
          shrinkWrap: true,
          itemCount: Provider.of<SweeUser>(context,listen:false).imagePaths.length,
          // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
          itemBuilder: (BuildContext context,int index) {
            String thisImagePath = Provider.of<SweeUser>(context,listen:false).imagePathsRotated[index];
            bool imageExists = false;
            if (File(thisImagePath).existsSync()) {
              imageExists = true;
            }

            if (imageExists) {
              return Image(
                image: FileImage(File(thisImagePath)),
                height: _imageSize,
              );

            } else {
              return Text('Image Does Not Exist');
            }
          },
        ),
      ],
    );
  }
}