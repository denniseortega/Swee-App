import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer';
import 'package:provider/provider.dart';
import '../../main.dart';

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  List<VideoPlayerController> _controllers = [];
  List<Future<void>> _controllersInit = [];
  // List<String> videos = ["http://192.168.0.174:5001/downloads/alex/20200321-153527.mp4","https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"];
  List<String> _videos = [];

  @override
  void initState() {
    _videos = Provider.of<SweeUser>(context,listen:false).videoPaths; // Get this
    _initVideoPlayers();
    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].dispose();
    } 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Videos for Hole 123')),
      body:
      RefreshIndicator(
        onRefresh: _refreshGridView,
        child: GridView.builder(
          itemCount: _controllers.isEmpty? 1:_controllers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _controllers.isEmpty? 1:3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
          itemBuilder: (BuildContext context, int index){
            if (_controllers.isEmpty) {
              return _returnEmptyGrid();
            }
            else {
              return _returnVideoPlayerStack(index);
            }
          },
        ),
      ),
    );
  }

  Center _returnEmptyGrid() {
    // Ok, it's not really an empty grid...
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

  Stack _returnVideoPlayerStack(index) {
    String thisvid = _videos[index];
    log('$thisvid');

    return Stack(
      children: <Widget>[
        Center(
          child:FutureBuilder(
          future: _controllersInit[index],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the VideoPlayerController has finished initialization, use
                // the data it provides to limit the aspect ratio of the video.
                return AspectRatio(
                  aspectRatio: _controllers[index].value.aspectRatio,
                  // Use the VideoPlayer widget to display the video.
                  child: VideoPlayer(_controllers[index]),
                );
              } else {
                // If the VideoPlayerController is still initializing, show a loading spinner.
                return Center(child: CircularProgressIndicator());
              }
            },
          )  
        ),
        Center(
          child: ButtonTheme(
            height: 100.0,
            minWidth: 200.0,
            child: RaisedButton(
              padding: EdgeInsets.all(60.0),
              color: Colors.transparent,
              elevation: 0,
              textColor: Colors.white,
              onPressed: () {
                // Wrap the play or pause in a call to `setState`. This ensures the correct icon is shown.
                setState(() {
                  if (_controllers[index].value.isPlaying) {
                    // If the video is playing, pause it.
                    _controllers[index].pause();
                  } else {
                    // If the video is paused, play it.
                    _controllers[index].play();
                  }
                });
              },
              child: Icon(
                _controllers[index].value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 120.0,
              ),
            )
          )
        )
      ],
    );
  }

  Future<void> _initVideoPlayers() async {
    if (_videos.isEmpty) {
      _controllers = []; // Reset
      setState(() {_controllersInit = [];}); // Reset, do a setState here so the page will be rebuilt
    }
    else {
      for (var i = 0; i < _videos.length; i++) {
        String _videoPath = _videos[i]; // USE THIS FOR LOCAL VIDEOS: "file://"+_videos[i];
        _controllers.add(VideoPlayerController.network(_videoPath));
        _controllers[i].setLooping(true);
        _controllersInit.add(_controllers[i].initialize());
      }
      setState((){}); // Do a setState here so the page will be rebuilt
    }
  }

  Future<void> _refreshGridView() async {
    log('Refreshing GridView()');
    _controllers = []; // Reset
    _controllersInit = []; // Reset
    // _videos.add("https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"); // Add new video to videos for test. IRL this should reference the SweeUser()
    _videos = Provider.of<SweeUser>(context,listen:false).videoPaths;
    _initVideoPlayers(); // Re-initialize video player(s)
  }
}