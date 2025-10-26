import 'package:nullworking/services/business/log_business.dart';
import 'package:nullworking/services/business/task_business.dart';
import 'package:nullworking/models/log.dart';
import 'package:nullworking/models/task.dart';

class MindMapBusiness {
  final LogBusiness _logBusiness = LogBusiness();
  final TaskBusiness _taskBusiness = TaskBusiness();

  // 新增：获取当天数据（日志+未完成任务）
  Future<Map<String, dynamic>> fetchTodayData() async {
    try {
      // 并行请求当天日志和任务
      final logsFuture = _logBusiness.getTodayLogs(); // 调用日志业务层的当天日志方法
      final tasksFuture = _taskBusiness.getTodayUnfinishedTasks(); // 调用任务业务层的当天任务方法

      final List<Log> todayLogs = await logsFuture;
      final List<Task> todayTasks = await tasksFuture;

      return {
        'todayLogs': todayLogs,
        'todayTasks': todayTasks,
        'companyImportant': '公司重要事项数据（示例）', // 保留原有其他卡片的模拟数据
        'personalImportant': '个人重要事项数据（示例）',
      };
    } catch (e) {
      return {
        'error': '加载失败：$e',
      };
    }
  }
}