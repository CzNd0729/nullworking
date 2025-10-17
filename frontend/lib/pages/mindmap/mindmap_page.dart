import 'package:flutter/material.dart';
import 'package:nullworking/services/api/user_api.dart';

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  // 为四个分框分别定义数据状态，等待API返回
  String _companyImportant = '加载中...';
  String _companyTask = '加载中...';
  String _personalImportant = '加载中...';
  String _personalLog = '加载中...';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // 这里可以根据实际API情况分别请求四个分框的数据
  Future<void> _fetchData() async {
    try {
      // 示例：调用健康状态API，实际应替换为各分框对应的API
      final response = await UserApi().getHealth();
      
      if (response.statusCode == 200) {
        setState(() {
          // 临时用同一数据填充，实际应根据API返回分别赋值
          _companyImportant = "公司重要事项数据";
          _companyTask = "公司任务调度数据";
          _personalImportant = "个人重要事项数据";
          _personalLog = "个人日志数据";
        });
      } else {
        setState(() {
          _companyImportant = '请求失败: ${response.statusCode}';
          _companyTask = '请求失败: ${response.statusCode}';
          _personalImportant = '请求失败: ${response.statusCode}';
          _personalLog = '请求失败: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _companyImportant = '发生错误: $e';
        _companyTask = '发生错误: $e';
        _personalImportant = '发生错误: $e';
        _personalLog = '发生错误: $e';
      });
    }
  }

  // 分框卡片组件
  Widget _buildCard(String title, String content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  // 移除了这里的const关键字，因为使用了Colors.grey[700]
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
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
        title: const Text('导图'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 顶端导图名称
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                '项目导图',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // 四个分框网格布局
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9, // 调整卡片宽高比
                children: [
                  _buildCard('公司重要事项', _companyImportant),
                  _buildCard('公司任务调度', _companyTask),
                  _buildCard('个人重要事项', _personalImportant),
                  _buildCard('个人日志', _personalLog),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
    