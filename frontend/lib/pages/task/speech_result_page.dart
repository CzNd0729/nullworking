import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechResultPage extends StatefulWidget {
  const SpeechResultPage({super.key});

  @override
  State<SpeechResultPage> createState() => _SpeechResultPageState();
}

class _SpeechResultPageState extends State<SpeechResultPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  // double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _listen(); // Start listening automatically when the page loads
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'));
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
            onResult: (val) => setState(() {
                  _text = val.recognizedWords;
                  // if (val.hasConfidenceRating && val.confidence > 0) {
                  //   _confidence = val.confidence;
                  // }
                }));
      } else {
        setState(() {
          _isListening = false;
          _speech.stop();
        });
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          '语音识别结果',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.white,
            ),
            onPressed: _listen,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextFormField(
                controller: TextEditingController(text: _text), // Use a controller to update the text
                readOnly: true,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _text); // 返回识别的文本
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9A3),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '使用此文本',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
