class Log {
  final String logId;
  final int? taskId;
  final String logTitle;
  final String logContent;
  final int logStatus;
  final int? taskProgress;
  final String startTime;
  final String endTime;
  final DateTime logDate;
  final List<int>? fileIds;

  Log({
    required this.logId,
    this.taskId,
    required this.logTitle,
    required this.logContent,
    required this.logStatus,
    this.taskProgress,
    required this.startTime,
    required this.endTime,
    required this.logDate,
    this.fileIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'logId': logId, // logId在更新时需要，创建时后端生成
      'taskId': taskId,
      'logTitle': logTitle,
      'logContent': logContent,
      'logStatus': logStatus,
      'taskProgress': taskProgress,
      'startTime': startTime,
      'endTime': endTime,
      'logDate': '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}',
      'fileIds': fileIds ?? [],
    };
  }

  factory Log.fromJson(Map<String, dynamic> json) {
    String? taskProgressStr = json['taskProgress']?.toString();
    int? parsedTaskProgress;
    if (taskProgressStr != null) {
      if (taskProgressStr.endsWith('%')) {
        taskProgressStr = taskProgressStr.substring(0, taskProgressStr.length - 1);
      }
      parsedTaskProgress = int.tryParse(taskProgressStr);
    }

    return Log(
      logId: json['logId']?.toString() ?? (json['id']?.toString() ?? ''),
      taskId: json['taskId'] != null
          ? int.tryParse(json['taskId'].toString())
          : null,
      logTitle: json['logTitle']?.toString() ?? '',
      logContent: json['logContent']?.toString() ?? '',
      logStatus: int.tryParse(json['logStatus']?.toString() ?? '') ?? 0,
      taskProgress: parsedTaskProgress,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      logDate: json['logDate'] != null
          ? (DateTime.tryParse(json['logDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      fileIds: json['fileIds'] != null
          ? List<int>.from(
              (json['fileIds'] as List).map((e) => int.parse(e.toString())),
            )
          : null,
    );
  }
}
