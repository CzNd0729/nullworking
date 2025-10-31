import 'package:flutter/material.dart';

class Top10DetailPage extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool readOnly;

  const Top10DetailPage({
    super.key,
    required this.index,
    required this.item,
    required this.readOnly,
  });

  @override
  State<Top10DetailPage> createState() => _Top10DetailPageState();
}

class _Top10DetailPageState extends State<Top10DetailPage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item['title'] ?? '');
    _contentCtrl = TextEditingController(text: widget.item['content'] ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    final updated = {
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
    };
    Navigator.of(context).pop(updated);
  }

  void _onDelete() {
    Navigator.of(context).pop({'deleted': true});
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.readOnly;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.index} 号事项'),
        actions: [
          if (!isReadOnly)
            IconButton(icon: const Icon(Icons.save), onPressed: _onSave),
          if (!isReadOnly)
            IconButton(icon: const Icon(Icons.delete), onPressed: _onDelete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // 标题：只读时放大显示；编辑时为输入框，使用浅灰色提示，不显示 label
            if (isReadOnly)
              Text(
                widget.item['title'] ?? '',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 20),
              )
            else
              TextField(
                controller: _titleCtrl,
                readOnly: false,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '输入事项标题',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
              ),

            const SizedBox(height: 12),

            // 内容：只读时为普通文本；编辑时为多行输入，使用浅灰色提示并保持在顶部
            Expanded(
              child: isReadOnly
                  ? SingleChildScrollView(
                      child: Text(
                        widget.item['content'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : TextField(
                      controller: _contentCtrl,
                      decoration: InputDecoration(
                        hintText: '输入事项内容',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 6.0,
                        ),
                      ),
                      readOnly: false,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                    ),
            ),

            if (!isReadOnly) const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
