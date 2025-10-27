import 'package:http/http.dart' as http;
import 'dart:convert';
import 'base_api.dart';
import 'package:nullworking/models/item.dart';

class ItemApi {
  final BaseApi _baseApi = BaseApi();

  Future<http.Response> addItem(Map<String, dynamic> itemData) async {
    final body = <String, dynamic>{
      'title': itemData['title'].toString(),
      'content': itemData['content'].toString(),
      'displayOrder': itemData['displayOrder'],
    };
    return await _baseApi.post(
      'api/items',
      body: body,
    );
  }

  Future<http.Response> adjustItemOrder(List<int> displayOrders) async {
    final body = <String, dynamic>{
      'displayOrders': displayOrders,
    };

    return await _baseApi.patch(
      'api/items',
      body: body,
    );
  }

  Future<http.Response> updateItem(String itemId, Map<String, dynamic> itemData) async {
    final body = <String, dynamic>{
      'title': itemData['title'].toString(),
      'content': itemData['content'].toString(),
      'display_order': itemData['display_order'],
    };

    return await _baseApi.put(
      'api/items/$itemId',
      body: body,
    );
  }

  Future<http.Response> deleteItem(String itemId) async {
    return await _baseApi.delete(
      'api/items/$itemId',
    );
  }

  Future<ItemListResponse?> getItems({String isCompany = "0"}) async {
    final response = await _baseApi.get('api/items?isCompany=$isCompany');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['code'] == 200 && body['data'] != null) {
        return ItemListResponse.fromJson(body['data']);
      }
    }
    return null;
  }
}
