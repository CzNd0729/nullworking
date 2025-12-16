import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xfvoice2/xfvoice2.dart';

class SpeechResultPage extends StatefulWidget {
  const SpeechResultPage({super.key});

  @override
  State<SpeechResultPage> createState() => _SpeechResultPageState();
}

class _SpeechResultPageState extends State<SpeechResultPage> {
  late TextEditingController _textEditingController;
  String _recognizedText = '点击按钮开始语音识别';
  bool _isListening = false; // Add this line
  final XFVoice _xfVoice = XFVoice.shared;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: _recognizedText); // Add this line
    _initSpeechRecognizer();
  }

  @override // Add this block
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _initSpeechRecognizer() {
    // 请替换成你的appid，这里使用示例appid
    _xfVoice.init(appIdIos: '6a5ecb24', appIdAndroid: '6a5ecb24'); 
    final param = XFVoiceParam();
    param.domain = 'iat';
    final map = param.toMap();
    map['dwa'] = 'wpgs';
    _xfVoice.setParameter(map);
  }

  void _startListening() {
    setState(() {
      _recognizedText = '正在聆听...';
      _textEditingController.text = _recognizedText; // Update controller text
      _isListening = true; // Set listening state
    });
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
          setState(() {
            if (text == '.' || text == '。') {
              _recognizedText += text; // Append if it's a period
            } else {
              _recognizedText = text; // Otherwise, replace
            }
            _textEditingController.text = _recognizedText; // Update controller text
            _textEditingController.selection = TextSelection.fromPosition( // Move cursor to end
                TextPosition(offset: _textEditingController.text.length));
          });
        },
        onCompleted: (Map<dynamic, dynamic> errInfo, String filePath) {
          setState(() { // Update state when listening completes
            _isListening = false;
            if (errInfo['errorCode'] == 0) {
              print('识别完成');
            } else {
              print('识别错误: ${errInfo['errorCode']}');
              _recognizedText = '识别错误: ${errInfo['errorCode']}';
              _textEditingController.text = _recognizedText;
            }
          });
        },
      ),
    );
  }

  void _stopListening() {
    _xfVoice.stop();
    setState(() {
      _recognizedText = '识别停止';
      _textEditingController.text = _recognizedText; // Update controller text
      _isListening = false; // Set listening state
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
            Card( // Wrap TextField in a Card
              margin: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
              elevation: 4.0, // Add a slight shadow for the card effect
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Inner padding for the text field
                child: TextField(
                  controller: _textEditingController,
                  minLines: 5, // Set minimum lines to make it taller
                  maxLines: null, // Allow multiple lines
                  keyboardType: TextInputType.multiline, // Enable multiline input
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(), // Keep border
                    hintText: '点击麦克风开始语音识别',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            IconButton( // Single microphone button
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none, // Change icon based on listening state
                size: 48,
                color: _isListening ? Colors.red : Colors.blue, // Change color based on listening state
              ),
              onPressed: _isListening ? _stopListening : _startListening, // Toggle start/stop
            ),
          ],
        ),
      ),
    );
  }
}