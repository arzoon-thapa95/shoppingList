import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shop_list/data/categories.dart';
import 'package:shop_list/models/grocery_item.dart';
import 'package:shop_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GoceryList extends StatefulWidget {
  const GoceryList({super.key});

  @override
  State<GoceryList> createState() => _GoceryListState();
}

class _GoceryListState extends State<GoceryList> {
  List<GroceryItem> _groceryItems = [];
  // var _isLoading = true;
  String? _error;
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prepone-default-rtdb.firebaseio.com', 'shopping-list.json');

    //try and catch eroor//
    // try {
    final response = await http.get(url);
    print(response.statusCode); //error check 404

    //error Display massage

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery item.Please.');
      // setState(() {
      //   _error = 'Failed to fetch data. Please try again later';
      // });
    }

    // If response body is null then check and return to empty massage diloge box.And null should be String from '' or 'null'
    print(response.body);
    if (response.body == 'null') {
      //  setState(() {
      //     _isLoading = false;
      //  });
      return [];
    }
    final Map<String, dynamic> listData = jsonDecode(response.body);
    print(response.body);
    // input data shown in debug Console which is Decoded from listData.

    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItems;
    // setState(() {
    //   _groceryItems = loadedItems;
    //   _isLoading = false;
    // });
    // } catch (error) {
    //   setState(() {
    //     _error = 'Something went wrong!. Please try again later';
    //   });
    // }
  }

  //short-Way
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
    //getting index of delete items with index variable.
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('flutter-prepone-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget content = const Center(
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Text('No Content to Display'),
    //     ],
    //   ),
    // );

    // if (_isLoading) {
    //   content = const Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }

    // if (_groceryItems.isNotEmpty) {
    //   content = ListView.builder(
    //     itemCount: _groceryItems.length,
    //     itemBuilder: (context, index) {
    //       return Dismissible(
    //         key: ValueKey(_groceryItems[index].id),
    //         onDismissed: (direction) {
    //           _removeItem(_groceryItems[index]);
    //         },
    //         child: ListTile(
    //           title: Text(_groceryItems[index].name),
    //           leading: Container(
    //             height: 24,
    //             width: 24,
    //             color: _groceryItems[index].category.color,
    //           ),
    //           trailing: Text(_groceryItems[index].quantity.toString()),
    //         ),
    //       );
    //     },
    //   );
    // }

    //error content massage
    // if (_error != null) {
    //   content = Center(child: Text(_error!));
    // }

    return
        // Scaffold(
        //   appBar: AppBar(
        //     title: const Text('Your Groceries'),
        //     actions: [
        //       IconButton(
        //         onPressed: _addItem,
        //         icon: const Icon(Icons.add),
        //       )
        //     ],
        //   ),
        //   body:
        FutureBuilder(
      future: _loadedItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No Content to Display'),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: ValueKey(snapshot.data![index].id),
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  height: 24,
                  width: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(snapshot.data![index].quantity.toString()),
              ),
            );
          },
        );
      },
    );
  }
}
