import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName; // مرر هنا الـ Document ID الخاص بالموعد من Firestore
  final String token;       // مرر نصاً فارغاً "" إذا كان مشروعك في وضع Testing Mode

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
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // 1. طلب أذونات الميكروفون والكاميرا
    await [Permission.microphone, Permission.camera].request();

    // 2. إنشاء محرك Agora وتجهيزه
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "068164ddaed64ec482c4dcbb6329786e",
      channelProfile: ChannelProfileType.channelProfileLiveStreaming, // ضروري لعمل الـ Broadcaster
    ));

    // 3. إعداد مستمعي الأحداث لربط الطرفين
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("تم الانضمام بنجاح للقناة: ${widget.channelName}");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("الطرف الآخر انضم للمكالمة UID: $remoteUid");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("الطرف الآخر غادر المكالمة");
          setState(() => _remoteUid = null);
          if (mounted) Navigator.pop(context);
        },
        onError: (err, msg) {
          debugPrint("خطأ في Agora: $err - $msg");
        },
      ),
    );

    // 4. تفعيل الفيديو وتحديد الدور كـ Broadcaster (الحل لمشكلة الـ Audience)
    await _engine.enableVideo();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.startPreview();

    // 5. الانضمام الفعلي للقناة
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0, // 0 تجعل Agora يولد معرفاً تلقائياً
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
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
          // عرض فيديو الطرف الآخر (يملأ الشاشة)
          Center(child: _remoteVideo()),

          // عرض فيديو المستخدم الحالي (صغير في الزاوية)
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
                    : const Center(child: CircularProgressIndicator(color: Colors.blue)),
              ),
            ),
          ),

          // أزرار التحكم في أسفل الشاشة
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
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 25),
            Text(
              "Waiting for the other party...\nبانتظار انضمام الطرف الآخر\nОжидание подключения...",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
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
          // زر كتم الميكروفون
          _buildActionButton(
            onPressed: () {
              setState(() => _muted = !_muted);
              _engine.muteLocalAudioStream(_muted);
            },
            icon: _muted ? Icons.mic_off : Icons.mic,
            color: _muted ? Colors.blueAccent : Colors.white24,
          ),
          const SizedBox(width: 20),
          // زر إنهاء المكالمة
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
          ),
          const SizedBox(width: 20),
          // زر تبديل الكاميرا (أمامية/خلفية)
          _buildActionButton(
            onPressed: () => _engine.switchCamera(),
            icon: Icons.switch_camera,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required Color color}) {
    return RawMaterialButton(
      onPressed: onPressed,
      shape: const CircleBorder(),
      elevation: 2.0,
      fillColor: color,
      padding: const EdgeInsets.all(12.0),
      child: Icon(icon, color: Colors.white, size: 20.0),
    );
  }
}
