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
      displayOrder: json['display_order'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}

class ItemListResponse {
  final List<Item> events;

  ItemListResponse({required this.events});

  factory ItemListResponse.fromJson(Map<String, dynamic> json) {
    final eventsData = json['events'] as List<dynamic>;
    final events = eventsData.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
    return ItemListResponse(events: events);
  }
}
