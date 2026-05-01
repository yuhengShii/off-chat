import 'package:flutter_test/flutter_test.dart';
import 'package:off_chat/services/voice_message_service.dart';

void main() {
  group('VoiceRecorderState', () {
    test('has correct enum values', () {
      expect(VoiceRecorderState.values, [
        VoiceRecorderState.idle,
        VoiceRecorderState.recording,
        VoiceRecorderState.recordingPaused,
      ]);
    });

    test('idle has index 0', () {
      expect(VoiceRecorderState.idle.index, 0);
    });

    test('recording has index 1', () {
      expect(VoiceRecorderState.recording.index, 1);
    });

    test('recordingPaused has index 2', () {
      expect(VoiceRecorderState.recordingPaused.index, 2);
    });
  });
}
