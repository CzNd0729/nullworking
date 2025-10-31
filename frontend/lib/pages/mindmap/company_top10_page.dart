import 'package:flutter/material.dart';
import '../../services/business/mindmap_business.dart';
import 'top10_detail_page.dart';
import '../../models/item.dart';

class CompanyTop10Page extends StatefulWidget {
  const CompanyTop10Page({super.key});

  @override
  State<CompanyTop10Page> createState() => _CompanyTop10PageState();
}

class _CompanyTop10PageState extends State<CompanyTop10Page> {
  final MindMapBusiness _business = MindMapBusiness();
  List<Item> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _business.fetchCompanyTop10();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('公司十大重要事项')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(item.title ?? ''),
                    subtitle: Text(
                      item.content ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Top10DetailPage(
                            index: index + 1,
                            item: item.toJson(),
                            readOnly: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
