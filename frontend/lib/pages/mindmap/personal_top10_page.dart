import 'package:flutter/material.dart';
import '../../services/business/mindmap_business.dart';
import 'top10_detail_page.dart';
import '../../models/item.dart';
import '../../services/api/item_api.dart';
import 'dart:convert'; // Added for jsonDecode

class PersonalTop10Page extends StatefulWidget {
  const PersonalTop10Page({super.key});

  @override
  State<PersonalTop10Page> createState() => _PersonalTop10PageState();
}

class _PersonalTop10PageState extends State<PersonalTop10Page> {
  final MindMapBusiness _business = MindMapBusiness();
  final ItemApi _itemApi = ItemApi();
  List<Item> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fetchedItems = await _business.fetchPersonalTop10();
    
    // 确保所有获取的事项都按照其在列表中的位置设置正确的 displayOrder
    for (int i = 0; i < fetchedItems.length; i++) {
      // 由于 API 返回的 display_order 已经是从 1 开始的，这里我们不需要额外修改
      // fetchedItems[i] = fetchedItems[i].copyWith(displayOrder: i + 1); // 假设 Item 有 copyWith 方法
    }

    // 补齐到10个空事项
    final List<Item> items = List.from(fetchedItems);
    while (items.length < 10) {
      items.add(Item(itemId: 0, displayOrder: items.length + 1, title: '', content: ''));
    }

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

    // 重新分配 displayOrder 并只提交非空事项的顺序
    final List<int> displayOrders = [];
    final List<Item> newOrderItems = [];
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].itemId != 0) {
        newOrderItems.add(_items[i].copyWith(displayOrder: newOrderItems.length + 1)); // 假设 Item 有 copyWith 方法
        displayOrders.add(newOrderItems.last.itemId);
      } else {
        newOrderItems.add(_items[i].copyWith(displayOrder: i + 1)); // 空事项也更新 displayOrder
      }
    }
    
    // 更新 _items 列表以反映新的 displayOrder
    setState(() {
      _items = newOrderItems;
    });

    if (displayOrders.isNotEmpty) {
      await _itemApi.adjustItemOrder(displayOrders);
    }
  }

  Future<void> _openDetail(int index) async {
    final current = _items[index];
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => Top10DetailPage(
            index: index + 1, item: current.toJson(), readOnly: false),
      ),
    );

    if (result != null) {
      final String newTitle = result['title']?.trim() ?? '';
      final String newContent = result['content']?.trim() ?? '';

      if (current.itemId == 0) { // 如果是空事项
        if (newTitle.isNotEmpty || newContent.isNotEmpty) { // 如果有内容，则视为新建
          final newItemData = {
            'title': newTitle,
            'content': newContent,
          };
          final response = await _itemApi.addItem(newItemData);
          if (response.statusCode == 200) {
            final responseBody = jsonDecode(response.body);
            if (responseBody['code'] == 200 && responseBody['data'] != null) {
              final createdItem = Item.fromJson(responseBody['data']);
              setState(() {
                _items[index] = createdItem;
              });
            }
          }
        } // 否则空事项未被编辑，不进行任何操作
      } else { // 如果是真实事项
        if (newTitle.isEmpty && newContent.isEmpty) { // 如果被清空，则视为删除
          await _itemApi.deleteItem(current.itemId.toString());
          setState(() {
            _items[index] = Item(
                itemId: 0,
                displayOrder: current.displayOrder,
                title: '',
                content: '');
          });
        } else if (newTitle != current.title || newContent != current.content) { // 如果有改动，则视为更新
          final updatedItemData = {
            'title': newTitle,
            'content': newContent,
          };
          await _itemApi.updateItem(current.itemId.toString(), updatedItemData);
          setState(() {
            _items[index] = current.copyWith(title: newTitle, content: newContent);
          });
        }
      }
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
              // 重新分配 displayOrder 并只提交非空事项的顺序
              final List<int> displayOrders = [];
              final List<Item> currentItems = List.from(_items);
              final List<Item> newOrderItems = [];
              for (int i = 0; i < currentItems.length; i++) {
                if (currentItems[i].itemId != 0) {
                  newOrderItems.add(currentItems[i].copyWith(displayOrder: newOrderItems.length + 1));
                  displayOrders.add(newOrderItems.last.itemId);
                } else {
                  newOrderItems.add(currentItems[i].copyWith(displayOrder: i + 1));
                }
              }

              setState(() {
                _items = newOrderItems;
              });

              if (displayOrders.isNotEmpty) {
                await _itemApi.adjustItemOrder(displayOrders);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已保存顺序')));
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('没有可保存的顺序')));
              }
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
                  key: ValueKey('${item.itemId}_${index}'),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(item.title),
                    subtitle: Text(
                      item.content,
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
