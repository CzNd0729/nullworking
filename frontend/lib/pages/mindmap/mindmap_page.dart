import 'package:flutter/material.dart';
import '../../services/business/mindmap_business.dart';

class MindMapPage extends StatefulWidget {
  const MindMapPage({super.key});

  @override
  State<MindMapPage> createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  String _companyImportant = '加载中...';
  String _companyTask = '加载中...';
  String _personalImportant = '加载中...';
  String _personalLog = '加载中...';

  final MindMapBusiness _mindMapBusiness = MindMapBusiness();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _mindMapBusiness.fetchMindMapData();
    setState(() {
      _companyImportant = data['companyImportant']!;
      _companyTask = data['companyTask']!;
      _personalImportant = data['personalImportant']!;
      _personalLog = data['personalLog']!;
    });
  }

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
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
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
    