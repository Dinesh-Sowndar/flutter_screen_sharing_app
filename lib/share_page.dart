import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_background/flutter_background.dart';

class SharePage extends StatefulWidget {
  final String token;
  const SharePage({super.key, required this.token});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final Room room = Room();
  bool _isSharing = false;
  bool _connecting = true;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    try {
      await room.connect(
        'wss://flutter-demo-app-jbk0o0lo.livekit.cloud', // Replace with your LiveKit server URL
        widget.token,
      );
      setState(() => _connecting = false);
    } catch (e) {
      setState(() => _connecting = false);

      print('---------------e-----------------');
      print(e);
      print('--------------------------------');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleScreenShare() async {
    if (_isSharing) {
      // 🔴 Stop sharing
      await _disableScreenShare();
    } else {
      // 🟢 Start sharing
      await _enableScreenShare();
    }
  }

  Future<void> _enableScreenShare() async {
    try {
      final participant = room.localParticipant;
      if (participant == null) return;

      if (lkPlatformIs(PlatformType.android)) {
        // Request capture permission
        if (!await Helper.requestCapturePermission()) return;

        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Screen Sharing',
          notificationText: 'Sharing your screen via LiveKit',
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(
            name: 'livekit_ic_launcher',
            defType: 'mipmap',
          ),
        );

        // ✅ Always initialize before enabling background execution
        bool initialized = await FlutterBackground.initialize(
          androidConfig: androidConfig,
        );
        if (!initialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize background service'),
            ),
          );
          return;
        }

        // ✅ Now enable background execution
        if (!FlutterBackground.isBackgroundExecutionEnabled) {
          await FlutterBackground.enableBackgroundExecution();
        }

        setState(() => _isSharing = true);
      }

      if (lkPlatformIs(PlatformType.iOS)) {
        final track = await LocalVideoTrack.createScreenShareTrack(
          const ScreenShareCaptureOptions(
            useiOSBroadcastExtension: true,
            maxFrameRate: 15.0,
          ),
        );
        await participant.publishVideoTrack(track);
      } else if (lkPlatformIsWebMobile()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screen share is not supported on mobile web'),
          ),
        );
        return;
      } else {
        await participant.setScreenShareEnabled(true, captureScreenAudio: true);
      }

      setState(() => _isSharing = true);
    } catch (e) {
      print('---------------e-----------------');
      print(e);
      print('--------------------------------');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start screen share: $e')),
      );
      setState(() => _isSharing = false);
    }
  }

  Future<void> _disableScreenShare() async {
    try {
      final participant = room.localParticipant;
      if (participant == null) return;

      await participant.setScreenShareEnabled(false);

      if (lkPlatformIs(PlatformType.android)) {
        if (FlutterBackground.isBackgroundExecutionEnabled) {
          await FlutterBackground.disableBackgroundExecution();
        }
      }

      setState(() => _isSharing = false);
    } catch (e) {
      print('---------------e-----------------');
      print(e);
      print('--------------------------------');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop screen share: $e')),
      );
    }
  }

  @override
  void dispose() {
    room.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Screen Share')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _toggleScreenShare,
          icon: Icon(_isSharing ? Icons.stop_screen_share : Icons.screen_share),
          label: Text(_isSharing ? 'Stop Sharing' : 'Start Screen Share'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSharing ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
    );
  }
}
