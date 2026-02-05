import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service for playing pleasant sound effects in the app
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _player;
  bool soundEnabled = true;
  String? _tempDir;
  bool _isInitialized = false;

  // Cache generated audio files
  final Map<String, String> _audioCache = {};

  /// Initialize the sound service
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      _player = AudioPlayer();
      await _player!.setPlayerMode(PlayerMode.lowLatency);
      final dir = await getTemporaryDirectory();
      _tempDir = dir.path;
      _isInitialized = true;
    } catch (e) {
    }
  }

  /// Play a success/correct sound - pleasant ascending chime
  Future<void> playCorrect() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playChord('correct', [523.25, 659.25, 783.99], 200,
        decay: true,); // C-E-G major chord
  }

  /// Play a failure/incorrect sound - soft descending tone
  Future<void> playIncorrect() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playTone('incorrect', 349.23, 180,
        waveType: WaveType.soft,); // F4, softer
  }

  /// Play a card flip sound - soft whoosh/page turn
  Future<void> playFlip() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playNoise('flip', 80); // Soft noise burst for flip
  }

  /// Play a button tap sound - soft pop
  Future<void> playTap() async {
    if (!soundEnabled) return;
    HapticFeedback.selectionClick();
    await _playTone('tap', 1200, 40, waveType: WaveType.pop);
  }

  /// Play a navigation sound - subtle click
  Future<void> playNavigate() async {
    if (!soundEnabled) return;
    HapticFeedback.selectionClick();
    await _playTone('navigate', 800, 50, waveType: WaveType.soft);
  }

  /// Play a hint reveal sound
  Future<void> playHint() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playChord('hint', [440, 554.37], 150, decay: true); // A-C# (bright)
  }

  /// Play a level up/achievement sound - triumphant fanfare
  Future<void> playAchievement() async {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    await _playMelody('achievement', [
      (523.25, 120), // C5
      (659.25, 120), // E5
      (783.99, 120), // G5
      (1046.50, 250), // C6
    ]);
  }

  /// Play a streak notification sound - exciting ascending notes
  Future<void> playStreak() async {
    if (!soundEnabled) return;
    HapticFeedback.mediumImpact();
    await _playMelody('streak', [
      (659.25, 80), // E5
      (783.99, 80), // G5
      (987.77, 150), // B5
    ]);
  }

  /// Play a completion sound - celebratory melody
  Future<void> playComplete() async {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    await _playMelody('complete', [
      (523.25, 100), // C5
      (587.33, 100), // D5
      (659.25, 100), // E5
      (783.99, 100), // G5
      (1046.50, 300), // C6
    ]);
  }

  /// Play an error sound - gentle warning
  Future<void> playError() async {
    if (!soundEnabled) return;
    HapticFeedback.heavyImpact();
    await _playTone('error', 220, 200, waveType: WaveType.soft);
  }

  /// Play a swipe sound
  Future<void> playSwipe() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playNoise('swipe', 60);
  }

  /// Play difficulty rating sounds
  Future<void> playRatingAgain() async {
    if (!soundEnabled) return;
    HapticFeedback.mediumImpact();
    await _playTone('rating_again', 293.66, 150, waveType: WaveType.soft); // D4
  }

  Future<void> playRatingHard() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playTone('rating_hard', 392.00, 120, waveType: WaveType.soft); // G4
  }

  Future<void> playRatingGood() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playChord('rating_good', [440, 554.37], 150, decay: true); // A-C#
  }

  Future<void> playRatingEasy() async {
    if (!soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playChord('rating_easy', [523.25, 659.25, 783.99], 180,
        decay: true,); // C-E-G
  }

  /// Play a melody (sequence of notes)
  Future<void> _playMelody(
      String cacheKey, List<(double freq, int duration)> notes,) async {
    try {
      await _ensureInitialized();
      if (_player == null || _tempDir == null) return;

      String? filePath = _audioCache[cacheKey];

      if (filePath == null || !File(filePath).existsSync()) {
        const int sampleRate = 44100;

        final audioData = _generateMelodyWavData(notes, sampleRate);
        filePath = '$_tempDir/sound_$cacheKey.wav';
        final file = File(filePath);
        await file.writeAsBytes(audioData);
        _audioCache[cacheKey] = filePath;
      }

      await _player!.stop();
      await _player!.play(DeviceFileSource(filePath));
    } catch (e) {
    }
  }

  /// Play a chord (multiple notes together)
  Future<void> _playChord(
      String cacheKey, List<double> frequencies, int durationMs,
      {bool decay = false,}) async {
    try {
      await _ensureInitialized();
      if (_player == null || _tempDir == null) return;

      String? filePath = _audioCache[cacheKey];

      if (filePath == null || !File(filePath).existsSync()) {
        const int sampleRate = 44100;
        final int numSamples = (sampleRate * durationMs / 1000).round();
        final audioData = _generateChordWavData(
            frequencies, numSamples, sampleRate,
            decay: decay,);

        filePath = '$_tempDir/sound_$cacheKey.wav';
        final file = File(filePath);
        await file.writeAsBytes(audioData);
        _audioCache[cacheKey] = filePath;
      }

      await _player!.stop();
      await _player!.play(DeviceFileSource(filePath));
    } catch (e) {
    }
  }

  /// Play a noise burst (for flip/swipe sounds)
  Future<void> _playNoise(String cacheKey, int durationMs) async {
    try {
      await _ensureInitialized();
      if (_player == null || _tempDir == null) return;

      String? filePath = _audioCache[cacheKey];

      if (filePath == null || !File(filePath).existsSync()) {
        const int sampleRate = 44100;
        final int numSamples = (sampleRate * durationMs / 1000).round();
        final audioData = _generateNoiseWavData(numSamples, sampleRate);

        filePath = '$_tempDir/sound_$cacheKey.wav';
        final file = File(filePath);
        await file.writeAsBytes(audioData);
        _audioCache[cacheKey] = filePath;
      }

      await _player!.stop();
      await _player!.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  /// Play a simple tone with wave type
  Future<void> _playTone(String cacheKey, double frequency, int durationMs,
      {WaveType waveType = WaveType.sine,}) async {
    try {
      await _ensureInitialized();
      if (_player == null || _tempDir == null) return;

      String? filePath = _audioCache[cacheKey];

      if (filePath == null || !File(filePath).existsSync()) {
        const int sampleRate = 44100;
        final int numSamples = (sampleRate * durationMs / 1000).round();
        final audioData = _generateWavData(frequency, numSamples, sampleRate,
            waveType: waveType,);

        filePath = '$_tempDir/sound_$cacheKey.wav';
        final file = File(filePath);
        await file.writeAsBytes(audioData);
        _audioCache[cacheKey] = filePath;
      }

      await _player!.stop();
      await _player!.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  /// Generate melody WAV data
  Uint8List _generateMelodyWavData(
      List<(double freq, int duration)> notes, int sampleRate,) {
    // Calculate total samples
    int totalSamples = 0;
    for (final note in notes) {
      totalSamples += (sampleRate * note.$2 / 1000).round();
    }

    final pcmData = ByteData(totalSamples * 2);
    int sampleOffset = 0;

    for (final note in notes) {
      final int noteSamples = (sampleRate * note.$2 / 1000).round();

      for (int i = 0; i < noteSamples; i++) {
        final double time = i / sampleRate;
        // Use softer wave with harmonics
        double value = math.sin(2 * math.pi * note.$1 * time);
        value += 0.3 * math.sin(4 * math.pi * note.$1 * time); // 2nd harmonic
        value += 0.1 * math.sin(6 * math.pi * note.$1 * time); // 3rd harmonic
        value /= 1.4; // Normalize

        final double envelope = _calculateSoftEnvelope(i, noteSamples);
        final int sample = (value * envelope * 32767 * 0.5).round();

        pcmData.setInt16(
            (sampleOffset + i) * 2, sample.clamp(-32768, 32767), Endian.little,);
      }
      sampleOffset += noteSamples;
    }

    return _createWavFile(pcmData, totalSamples, sampleRate);
  }

  /// Generate chord WAV data (multiple frequencies)
  Uint8List _generateChordWavData(
      List<double> frequencies, int numSamples, int sampleRate,
      {bool decay = false,}) {
    final pcmData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double time = i / sampleRate;
      double value = 0;

      for (final freq in frequencies) {
        value += math.sin(2 * math.pi * freq * time);
        value += 0.2 * math.sin(4 * math.pi * freq * time); // Soft harmonic
      }
      value /= frequencies.length; // Normalize

      double envelope = _calculateSoftEnvelope(i, numSamples);
      if (decay) {
        // Add exponential decay for bell-like sound
        envelope *= math.exp(-3.0 * i / numSamples);
      }

      final int sample = (value * envelope * 32767 * 0.5).round();
      pcmData.setInt16(i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return _createWavFile(pcmData, numSamples, sampleRate);
  }

  /// Generate noise WAV data (for whoosh/flip sounds)
  Uint8List _generateNoiseWavData(int numSamples, int sampleRate) {
    final pcmData = ByteData(numSamples * 2);
    final random = math.Random();

    for (int i = 0; i < numSamples; i++) {
      // Filtered noise with envelope
      double noise = (random.nextDouble() * 2 - 1);

      // Apply bandpass filter effect by mixing with sine
      final double time = i / sampleRate;
      noise = noise * 0.3 +
          0.7 * math.sin(2 * math.pi * 2000 * time * (1 - i / numSamples));

      final double envelope = _calculateSoftEnvelope(i, numSamples);
      // Fast attack, gradual decay
      final double attackDecay = i < numSamples * 0.1
          ? i / (numSamples * 0.1)
          : math.exp(-5.0 * (i - numSamples * 0.1) / numSamples);

      final int sample =
          (noise * envelope * attackDecay * 32767 * 0.25).round();
      pcmData.setInt16(i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return _createWavFile(pcmData, numSamples, sampleRate);
  }

  /// Generate WAV file data with different wave types
  Uint8List _generateWavData(double frequency, int numSamples, int sampleRate,
      {WaveType waveType = WaveType.sine,}) {
    final pcmData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double time = i / sampleRate;
      double value;

      switch (waveType) {
        case WaveType.sine:
          value = math.sin(2 * math.pi * frequency * time);
          break;
        case WaveType.soft:
          // Soft sine with gentle harmonics (bell-like)
          value = math.sin(2 * math.pi * frequency * time);
          value += 0.2 * math.sin(4 * math.pi * frequency * time);
          value /= 1.2;
          break;
        case WaveType.pop:
          // Short pop sound
          value = math.sin(2 * math.pi * frequency * time);
          value *= math.exp(-10.0 * i / numSamples); // Fast decay
          break;
      }

      final double envelope = _calculateSoftEnvelope(i, numSamples);
      final int sample = (value * envelope * 32767 * 0.5).round();

      pcmData.setInt16(i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return _createWavFile(pcmData, numSamples, sampleRate);
  }

  /// Create WAV file from PCM data
  Uint8List _createWavFile(ByteData pcmData, int numSamples, int sampleRate) {
    final int dataSize = numSamples * 2;
    final int fileSize = 36 + dataSize;

    final header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little);

    // WAVE header
    header.setUint8(8, 0x57); // 'W'
    header.setUint8(9, 0x41); // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);

    // data subchunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);

    final result = Uint8List(44 + dataSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataSize, pcmData.buffer.asUint8List());

    return result;
  }

  /// Softer envelope for pleasant sounds
  double _calculateSoftEnvelope(int sample, int totalSamples) {
    const double attackTime = 0.05; // 5% attack
    const double releaseTime = 0.2; // 20% release

    final int attackSamples = (totalSamples * attackTime).round();
    final int releaseSamples = (totalSamples * releaseTime).round();

    if (sample < attackSamples) {
      // Smooth attack using sine curve
      return math.sin((sample / attackSamples) * math.pi / 2);
    } else if (sample > totalSamples - releaseSamples) {
      // Smooth release using cosine curve
      final double releaseProgress =
          (sample - (totalSamples - releaseSamples)) / releaseSamples;
      return math.cos(releaseProgress * math.pi / 2);
    } else {
      return 1.0;
    }
  }

  /// Clear audio cache
  Future<void> clearCache() async {
    for (final path in _audioCache.values) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _audioCache.clear();
  }

  void dispose() {
    _player?.dispose();
    _player = null;
    clearCache();
  }
}

/// Wave types for different sound characteristics
enum WaveType {
  sine, // Pure tone
  soft, // Soft bell-like
  pop, // Quick pop
}

// Global sound service instance
final soundService = SoundService();
