import '../api/task_api.dart';
import '../api/user_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/task.dart';
import 'package:http/http.dart' as http;

class TaskBusiness {
  final TaskApi _taskApi = TaskApi();
  final UserApi _userApi = UserApi();
  Future<List<Task>> getTodayUnfinishedTasks() async {
    try {
      final userTasks = await loadUserTasks();
      if (userTasks != null) {
        final allTasks = <Task>[];
        allTasks.addAll(userTasks['participatedTasks'] ?? []);

        final todayUnfinishedTasks = allTasks.where((task) {
          return task.taskStatus == "0";
        }).toList();
        // Sort tasks by deadline from nearest to furthest
        todayUnfinishedTasks.sort((a, b) {
          return a.deadline.compareTo(b.deadline);
        });
        return todayUnfinishedTasks;
      }
      return <Task>[];
    } catch (e) {
      print('获取当天未完成任务异常: $e');
      return <Task>[];
    }
  }

  Future<Map<String, List<Task>>?> loadUserTasks() async {
    try {
      final response = await _taskApi.listUserTasks();
      if (response != null) {
        return {
          'createdTasks': response.createdTasks,
          'participatedTasks': response.participatedTasks,
        };
      }
    } catch (e) {
      print('加载任务失败: $e');
    }
    return null;
  }

  List<Task> filterTasks(List<Task> tasks, String searchQuery, Set<String> selectedStatusFilters) {
    return tasks.where((task) {
      final matchesSearch =
          searchQuery.isEmpty ||
          task.taskTitle.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.taskContent.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus =
          selectedStatusFilters.isEmpty ||
          selectedStatusFilters.contains(task.taskStatus);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<Task?> publishTask({
    required String title,
    required String content,
    required int priority,
    required List<String> executorIds,
    required DateTime deadline,
    String? taskId,
  }) async {
    try {
      final taskData = {
        'title': title,
        'content': content,
        'priority': priority,
        'executorIds': executorIds,
        'deadline': deadline.toIso8601String(),
      };

      http.Response response;
      if (taskId != null) {
        taskData['taskId'] = taskId;
        response = await _taskApi.updateTask(taskData);
      } else {
        response = await _taskApi.publishTask(taskData);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 200 && responseBody['data'] != null) {
          final String? finalTaskId = taskId ?? responseBody['data']['taskId']?.toString();
          if (finalTaskId == null) {
            print('任务Id缺失');
            return null;
          }
          final prefs = await SharedPreferences.getInstance();
          final currentUserName = prefs.getString("userName") ?? "我";
          return Task(
            taskId: finalTaskId,
            creatorName: currentUserName,
            taskTitle: title,
            taskContent: content,
            taskPriority: priority.toString(),
            taskStatus: "0",
            creationTime: DateTime.now(),
            deadline: deadline,
            executorNames: _mapUserIdsToNames(executorIds),
            isParticipated: false, // 新发布的任务，isParticipated 设为 false
          );
        } else {
          print('任务发布/更新失败: ${responseBody['message'] ?? '未知错误'}');
        }
      } else {
        print('任务发布/更新失败: ${response.statusCode}');
      }
    } catch (e) {
      print('发布/更新任务时出错: $e');
    }
    return null;
  }

  List<String> _mapUserIdsToNames(List<String> userIds) {
    if (userIds.contains(getCurrentUserId())) {
      return ["我"];
    }
    return userIds.map((id) => "用户_$id").toList();
  }

  Future<List<Map<String, dynamic>>> fetchTeamMembers() async {
    try {
      final response = await _userApi.getSubDeptUser();
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 200 && responseBody['data'] != null) {
          return (responseBody['data']['users'] as List)
              .map(
                (user) => {
                  'name': user['realName'] ?? '未知用户',
                  'role': user['role'] ?? '',
                  'userId': user['userId'].toString(),
                },
              )
              .toList();
        }
      } else {
        print('获取团队成员失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取团队成员时出错: $e');
    }
    return [];
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userName");
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await _taskApi.deleteTask(taskId);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody['code'] == 200;
      } else {
        print('任务删除失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('删除任务时出错: $e');
      return false;
    }
  }
}
