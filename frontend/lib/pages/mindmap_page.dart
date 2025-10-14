import 'package:flutter/material.dart';
import 'package:nullworking/services/api_service.dart';

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  String _apiResult = '加载中...';

  @override
  void initState() {
    super.initState();
    _fetchHealthStatus();
  }

  Future<void> _fetchHealthStatus() async {
    try {
      final response = await ApiService().get('api/health');
      if (response.statusCode == 200) {
        setState(() {
          _apiResult = response.body;
        });
      } else {
        setState(() {
          _apiResult = '请求失败: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _apiResult = '发生错误: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导图'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          _apiResult,
          style: const TextStyle(fontSize: 24, color: Colors.white70),
        ),
      ),
    );
  }
}
