class AiAnalysisResult {
  String resultId;
  Map<String, dynamic> prompt;
  DateTime analysisTime;
  int status; // 0 for processing, 1 for completed, 2 for failed
  int mode; // 0 for default, other values for specific analysis modes
  Map<String, dynamic> content; // 新增字段，用于存储分析结果的原始数据

  AiAnalysisResult({
    required this.resultId,
    required this.prompt,
    required this.analysisTime,
    required this.status,
    required this.mode,
    required this.content, // 新增 data 字段
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      resultId: json['resultId']?.toString() ?? '',
      prompt: Map<String, dynamic>.from(json['prompt'] ?? {}),
      analysisTime: json['analysisTime'] != null
          ? DateTime.parse(json['analysisTime'].toString())
          : DateTime.now(),
      status: int.parse(json['status']?.toString() ?? '0'),
      mode: int.parse(json['mode']?.toString() ?? '0'),
      content: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'resultId': resultId,
        'prompt': prompt,
        'status': status,
        'analysisTime': analysisTime.toIso8601String(),
        'data': content, // 将 data 字段包含在 toJson 中
      };
}
