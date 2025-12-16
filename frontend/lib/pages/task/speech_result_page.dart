import 'package:flutter/material.dart';
import 'package:xfvoice2/xfvoice2.dart';

class SpeechResultPage extends StatefulWidget {
  const SpeechResultPage({super.key});

  @override
  State<SpeechResultPage> createState() => _SpeechResultPageState();
}

class _SpeechResultPageState extends State<SpeechResultPage> {
  String _recognizedText = '点击按钮开始语音识别';
  final XFVoice _xfVoice = XFVoice.shared;

  @override
  void initState() {
    super.initState();
    _initSpeechRecognizer();
  }

  void _initSpeechRecognizer() {
    // 请替换成你的appid，这里使用示例appid
    _xfVoice.init(appIdIos: '6a5ecb24', appIdAndroid: '6a5ecb24'); 
    final param = XFVoiceParam();
    param.domain = 'iat';
    param.result_type = 'json';
    final map = param.toMap();
    map['dwa'] = 'wpgs';
    _xfVoice.setParameter(map);
  }

  void _startListening() {
    setState(() {
      _recognizedText = '正在聆听...';
    });
    _xfVoice.start(
      listener: XFVoiceListener(
        onVolumeChanged: (volume) {
          print('音量：$volume');
        },
        onResults: (String result, isLast) {
          setState(() {
            _recognizedText = result;
          });
        },
        onCompleted: (Map<dynamic, dynamic> errInfo, String filePath) {
          if (errInfo['errorCode'] == 0) {
            print('识别完成');
          } else {
            print('识别错误: ${errInfo['errorCode']}');
            setState(() {
              _recognizedText = '识别错误: ${errInfo['errorCode']}';
            });
          }
        },
      ),
    );
  }

  void _stopListening() {
    _xfVoice.stop();
    setState(() {
      _recognizedText = '识别停止';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音识别'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _recognizedText,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _startListening,
              child: const Text('开始语音识别'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopListening,
              child: const Text('停止语音识别'),
            ),
          ],
        ),
      ),
    );
  }
}