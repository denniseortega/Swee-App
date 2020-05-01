import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../main.dart';
import 'dart:developer';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoLibrary extends StatefulWidget {
  VideoLibrary({Key key}) : super(key: key);

  @override
  VideoLibraryState createState() => VideoLibraryState();
}

class VideoLibraryState extends State<VideoLibrary> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Library'),
      ),
      body: 
      RefreshIndicator(
        onRefresh: _refresh,
        child: 
        ListView.separated(
          // controller: ScrollController(),
          // physics: const AlwaysScrollableScrollPhysics(),//NeverScrollableScrollPhysics(), // Disable scrolling in this ListView instance, since the parent ListView srolls
          // shrinkWrap: true,
          itemCount: Provider.of<SweeUser>(context,listen:true).videoPathsLocal.isEmpty? 1:Provider.of<SweeUser>(context,listen:true).videoPathsLocal.length,
          separatorBuilder: (BuildContext context, int index) => Divider(),
          itemBuilder: (BuildContext context,int index){
            List<String> _vidPaths = Provider.of<SweeUser>(context,listen:true).videoPathsLocal;
            if (_vidPaths.isEmpty) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height:25),
                    Text('No Videos Found'),
                    SizedBox(height:25),
                    Text('Pull Down to Refresh'),
                  ],
                ),
              );
            }
            else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget> [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget> [
                      Text('Course: Test, Hole: -1, Shot: -2'),
                      Container(
                        child: Row(
                          children: [
                            RaisedButton(
                              child: Icon(Icons.movie),
                              onPressed: () {
                                Navigator.push(context,MaterialPageRoute(builder: (context) => VidPlay(videoPath: Provider.of<SweeUser>(context,listen:true).videoPathsLocal[index])));
                              },
                            ),
                            SizedBox(width:10),
                            RaisedButton(
                              child: Icon(Icons.delete_forever),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Delete Video from Library'),
                                      content: Text('Are you sure you want to delete this video? This action cannot be undone.'),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text('Nope!'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        FlatButton(
                                          child: Text('Delete Forever'),
                                          onPressed: () {
                                            String _thisVid = _vidPaths[index];
                                            log('Deleting $_thisVid');
                                            _vidPaths.remove(_thisVid);
                                            Provider.of<SweeUser>(context,listen:false).setVideoPathsLocal(_vidPaths);
                                            setState((){});
                                            _saveSharedPrefs(_vidPaths);



                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                );
                              }
                            ),
                          ], 
                        ),
                      ),
                    ]
                  ),
                ],
              );
            }
          },
        ), 
      ),
    );
  }

  Future<void> _refresh() async {
    log('Refreshing "Video Library"...');
    setState(() {});
  }

  void _saveSharedPrefs(videoPathsLocalIn) async {
    log('home_screen: _saveSharedPrefs');
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('videoPathsLocal', videoPathsLocalIn);
  }
}











class VidPlay extends StatefulWidget {
  final String videoPath;

  VidPlay({Key key, this.videoPath}) : super(key: key);

  @override
  VidPlayState createState() => VidPlayState();
}

class VidPlayState extends State<VidPlay> {
  VideoPlayerController _videoPlayerController1;
  ChewieController _chewieController;
  String _videoPath;

  @override
  void initState() {
    if (widget.videoPath==null) {
      _videoPath = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
      _videoPlayerController1 = VideoPlayerController.network(_videoPath);
    }
    else {
      _videoPath = 'file://'+widget.videoPath;
      log('local video path: $_videoPath');
      _videoPlayerController1 = VideoPlayerController.network(
        _videoPath);
    }

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: false,
      // Try playing around with some of these other options:
      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      autoInitialize: true,
    );

    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Player"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: <Widget> [
          // Text(_videoPath),
          // SizedBox(height:10),
          Chewie(controller: _chewieController,),
        ]
      )
    );
  }
}