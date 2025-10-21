class Log {
  final String logId;
  final int? taskId;
  final String logTitle;
  final String logContent;
  final int logStatus; // 0/1/2 etc
  final int taskProgress; // 0-100
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final DateTime logDate;
  final List<int> fileIds;

  Log({
    required this.logId,
    this.taskId,
    required this.logTitle,
    required this.logContent,
    required this.logStatus,
    required this.taskProgress,
    required this.startTime,
    required this.endTime,
    required this.logDate,
    required this.fileIds,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      logId: json['logId']?.toString() ?? (json['id']?.toString() ?? ''),
      taskId: json['taskId'] != null
          ? int.tryParse(json['taskId'].toString())
          : null,
      logTitle: json['logTitle']?.toString() ?? '',
      logContent: json['logContent']?.toString() ?? '',
      logStatus: int.tryParse(json['logStatus']?.toString() ?? '') ?? 0,
      taskProgress: int.tryParse(json['taskProgress']?.toString() ?? '') ?? 0,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      logDate: json['logDate'] != null
          ? DateTime.parse(json['logDate'].toString())
          : DateTime.now(),
      fileIds: json['fileIds'] != null
          ? List<int>.from(
              (json['fileIds'] as List).map((e) => int.parse(e.toString())),
            )
          : [],
    );
  }
}
