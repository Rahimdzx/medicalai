import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/api_config.dart';
import 'agora_settings_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String token;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.token,
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

    try {
      // Check if using default App ID
      if (ApiConfig.agoraAppId == '068164ddaed64ec482c4dcbb6329786e') {
        debugPrint('⚠️ WARNING: Using default Agora App ID. Video calls may not work in production.');
      }
      
      // إنشاء المحرك
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: ApiConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
    } catch (e) {
      debugPrint('❌ Error initializing Agora: $e');
      if (mounted) {
        _showErrorDialog('Failed to initialize video call. Please check your Agora settings.');
      }
      return;
    }

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
          if (mounted) Navigator.pop(context);
        },
      ),
    );

    try {
      await _engine.enableVideo();
      await _engine.startPreview();

      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error joining channel: $e');
      if (mounted) {
        _showErrorDialog('Failed to join video call. Error: $e');
      }
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Video Call Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgoraSettingsScreen()),
              );
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          // فيديو المستخدم المحلي
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 120,
              height: 180,
              margin: const EdgeInsets.only(top: 50, left: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24, width: 2),
              ),
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
      return const Center(
        child: Text(
          "Waiting for connection...",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              setState(() => _muted = !_muted);
              _engine.muteLocalAudioStream(_muted);
            },
            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
            color: Colors.white,
            style: IconButton.styleFrom(backgroundColor: _muted ? Colors.blue : Colors.white24),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.call_end),
            color: Colors.white,
            iconSize: 35,
            style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () => _engine.switchCamera(),
            icon: const Icon(Icons.switch_camera),
            color: Colors.white,
            style: IconButton.styleFrom(backgroundColor: Colors.white24),
          ),
        ],
      ),
    );
  }
}
