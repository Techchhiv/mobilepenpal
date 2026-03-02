import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

class OnnxInferenceService {
  OnnxInferenceService._();
  static final OnnxInferenceService instance = OnnxInferenceService._();

  bool _envInitialized = false;

  /// Model type → asset path mapping.
  static const Map<String, String> _modelAssets = {
    'digit': 'assets/models/best_digit.onnx',
    'math': 'assets/models/best_math.onnx',
    'consonant': 'assets/models/best_consonant.onnx',
    'independent_vowel': 'assets/models/best_independent_vowel.onnx',
    'dependent_vowel': 'assets/models/best_dependent_vowel.onnx',
  };

  /// Cached sessions keyed by model type.
  final Map<String, OrtSession> _sessions = {};

  // ──────────────────────────────────────────────
  //  LABEL MAPS (mirrored from Python)
  // ──────────────────────────────────────────────

  static const List<String> _khmerDigits = [
    '០',
    '១',
    '២',
    '៣',
    '៤',
    '៥',
    '៦',
    '៧',
    '៨',
    '៩',
  ];

  static const Map<int, String> _mathLabelMap = {
    0: ',',
    1: '-',
    2: '០',
    3: '១',
    4: '២',
    5: '៣',
    6: '៤',
    7: '៥',
    8: '៦',
    9: '៧',
    10: '៨',
    11: '៩',
  };

  static final List<String> _consonantChars = (List<String>.from([
    'ក',
    'ខ',
    'គ',
    'ឃ',
    'ង',
    'ច',
    'ឆ',
    'ជ',
    'ឈ',
    'ញ',
    'ដ',
    'ឋ',
    'ឌ',
    'ឍ',
    'ណ',
    'ត',
    'ថ',
    'ទ',
    'ធ',
    'ន',
    'ប',
    'ផ',
    'ព',
    'ភ',
    'ម',
    'យ',
    'រ',
    'ល',
    'វ',
    'ស',
    'ហ',
    'ឡ',
    'អ',
  ]))..sort();

  static final List<String> _independentVowelChars = (List<String>.from([
    'ឥ',
    'ឦ',
    'ឧ',
    'ឩ',
    'ឪ',
    'ឫ',
    'ឬ',
    'ឭ',
    'ឮ',
    'ឯ',
    'ឰ',
    'ឱ',
    'ឳ',
  ]))..sort();

  static final List<String> _dependentVowelChars = (List<String>.from([
    'ា',
    'ិ',
    'ី',
    'ឹ',
    'ឺ',
    'ុ',
    'ូ',
    'ួ',
    'ើ',
    'ឿ',
    'ៀ',
    'េ',
    'ែ',
    'ៃ',
    'ោ',
    'ៅ',
    'ុំ',
    'ំ',
    'ាំ',
    'ះ',
    'ិះ',
    'ុះ',
    'េះ',
    'ោះ',
  ]))..sort();

  void init() {
    if (!_envInitialized) {
      OrtEnv.instance.init();
      _envInitialized = true;
    }
  }

  void dispose() {
    for (final session in _sessions.values) {
      session.release();
    }
    _sessions.clear();
    if (_envInitialized) {
      OrtEnv.instance.release();
      _envInitialized = false;
    }
  }

  Future<OrtSession> _getSession(String modelType) async {
    if (_sessions.containsKey(modelType)) return _sessions[modelType]!;

    final assetPath = _modelAssets[modelType];
    if (assetPath == null) {
      throw Exception('Unknown model type: $modelType');
    }

    final rawAsset = await rootBundle.load(assetPath);
    final bytes = rawAsset.buffer.asUint8List();
    final options = OrtSessionOptions();
    final session = OrtSession.fromBuffer(bytes, options);
    _sessions[modelType] = session;
    dev.log('Loaded ONNX session for $modelType', name: 'OnnxInference');
    return session;
  }

  Future<Map<String, dynamic>> predict(
    String modelType,
    List<List<double>> inputData,
    List<int> shape,
  ) async {
    final session = await _getSession(modelType);

    final flat = <double>[];
    for (final row in inputData) {
      flat.addAll(row);
    }

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(flat),
      shape,
    );
    final inputs = {'input': inputTensor};
    final runOptions = OrtRunOptions();

    try {
      final outputs = await session.runAsync(runOptions, inputs);

      if (outputs == null || outputs.isEmpty) {
        throw Exception('Model returned no output');
      }

      int targetOutputIndex = 0;
      if (session.outputNames.length > 1) {
        final idx = session.outputNames.indexOf('label_output');
        if (idx != -1) {
          targetOutputIndex = idx;
        } else {
          final outIdx = session.outputNames.indexOf('output');
          if (outIdx != -1) targetOutputIndex = outIdx;
        }
      }

      final labelOutput = outputs[targetOutputIndex];
      if (labelOutput == null) {
        throw Exception(
          'Model returned null output at index $targetOutputIndex',
        );
      }

      final labelData = labelOutput.value;
      final logits = _extractLogits(labelData);

      int predIndex = 0;
      double maxVal = logits[0];
      for (int i = 1; i < logits.length; i++) {
        if (logits[i] > maxVal) {
          maxVal = logits[i];
          predIndex = i;
        }
      }

      dev.log(
        '$modelType → index=$predIndex confidence=${maxVal.toStringAsFixed(3)} '
        'logits_len=${logits.length}',
        name: 'OnnxInference',
      );

      final prediction = _indexToLabel(modelType, predIndex);
      return {'prediction': prediction, 'index': predIndex};
    } finally {
      inputTensor.release();
      runOptions.release();
    }
  }

  List<double> _extractLogits(dynamic data) {
    if (data is List && data.isNotEmpty && data[0] is List) {
      final inner = data[0] as List;
      return inner.map((e) => (e as num).toDouble()).toList();
    }
    if (data is List) {
      return data.map((e) => (e as num).toDouble()).toList();
    }
    throw Exception('Unexpected ORT output type: ${data.runtimeType}');
  }

  // ──────────────────────────────────────────────
  //  LABEL DECODING
  // ──────────────────────────────────────────────

  String _indexToLabel(String modelType, int index) {
    switch (modelType) {
      case 'digit':
        return (index >= 0 && index < _khmerDigits.length)
            ? _khmerDigits[index]
            : '?';
      case 'math':
        return _mathLabelMap[index] ?? '?';
      case 'consonant':
        return (index >= 0 && index < _consonantChars.length)
            ? _consonantChars[index]
            : '?';
      case 'independent_vowel':
        return (index >= 0 && index < _independentVowelChars.length)
            ? _independentVowelChars[index]
            : '?';
      case 'dependent_vowel':
        return (index >= 0 && index < _dependentVowelChars.length)
            ? _dependentVowelChars[index]
            : '?';
      default:
        return '?';
    }
  }
}
