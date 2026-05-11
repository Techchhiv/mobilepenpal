import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:mobilepenpal/core/utils/stroke_preprocessor.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

class DrawingEvaluationService {
  DrawingEvaluationService({WorldService? worldService})
    : _worldService = worldService ?? WorldService();

  final WorldService _worldService;

  String mapCharacterTypeToModelType(String? characterType) {
    final t = (characterType ?? '').trim().toLowerCase();
    switch (t) {
      case 'digits':
        return 'digit';
      case 'consonants':
        return 'consonant';
      case 'independent_vowels':
        return 'independent_vowel';
      case 'dependent_vowels':
        return 'dependent_vowel';
      case 'math':
        return 'math';
      default:
        return 'consonant';
    }
  }

  Future<Map<String, dynamic>?> predictLocal(
    String modelType,
    List<List<Map<String, dynamic>>> rawStrokes,
  ) async {
    try {
      final result = StrokePreprocessor.preprocessForModel(
        modelType,
        rawStrokes,
      );

      if (modelType == 'math' && !result.isSingleSegment) {
        String combined = '';
        for (int i = 0; i < result.segments.length; i++) {
          final data = await OnnxInferenceService.instance.predict(
            modelType,
            result.segments[i],
            result.shapes[i],
          );
          combined += (data['prediction'] ?? '').toString().trim();
        }
        return {'prediction': combined, 'segments': result.segments.length};
      } else {
        return await OnnxInferenceService.instance.predict(
          modelType,
          result.segments[0],
          result.shapes[0],
        );
      }
    } catch (e) {
      dev.log(
        'Local ONNX inference failed for $modelType: $e',
        name: 'DrawingEvaluationService',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> predictRemote({
    required List<Map<String, dynamic>> strokes,
    required String modelType,
    CancelToken? cancelToken,
  }) {
    return _worldService.predictDrawingVector(
      strokes: strokes,
      modelType: modelType,
      cancelToken: cancelToken,
    );
  }

  Future<Map<String, dynamic>?> predictBoard({
    required String modelType,
    required List<List<Map<String, dynamic>>> rawStrokes,
    required Map<String, dynamic> Function() getPayload,
    CancelToken? cancelToken,
  }) async {
    Map<String, dynamic>? data = await predictLocal(modelType, rawStrokes);

    if (data == null) {
      final payload = getPayload();
      final strokes = (payload['strokes'] as List).cast<Map<String, dynamic>>();
      data = await predictRemote(
        strokes: strokes,
        modelType: payload['model_type'] as String,
        cancelToken: cancelToken,
      );
    }

    return data;
  }

  Future<String> predictMultiBoard({
    required String modelType,
    required int boardCount,
    required List<List<List<Map<String, dynamic>>>> rawStrokesPerBoard,
    required Map<String, dynamic> Function(int boardIndex) getPayload,
    required int Function() getReqId,
    required int currentReqId,
    CancelToken? cancelToken,
  }) async {
    String combinedPred = '';

    for (int i = 0; i < boardCount; i++) {
      if (rawStrokesPerBoard[i].isEmpty) continue;

      final data = await predictBoard(
        modelType: modelType,
        rawStrokes: rawStrokesPerBoard[i],
        getPayload: () => getPayload(i),
        cancelToken: cancelToken,
      );

      // Check if the request was superseded.
      if (getReqId() != currentReqId) return '';

      combinedPred += (data?['prediction'] ?? '').toString().trim();
    }

    return combinedPred;
  }
}
