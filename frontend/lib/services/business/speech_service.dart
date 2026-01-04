import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xfvoice2/xfvoice2.dart';

class SpeechService {
  final XFVoice _xfVoice = XFVoice.shared;
  bool _isListening = false;
  String _recognizedText = '';

  // 核心缓存：用于存储每个 sn 包对应的文本
  final Map<int, String> _resultCache = {};

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Function(String)? onResult;
  Function(bool)? onListeningStatusChanged;

  SpeechService({
    this.onResult,
    this.onListeningStatusChanged
  });

  void initialize({required String appIdIos, required String appIdAndroid}) {
    _xfVoice.init(appIdIos: appIdIos, appIdAndroid: appIdAndroid);
    final param = XFVoiceParam();
    param.domain = 'iat';
    final map = param.toMap();
    map['dwa'] = 'wpgs';      // 必须开启，否则 pgs 字段无效
    map['vad_eos'] = '1500';
    _xfVoice.setParameter(map);
  }

  void startListening() {
    if (_isListening) return;

    _resultCache.clear();
    _recognizedText = '';
    _isListening = true;
    onListeningStatusChanged?.call(true);

    _xfVoice.start(
      listener: XFVoiceListener(
        onResults: (String result, bool isLast) {
          if (result.isEmpty) return;

          try {
            Map<String, dynamic> jsonResult = json.decode(result);
            int sn = jsonResult['sn'];
            String pgs = jsonResult['pgs'] ?? 'apd';
            // 获取 rg 字段，可能是 List 也可能是 String，视具体返回格式而定，这里做兼容处理
            var rg = jsonResult['rg']; 
            bool ls = jsonResult['ls'] ?? false;

            // 提取当前包的文字
            String currentPacketText = "";
            if (jsonResult['ws'] != null) {
              for (var ws in jsonResult['ws']) {
                for (var cw in ws['cw']) {
                  currentPacketText += cw['w'] ?? "";
                }
              }
            }

            // --- 核心逻辑修改部分 (参考 Java 代码) ---
            
            // 如果 pgs 是 rpl 就在已有的结果中删除掉要覆盖的 sn 部分
            if (pgs == 'rpl' && rg != null) {
              int begin = 0;
              int end = 0;

              // Dart 的 jsonDecode 通常会将 [1,2] 直接解析为 List<dynamic>
              // 但为了保险起见，兼容 Java 代码中处理 String 的逻辑
              if (rg is List) {
                begin = rg[0] as int;
                end = rg[1] as int;
              } else if (rg is String) {
                // 对应 Java: rg.replace("[", "").replace("]", "").split(",")
                String rgStr = rg.replaceAll('[', '').replaceAll(']', '');
                List<String> parts = rgStr.split(',');
                if (parts.length >= 2) {
                  begin = int.parse(parts[0]);
                  end = int.parse(parts[1]);
                }
              }

              // Java: for (int i = begin; i <= end; i++) { mIatResults.remove(i+""); }
              // 执行精准删除逻辑
              for (int i = begin; i <= end; i++) {
                _resultCache.remove(i);
              }
            }

            // Java: mIatResults.put(sn, text);
            // 将当前的 sn 和文本存入缓存 (如果是 rpl，这里就是修正后的新内容)
            _resultCache[sn] = currentPacketText;

            // 拼接所有序号的结果包
            // Java中使用 LinkedHashMap 或者是按 key 遍历，这里我们手动对 key 排序确保顺序
            List<int> keys = _resultCache.keys.toList()..sort();
            StringBuffer resultBuffer = StringBuffer();
            for (var key in keys) {
              resultBuffer.write(_resultCache[key]);
            }

            // 更新 UI
            _recognizedText = resultBuffer.toString();
            onResult?.call(_recognizedText);

            if (isLast || ls) {
              _isListening = false;
              onListeningStatusChanged?.call(false);
            }
          } catch (e) {
            debugPrint("解析识别结果失败: $e");
          }
        },
        onCompleted: (err, path) {
          _isListening = false;
          onListeningStatusChanged?.call(false);
        },
      ),
    );
  }

  void stopListening() {
    _xfVoice.stop();
    _isListening = false;
    onListeningStatusChanged?.call(false);
  }
}