import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xfvoice2/xfvoice2.dart';

class SpeechService {
  final XFVoice _xfVoice = XFVoice.shared;
  bool _isListening = false;
  String _recognizedText = '';
  String _lastError = '';

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  String get lastError => _lastError;

  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStatusChanged;

  SpeechService({
    this.onResult,
    this.onError,
    this.onListeningStatusChanged,
  });

  void initialize({
    required String appIdIos,
    required String appIdAndroid,
  }) {
    _xfVoice.init(appIdIos: appIdIos, appIdAndroid: appIdAndroid);
    final param = XFVoiceParam();
    param.domain = 'iat';
    final map = param.toMap();
    map['dwa'] = 'wpgs';
    map['vad_eos'] = '5000';
    _xfVoice.setParameter(map);
  }

  void startListening() {
    if (!_isListening) {
      _recognizedText = '正在聆听...';
      _lastError = '';
      _isListening = true;
      onListeningStatusChanged?.call(true);
      onResult?.call(_recognizedText);

      _xfVoice.start(
        listener: XFVoiceListener(
          onVolumeChanged: (volume) {
            // print('音量：$volume');
          },
          onResults: (String result, isLast) {
            String text = '';
            if (result.isNotEmpty) {
              final Map<String, dynamic> jsonResult = json.decode(result);
              if (jsonResult['ws'] != null) {
                for (var wsItem in jsonResult['ws']) {
                  if (wsItem['cw'] != null) {
                    for (var cwItem in wsItem['cw']) {
                      if (cwItem['w'] != null) {
                        text += cwItem['w'];
                      }
                    }
                  }
                }
              }
            }
            if (text == '.' || text == '。') {
              _recognizedText += text; // Append if it's a period
            } else {
              _recognizedText = text; // Otherwise, replace
            }
            onResult?.call(_recognizedText);
            if (isLast) {
              _isListening = false;
              onListeningStatusChanged?.call(false);
            }
          },
          onCompleted: (Map<dynamic, dynamic> errInfo, String filePath) {
            _isListening = false;
            onListeningStatusChanged?.call(false);
            print("="*40);
            if (errInfo['errorCode'] == 0) {
              print('识别完成');
            } else {
              print('识别错误: ${errInfo['errorCode']}');
              _lastError = '识别错误: ${errInfo['errorCode']}';
              onError?.call(_lastError);
              onResult?.call(_lastError);
            }
          },
        ),
      );
    }
  }

  void stopListening() {
    if (_isListening) {
      _xfVoice.stop();
      _recognizedText = '识别停止';
      _isListening = false;
      onListeningStatusChanged?.call(false);
      onResult?.call(_recognizedText);
    }
  }

  void cancelListening() {
    if (_isListening) {
      _xfVoice.cancel();
      _recognizedText = '';
      _isListening = false;
      onListeningStatusChanged?.call(false);
      onResult?.call(_recognizedText);
    }
  }
}
