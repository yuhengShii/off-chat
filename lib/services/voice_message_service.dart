// 语音消息服务接口（预留实现）
// 后续实现语音消息时，将使用 record 和 audioplayers 库

abstract class VoiceMessageService {
  /// 开始录音
  Future<String?> startRecording();

  /// 停止录音，返回文件路径
  Future<String?> stopRecording();

  /// 播放语音消息
  Future<void> playVoiceMessage(String filePath);

  /// 停止播放
  Future<void> stopPlayback();

  /// 获取录音状态
  bool get isRecording;

  /// 获取播放状态
  bool get isPlaying;

  /// 获取录音时长（毫秒）
  int get recordingDuration;

  /// 释放资源
  Future<void> dispose();
}

// 预留：录音按钮状态
enum VoiceRecorderState {
  idle,
  recording,
  recordingPaused,
}
