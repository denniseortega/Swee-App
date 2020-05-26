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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  List<VideoPlayerController> _controllers = [];
  List<Future<void>> _controllersInit = [];
  // List<String> _videos = ["https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4","https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4", "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"];
  List<String> _videos = [];
  int _crossAxisCount = 1;
  double _aspectRatio = 16/9; // TODO: kinda sucks that this is hardcoded. figure out how to get the grid to initialize with the correct aspect ratio?
  List<AnimationController> _animationControllers = [];
 
  @override
  void initState() {
    // _videos = Provider.of<SweeUser>(context,listen:false).videoPathsCurrentHole; // Get this
    _initVideoPlayers();
    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].dispose();
      _animationControllers[i].dispose();
    } 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Videos for Hole 123')),
      body:
      RefreshIndicator(
        onRefresh: _refreshGridView,
        child: GridView.builder(
          itemCount: _controllers.isEmpty? 1:_controllers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _controllers.isEmpty? 1:_crossAxisCount,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
            childAspectRatio: _controllers.isEmpty? 1:_aspectRatio,//_controllers[0].value.aspectRatio, // Grab the first aspect ratio, assuming they're all the same anyways
            ),
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
    final animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationControllers[index]);
    animation.addStatusListener((status) {
      if (status==AnimationStatus.completed) {
        _animationControllers[index].reverse();
      }
    });

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
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
          ),
        ),
        FadeTransition(
          opacity: animation,
          child: FlatButton(
            onPressed: () {
              _animationControllers[index].forward();
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
              _controllers[index].value.isPlaying ? Icons.play_arrow : Icons.pause,
              size: 90,
            ),
          ),
        ),
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

        _animationControllers.add(
          AnimationController(
            vsync: this,
            duration: Duration(milliseconds: 500),
          )
        );
      }
      setState((){}); // Do a setState here so the page will be rebuilt
    }
  }

  Future<void> _refreshGridView() async {
    log('Refreshing "Current Hole"...');
    _controllers = []; // Reset
    _controllersInit = []; // Reset
    _videos = Provider.of<SweeUser>(context,listen:false).videoPathsCurrentHole;
  _initVideoPlayers(); // Re-initialize video player(s)
  }
}