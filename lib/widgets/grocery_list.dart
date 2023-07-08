import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    final url = Uri.https(
      "flutter-learn-shopping-list-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);

    final responseBody = response.body;

    if (responseBody == "null") {
      setState(() {
        _isLoading = false;
      });

      return;
    }

    final Map<String, dynamic> listData = json.decode(responseBody);

    final List<GroceryItem> loadedGroceryItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value["category"])
          .value;

      final groceryItem = GroceryItem(
        id: item.key,
        name: item.value["name"],
        quantity: item.value["quantity"],
        category: category,
      );
      loadedGroceryItems.add(groceryItem);
    }
    setState(() {
      _groceryItems = loadedGroceryItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final itemIdx = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
      "flutter-learn-shopping-list-default-rtdb.firebaseio.com",
      "shopping-list/${item.id}.json",
    );

    var response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(itemIdx, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No Items"),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, idx) => Column(
          children: [
            Dismissible(
              key: ValueKey(_groceryItems[idx].id),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  _removeItem(_groceryItems[idx]);
                }
              },
              child: ListTile(
                title: Text(_groceryItems[idx].name),
                leading: Container(
                  width: 25,
                  height: 25,
                  color: _groceryItems[idx].category.color,
                ),
                trailing: Text(_groceryItems[idx].quantity.toString()),
              ),
            ),
            const Divider(
              color: Color.fromARGB(255, 85, 81, 81),
            )
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: content,
    );
  }
}
