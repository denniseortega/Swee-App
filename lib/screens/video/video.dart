import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer';

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  List<VideoPlayerController> _controllers = [];
  List<Future<void>> _controllersInit = [];
  List<String> videos = ["https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"];

  @override
  void initState() {
    _initVideoPlayers();
    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    // _controller.dispose();
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].dispose();
    } 

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Video')),
      body: RefreshIndicator(
        onRefresh: _refreshGridView,
        child: GridView.builder(
          itemCount: _controllers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
          itemBuilder: (BuildContext context, int index){
            return _returnVideoPlayerStack(index);
          },
        ),
      ),
    );
  }

  Stack _returnVideoPlayerStack(index) {
    return Stack(
      children: <Widget>[
        Center(child:FutureBuilder(
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
        )),
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
                // Wrap the play or pause in a call to `setState`. This ensures the
                // correct icon is shown.
                setState(() {
                  // If the video is playing, pause it.
                  if (_controllers[index].value.isPlaying) {
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
    for (var i = 0; i < videos.length; i++) {
      _controllers.add(VideoPlayerController.network(videos[i]));
      _controllersInit.add(_controllers[i].initialize());
      _controllers[i].setLooping(true);
    } 
  }

  Future<void> _refreshGridView() async {
    log('Refreshing GridView()');
    setState((){_controllers = [];}); // Reset
    setState((){_controllersInit = [];}); // Reset
    setState(() {
      videos.add("https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"); // Add new video to videos for test. IRL this should reference the SweeUser()
    });
    _initVideoPlayers(); // Re-initialize video player(s)
  }
}