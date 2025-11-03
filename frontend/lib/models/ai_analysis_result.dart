class AiAnalysisResult {
  String resultId;
  String prompt;
  DateTime analysisTime;
  int status; // 0 for processing, 1 for completed, 2 for failed
  int mode; // 0 for default, other values for specific analysis modes

  AiAnalysisResult({
    required this.resultId,
    required this.prompt,
    required this.analysisTime,
    required this.status,
    required this.mode,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      resultId: json['resultId'].toString(),
      prompt: json['prompt'].toString(),
      analysisTime: DateTime.parse(json['analysisTime']),
      status: int.parse(json['status'].toString()),
      mode: int.parse(json['mode'].toString()),
    );
  }
}
