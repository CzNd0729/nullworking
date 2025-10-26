import 'package:flutter/material.dart';
import '../../services/business/mindmap_business.dart';
import 'top10_detail_page.dart';

class PersonalTop10Page extends StatefulWidget {
  const PersonalTop10Page({super.key});

  @override
  State<PersonalTop10Page> createState() => _PersonalTop10PageState();
}

class _PersonalTop10PageState extends State<PersonalTop10Page> {
  final MindMapBusiness _business = MindMapBusiness();
  List<Map<String, String>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _business.fetchPersonalTop10();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    // 自动保存顺序到本地
    await _business.savePersonalTop10(_items);
  }

  Future<void> _openDetail(int index) async {
    final current = Map<String, String>.from(_items[index]);
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) =>
            Top10DetailPage(index: index + 1, item: current, readOnly: false),
      ),
    );

    if (result != null) {
      setState(() {
        _items[index] = result;
      });
      await _business.savePersonalTop10(_items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人十大重要事项'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _business.savePersonalTop10(_items);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已保存顺序')));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  key: ValueKey('${item['title']}_${index}'),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(item['title'] ?? ''),
                    subtitle: Text(
                      item['content'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    onTap: () => _openDetail(index),
                  ),
                );
              },
            ),
    );
  }
}
