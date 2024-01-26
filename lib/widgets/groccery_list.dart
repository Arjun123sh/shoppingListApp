import 'package:flutter/material.dart';
import 'package:shoppinglist/data/categories.dart';
import 'package:shoppinglist/models/groccery_item.dart';
import 'package:shoppinglist/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});
  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _grocceryItems = [];
  var isLoadig = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-f905f-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Could not load items. Please try again later!';
      });
    }

    if (response.body == 'null') {
      setState(() {
        isLoadig = false;
      });
      return;
    }

    final Map<String, dynamic> listdata = json.decode(response.body);
    final List<GroceryItem> _loadedItems = [];
    for (final item in listdata.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      _loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          category: category,
          quantity: item.value['quantity'],
        ),
      );
    }
    setState(() {
      _grocceryItems = _loadedItems;
      isLoadig = true;
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
      _grocceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    setState(() {
      _grocceryItems.remove(item);
    });

    final url = Uri.https('flutter-prep-f905f-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _grocceryItems.insert(_grocceryItems.indexOf(item), item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No Items Added'),
    );
    if (isLoadig) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_grocceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _grocceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_grocceryItems[index]);
          },
          key: ValueKey(_grocceryItems[index].id),
          child: ListTile(
            title: Text(_grocceryItems[index].name),
            leading: Container(
              height: 24,
              width: 24,
              color: _grocceryItems[index].category.color,
            ),
            trailing: Text(_grocceryItems[index].quantity.toString()),
          ),
        ),
      );
    }
    if (_error != null) {
      content = Center(child: Text(_error!));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
