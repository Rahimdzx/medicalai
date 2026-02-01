import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/call_model.dart';
import '../../data/models/user_model.dart';
import '../constants/api_config.dart';
import '../constants/app_constants.dart';

/// Callback types for video call events
typedef OnUserJoined = void Function(int remoteUid);
typedef OnUserOffline = void Function(int remoteUid, UserOfflineReasonType reason);
typedef OnCallStateChanged = void Function(CallState state);
typedef OnNetworkQuality = void Function(int quality);

/// Call state enum
enum CallState {
  idle,
  calling,
  ringing,
  connecting,
  connected,
  reconnecting,
  ended,
}

/// Service for managing video/audio calls with Agora
class VideoCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  RtcEngine? _engine;
  CallState _callState = CallState.idle;
  CallModel? _currentCall;
  int? _localUid;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;

  // Callbacks
  OnUserJoined? onUserJoined;
  OnUserOffline? onUserOffline;
  OnCallStateChanged? onCallStateChanged;
  OnNetworkQuality? onNetworkQuality;

  // Getters
  RtcEngine? get engine => _engine;
  CallState get callState => _callState;
  CallModel? get currentCall => _currentCall;
  int? get localUid => _localUid;
  int? get remoteUid => _remoteUid;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isInCall => _callState == CallState.connected || _callState == CallState.connecting;

  CollectionReference get _callsRef => _firestore.collection(AppConstants.callsCollection);

  // ==================== Initialization ====================

  /// Initialize Agora engine
  Future<void> initialize() async {
    if (_engine != null) return;

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: ApiConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set video encoder configuration for HD quality
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(
            width: ApiConfig.videoWidth,
            height: ApiConfig.videoHeight,
          ),
          frameRate: ApiConfig.videoFrameRate,
          bitrate: ApiConfig.videoBitrate,
        ),
      );

      // Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: _onJoinChannelSuccess,
        onUserJoined: _onUserJoined,
        onUserOffline: _onUserOffline,
        onLeaveChannel: _onLeaveChannel,
        onConnectionStateChanged: _onConnectionStateChanged,
        onNetworkQuality: _onNetworkQuality,
        onError: _onError,
      ));

      debugPrint('Agora engine initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Agora engine: $e');
      rethrow;
    }
  }

  /// Request camera and microphone permissions
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  // ==================== Call Management ====================

  /// Initiate a call
  Future<CallModel?> initiateCall({
    required UserModel caller,
    required UserModel receiver,
    required bool isVideoCall,
    String? appointmentId,
  }) async {
    try {
      // Request permissions
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        debugPrint('Permissions not granted for call');
        return null;
      }

      // Initialize engine if needed
      await initialize();

      // Create call document
      final callId = _uuid.v4();
      final channelName = 'call_$callId';
      final now = DateTime.now();

      final call = CallModel(
        id: callId,
        callerId: caller.uid,
        callerName: caller.name,
        callerPhotoUrl: caller.photoUrl,
        receiverId: receiver.uid,
        receiverName: receiver.name,
        receiverPhotoUrl: receiver.photoUrl,
        channelName: channelName,
        type: isVideoCall ? AppConstants.callTypeVideo : AppConstants.callTypeAudio,
        status: AppConstants.callStatusCalling,
        startTime: now,
        hasVideo: isVideoCall,
        appointmentId: appointmentId,
      );

      // Save to Firestore
      await _callsRef.doc(callId).set(call.toMap());

      _currentCall = call;
      _updateCallState(CallState.calling);

      // Enable video/audio
      if (isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
        await _engine!.disableVideo();
      }

      // Join channel
      await _engine!.joinChannel(
        token: '', // Use empty token for testing; implement token server for production
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: isVideoCall,
          publishMicrophoneTrack: true,
        ),
      );

      return call;
    } catch (e) {
      debugPrint('Error initiating call: $e');
      await _endCallCleanup();
      return null;
    }
  }

  /// Answer an incoming call
  Future<bool> answerCall(CallModel call) async {
    try {
      // Request permissions
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        await rejectCall(call, reason: 'permissions_denied');
        return false;
      }

      // Initialize engine if needed
      await initialize();

      _currentCall = call;
      _updateCallState(CallState.connecting);

      // Update call status
      await _callsRef.doc(call.id).update({
        'status': AppConstants.callStatusActive,
        'answerTime': Timestamp.now(),
      });

      // Enable video/audio based on call type
      if (call.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
        await _engine!.disableVideo();
      }

      // Join channel
      await _engine!.joinChannel(
        token: call.token ?? '',
        channelId: call.channelName,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: call.isVideoCall,
          publishMicrophoneTrack: true,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('Error answering call: $e');
      await _endCallCleanup();
      return false;
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(CallModel call, {String? reason}) async {
    try {
      await _callsRef.doc(call.id).update({
        'status': AppConstants.callStatusRejected,
        'endTime': Timestamp.now(),
        'endReason': reason ?? 'rejected',
      });
    } catch (e) {
      debugPrint('Error rejecting call: $e');
    }
  }

  /// End the current call
  Future<void> endCall({String? reason}) async {
    if (_currentCall == null) return;

    try {
      final now = DateTime.now();
      final answerTime = _currentCall!.answerTime;
      int? duration;

      if (answerTime != null) {
        duration = now.difference(answerTime).inSeconds;
      }

      await _callsRef.doc(_currentCall!.id).update({
        'status': AppConstants.callStatusEnded,
        'endTime': Timestamp.fromDate(now),
        'durationSeconds': duration,
        'endReason': reason ?? 'completed',
      });

      await _endCallCleanup();
    } catch (e) {
      debugPrint('Error ending call: $e');
      await _endCallCleanup();
    }
  }

  /// Mark call as missed
  Future<void> markCallAsMissed(String callId) async {
    try {
      await _callsRef.doc(callId).update({
        'status': AppConstants.callStatusMissed,
        'endTime': Timestamp.now(),
        'endReason': 'no_answer',
      });
    } catch (e) {
      debugPrint('Error marking call as missed: $e');
    }
  }

  // ==================== Call Controls ====================

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _engine?.muteLocalAudioStream(_isMuted);

    if (_currentCall != null) {
      final field = _currentCall!.isCaller(_currentCall!.callerId)
          ? 'callerMuted'
          : 'receiverMuted';
      await _callsRef.doc(_currentCall!.id).update({field: _isMuted});
    }
  }

  /// Toggle camera
  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _engine?.muteLocalVideoStream(_isCameraOff);

    if (_currentCall != null) {
      final field = _currentCall!.isCaller(_currentCall!.callerId)
          ? 'callerCameraOff'
          : 'receiverCameraOff';
      await _callsRef.doc(_currentCall!.id).update({field: _isCameraOff});
    }
  }

  /// Toggle speaker
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await _engine?.setEnableSpeakerphone(_isSpeakerOn);
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    _isFrontCamera = !_isFrontCamera;
    await _engine?.switchCamera();
  }

  /// Enable/disable video mid-call
  Future<void> setVideoEnabled(bool enabled) async {
    if (enabled) {
      await _engine?.enableVideo();
      await _engine?.startPreview();
    } else {
      await _engine?.stopPreview();
      await _engine?.disableVideo();
    }
    _isCameraOff = !enabled;
  }

  // ==================== Call Queries ====================

  /// Stream incoming calls for a user
  Stream<List<CallModel>> getIncomingCalls(String userId) {
    return _callsRef
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.callStatusCalling)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CallModel.fromFirestore(doc)).toList();
    });
  }

  /// Get call history for a user
  Future<List<CallModel>> getCallHistory(String userId, {int limit = 50}) async {
    try {
      // Get calls where user is caller
      final callerCalls = await _callsRef
          .where('callerId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      // Get calls where user is receiver
      final receiverCalls = await _callsRef
          .where('receiverId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      // Combine and sort
      final allCalls = <CallModel>[
        ...callerCalls.docs.map((doc) => CallModel.fromFirestore(doc)),
        ...receiverCalls.docs.map((doc) => CallModel.fromFirestore(doc)),
      ];

      allCalls.sort((a, b) => b.startTime.compareTo(a.startTime));
      return allCalls.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting call history: $e');
      return [];
    }
  }

  /// Stream call document for real-time updates
  Stream<CallModel?> streamCall(String callId) {
    return _callsRef.doc(callId).snapshots().map((doc) {
      if (doc.exists) {
        return CallModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Rate call quality
  Future<void> rateCall(String callId, int rating, {String? feedback}) async {
    try {
      await _callsRef.doc(callId).update({
        'qualityRating': rating,
        'qualityFeedback': feedback,
      });
    } catch (e) {
      debugPrint('Error rating call: $e');
    }
  }

  // ==================== Private Methods ====================

  void _updateCallState(CallState state) {
    _callState = state;
    onCallStateChanged?.call(state);
  }

  Future<void> _endCallCleanup() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.stopPreview();
      _currentCall = null;
      _remoteUid = null;
      _isMuted = false;
      _isCameraOff = false;
      _isSpeakerOn = true;
      _updateCallState(CallState.ended);
    } catch (e) {
      debugPrint('Error in call cleanup: $e');
    }
  }

  // ==================== Agora Event Handlers ====================

  void _onJoinChannelSuccess(RtcConnection connection, int elapsed) {
    _localUid = connection.localUid;
    debugPrint('Local user joined channel: ${connection.channelId}');
    _updateCallState(CallState.connecting);
  }

  void _onUserJoined(RtcConnection connection, int remoteUid, int elapsed) {
    _remoteUid = remoteUid;
    debugPrint('Remote user joined: $remoteUid');
    _updateCallState(CallState.connected);
    onUserJoined?.call(remoteUid);
  }

  void _onUserOffline(RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
    debugPrint('Remote user offline: $remoteUid, reason: $reason');
    _remoteUid = null;
    onUserOffline?.call(remoteUid, reason);

    // End call if other user left
    if (reason == UserOfflineReasonType.userOfflineQuit) {
      endCall(reason: 'remote_ended');
    }
  }

  void _onLeaveChannel(RtcConnection connection, RtcStats stats) {
    debugPrint('Left channel with stats: ${stats.duration}s');
    _updateCallState(CallState.ended);
  }

  void _onConnectionStateChanged(
    RtcConnection connection,
    ConnectionStateType state,
    ConnectionChangedReasonType reason,
  ) {
    debugPrint('Connection state changed: $state, reason: $reason');

    switch (state) {
      case ConnectionStateType.connectionStateConnecting:
        _updateCallState(CallState.connecting);
        break;
      case ConnectionStateType.connectionStateConnected:
        _updateCallState(CallState.connected);
        break;
      case ConnectionStateType.connectionStateReconnecting:
        _updateCallState(CallState.reconnecting);
        break;
      case ConnectionStateType.connectionStateFailed:
        endCall(reason: 'connection_failed');
        break;
      case ConnectionStateType.connectionStateDisconnected:
        _updateCallState(CallState.ended);
        break;
    }
  }

  void _onNetworkQuality(
    RtcConnection connection,
    int remoteUid,
    QualityType txQuality,
    QualityType rxQuality,
  ) {
    // Convert quality to a simple 0-5 scale
    final quality = txQuality.index < rxQuality.index ? txQuality.index : rxQuality.index;
    onNetworkQuality?.call(quality);
  }

  void _onError(ErrorCodeType err, String msg) {
    debugPrint('Agora error: $err - $msg');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _endCallCleanup();
    await _engine?.release();
    _engine = null;
  }
}
