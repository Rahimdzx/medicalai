import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String token;

  const VideoCallScreen({
    super.key, 
    required this.channelName, 
    required this.token
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  late RtcEngine _engine;
  bool _localUserJoined = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // طلب الأذونات
    await [Permission.microphone, Permission.camera].request();

    // إنشاء المحرك
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "068164ddaed64ec482c4dcbb6329786e",
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUid = null);
          Navigator.pop(context);
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 120, height: 180,
              margin: const EdgeInsets.only(top: 40, left: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _localUserJoined 
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Text('في انتظار انضمام الطرف الآخر...', 
          style: TextStyle(color: Colors.white));
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() => _muted = !_muted);
              _engine.muteLocalAudioStream(_muted);
            },
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            fillColor: _muted ? Colors.blueAccent : Colors.white,
            child: Icon(_muted ? Icons.mic_off : Icons.mic, size: 20),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
            fillColor: Colors.redAccent,
            child: const Icon(Icons.call_end, color: Colors.white, size: 35),
          ),
          RawMaterialButton(
            onPressed: () => _engine.switchCamera(),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            fillColor: Colors.white,
            child: const Icon(Icons.switch_camera, size: 20),
          ),
        ],
      ),
    );
  }
}
