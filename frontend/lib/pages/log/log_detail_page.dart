import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/log.dart';
import '../../services/business/log_business.dart'; // 导入LogBusiness
import 'create_log_page.dart'; // 导入CreateLogPage

class LogDetailPage extends StatefulWidget {
  final String logId;

  const LogDetailPage({super.key, required this.logId});

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  final LogBusiness _logBusiness = LogBusiness();
  Log? _logDetails;
  List<Map<String, dynamic>> _logFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogData();
  }

  Future<void> _fetchLogData() async {
    try {
      setState(() => _isLoading = true);
      final log = await _logBusiness.fetchLogDetails(widget.logId);
      if (log != null) {
        setState(() {
          _logDetails = log;
        });

        if (log.fileIds != null && log.fileIds!.isNotEmpty) {
          final files = await _logBusiness.fetchLogFiles(log.fileIds!);
          setState(() {
            _logFiles = files;
          });
        }
      } else {
        // Handle case where log is not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日志详情加载失败！')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('加载日志详情异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载日志详情失败: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2CB7B3)),
        ),
      );
    }

    if (_logDetails == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('未能加载日志详情', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final log = _logDetails!;
    String statusText;
    Color statusColor;
    switch (log.logStatus) {
      case 0:
        statusText = '未完成';
        statusColor = Colors.blueAccent;
        break;
      case 1:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
      default:
        statusText = '未知';
        statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('日志详情'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editLog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDeleteLog(context),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.logTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    log.logContent,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日志概览',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    '日期',
                    DateFormat('yyyy年MM月dd日').format(log.logDate),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    '开始时间',
                    log.startTime,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    '结束时间',
                    log.endTime,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.data_usage,
                    '进度',
                    '${log.taskProgress ?? 0}%',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.info_outline,
                    '状态',
                    statusText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 文件附件区域
            if (_logFiles.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '附件',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._logFiles.map((file) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            file['fileName'] ?? '未知文件', // 假设文件详情包含文件名
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLog(BuildContext context) async {
    final updatedLog = await Navigator.push<Log?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLogPage(logToEdit: _logDetails),
      ),
    );

    if (updatedLog != null) {
      // 如果日志被更新，则重新加载日志详情
      _fetchLogData();
    }
  }

  Future<void> _confirmDeleteLog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('确认删除', style: TextStyle(color: Colors.white)),
          content: const Text('您确定要删除此日志吗？', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消', style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteLog();
    }
  }

  Future<void> _deleteLog() async {
    final Map<String, dynamic> result = await _logBusiness.deleteLog(_logDetails!.logId);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日志删除成功！'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // 返回并告知前一个页面已删除
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('日志删除失败: ${result['message']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
