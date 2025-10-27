class Item {
  final int itemId;
  final int displayOrder;
  final String title;
  final String content;

  Item({
    required this.itemId,
    required this.displayOrder,
    required this.title,
    required this.content,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'] as int,
      displayOrder: json['displayOrder'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  Item copyWith({
    int? itemId,
    int? displayOrder,
    String? title,
    String? content,
  }) {
    return Item(
      itemId: itemId ?? this.itemId,
      displayOrder: displayOrder ?? this.displayOrder,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'display_order': displayOrder,
      'title': title,
      'content': content,
    };
  }
}

class ItemListResponse {
  final List<Item> items;

  ItemListResponse({required this.items});

  factory ItemListResponse.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'] as List<dynamic>;
    final items = itemsData.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
    return ItemListResponse(items: items);
  }
}
