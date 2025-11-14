import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nullworking/models/ai_analysis_result.dart';
import 'package:nullworking/services/business/ai_analysis_business.dart';
import 'package:nullworking/pages/ai_analysis/ai_analysis_result_page.dart'; // 新增导入
import 'create_analysis_request.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:nullworking/services/api/user_api.dart';
import 'package:nullworking/services/api/task_api.dart';
import 'package:nullworking/pages/notification/notification_list_page.dart'; // 新增导入
import '../../widgets/notification_icon_with_badge.dart'; // 新增导入

class AIAnalysisPage extends StatefulWidget {
  const AIAnalysisPage({super.key});

  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage> {
  final AiAnalysisBusiness _aiAnalysisBusiness = AiAnalysisBusiness();
  List<AiAnalysisResult>? _analysisList;
  bool _isLoading = true;

  final UserApi _userApi = UserApi();
  final TaskApi _taskApi = TaskApi();

  List<String> _people = [];
  Map<String, int> _peopleMap = {}; // name -> userId
  List<Map<String, String>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
    _loadRemoteData();
  }

  Future<void> _loadRemoteData() async {
    // 加载人员（同级及下级部门用户）
    try {
      final userResp = await _userApi.getSubordinateUsers(); // Assuming a method to get sub-department users
      if (userResp.statusCode == 200) {
        final body = jsonDecode(userResp.body);
        if (body['code'] == 200 && body['data'] != null) {
          final users = body['data']['users'] as List<dynamic>?;
          if (users != null) {
            final names = <String>[];
            final map = <String, int>{};
            for (var u in users) {
              final id = u['userId'];
              final name = u['realName']?.toString() ?? '';
              if (name.isNotEmpty) {
                names.add(name);
                if (id != null) {
                  try {
                    map[name] = int.parse(id.toString());
                  } catch (_) {
                    // ignore parse
                  }
                }
              }
            }
            setState(() {
              _people = names;
              _peopleMap = map;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('加载用户失败: $e');
    }

    // 加载任务（当前用户创建与参与的任务）
    try {
      final taskList = await _taskApi.listTasks(); // Assuming a method to list tasks
      if (taskList != null) {
        final combined = <Map<String, String>>[];
        for (var t in taskList.createdTasks) {
          combined.add({'id': t.taskId, 'title': t.taskTitle});
        }
        for (var t in taskList.participatedTasks) {
          if (!combined.any((e) => e['id'] == t.taskId)) {
            combined.add({'id': t.taskId, 'title': t.taskTitle});
          }
        }
        setState(() {
          _tasks = combined;
        });
      }
    } catch (e) {
      debugPrint('加载任务失败: $e');
    }
  }

  Future<void> _loadAnalysisHistory() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _aiAnalysisBusiness.getResultList();
    if (mounted) {
      setState(() {
        _analysisList = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分析日志'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const NotificationIconWithBadge(), // Use the new widget
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 新建分析按钮
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreateAnalysisRequestPage(mode: 'time', params: {}),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.note_add_outlined),
                    ),
                    const SizedBox(width: 16),
                    const Text('新建AI分析', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 历史分析标题
            const Text(
              '历史AI分析',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            // 历史分析列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _analysisList == null || _analysisList!.isEmpty
                      ? const Center(child: Text('没有历史分析记录'))
                      : RefreshIndicator(
                          onRefresh: _loadAnalysisHistory,
                          child: ListView.builder(
                            itemCount: _analysisList!.length,
                            itemBuilder: (context, index) {
                              return _buildAnalysisItem(_analysisList![index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(AiAnalysisResult analysisResult) {
    String statusText;
    Color statusColor;
    switch (analysisResult.status) {
      case 0:
        statusText = '处理中';
        statusColor = Colors.cyan;
        break;
      case 1:
        statusText = '完成';
        statusColor = Colors.blue;
        break;
      case 2:
        statusText = '失败';
        statusColor = Colors.red;
        break;
      default:
        statusText = '未知';
        statusColor = Colors.grey;
    }

    return InkWell(
      onTap: analysisResult.status == 1
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AIAnalysisResultPage(
                    resultId: analysisResult.resultId,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    analysisResult.prompt['userPrompt'] ?? '无提示词',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: null, // 允许无限行
                    softWrap: true, // 允许软换行
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 根据 mode 显示不同的详情
            if (analysisResult.mode == 0) ...[
              // 按时间分析
              Text(
                '时间范围: ${analysisResult.prompt['startDate'] ?? '未知'} 至 ${analysisResult.prompt['endDate'] ?? '未知'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              Text(
                '分析人员: ${(_getUserNamesFromIds(analysisResult.prompt['userIds'] as List<dynamic>?))}',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ] else if (analysisResult.mode == 1) ...[
              // 按任务分析
              Text(
                '分析任务: ${(_getTaskTitleFromId(analysisResult.prompt['taskId']?.toString()))}',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy年MM月dd日 HH:mm')
                      .format(analysisResult.analysisTime),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                // 移除查看详情按钮
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getUserNamesFromIds(List<dynamic>? userIds) {
    if (userIds == null || userIds.isEmpty) return '全部';
    final names = userIds.map((id) {
      final userEntry = _peopleMap.entries.firstWhere(
        (element) => element.value == id,
        orElse: () => MapEntry('未知用户', id),
      );
      return userEntry.key;
    }).toList();
    return names.join(', ');
  }

  String _getTaskTitleFromId(String? taskId) {
    if (taskId == null) return '未知任务';
    final taskEntry = _tasks.firstWhere(
      (element) => element['id'] == taskId,
      orElse: () => {'title': '未知任务'},
    );
    return taskEntry['title'] ?? '未知任务';
  }
}
