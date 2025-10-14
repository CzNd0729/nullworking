import 'package:flutter/material.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  // 构建任务卡片组件
  Widget _buildTaskCard(String statusTag, String taskTitle, String assignee, String deadline, String priority) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusTag == '进行中' ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                statusTag,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            // 任务标题
            Text(
              taskTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 分配信息
            Text('分配给: $assignee'),
            const SizedBox(height: 4),
            // 截止日期
            Text('截止日期: $deadline'),
            const SizedBox(height: 4),
            // 优先级
            Text(
              '优先级: $priority',
              style: TextStyle(color: priority == 'P0' ? Colors.red : (priority == 'P1' ? Colors.orange : Colors.blue)),
            ),
            const SizedBox(height: 8),
            // 查看详情按钮
            ElevatedButton(
              onPressed: () {
                // 后续可添加查看详情的逻辑
              },
              child: const Text('查看详情'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务列表'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 通知铃铛图标
          IconButton(
            onPressed: () {
              // 后续可添加通知逻辑
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索栏
            TextField(
              decoration: InputDecoration(
                hintText: '按标题或任务内容搜索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 派发任务模块
            ExpansionTile(
              title: const Text(
                '派发任务',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                _buildTaskCard('进行中', '设计用户界面', '李四', '2024-07-30', 'P0'),
                _buildTaskCard('已完成', '数据库Schema设计', '王五', '2024-07-25', 'P1'),
              ],
            ),
            const SizedBox(height: 16),
            // 我的任务模块
            ExpansionTile(
              title: const Text(
                '我的任务',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                _buildTaskCard('进行中', '准备会议材料', 'THEp(我)', '2024-07-25', 'P2'),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 后续可添加添加新任务的逻辑
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}