import 'package:flutter/material.dart';

import 'package:flutter_base/models/Item.dart';

import 'package:uuid/uuid.dart';

import 'dart:convert';

import 'package:geoflutterfire/src/point.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../Repositories/supplyRepository.dart';

import 'package:flutter_base/main.dart';

class SimpleDynamicChecklistApp extends StatelessWidget {
  GeoFirePoint point;

  SimpleDynamicChecklistApp(this.point);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SimpleDynamicChecklist(point),
    );
  }
}

class SimpleDynamicChecklist extends StatefulWidget {
  GeoFirePoint point;

  SimpleDynamicChecklist(this.point);

  @override
  _SimpleDynamicChecklistState createState() =>
      _SimpleDynamicChecklistState(point);
}

class _SimpleDynamicChecklistState extends State<SimpleDynamicChecklist> {
  Map<String, Item> itemsMap;

  Map<String, String> nameMap;
  Map<String, int> qtyMap;

  GeoFirePoint point;

  _SimpleDynamicChecklistState(this.point);

  @override
  initState() {
    super.initState();

    itemsMap = new Map<String, Item>();
    nameMap = new Map<String, String>();
    qtyMap = new Map<String, int>();
    // Add listeners to this class
  }

  // you should fetch them from firestore

//  void takeItemName(String id, String itemName,TextEditingController controller) {
//    controller.text = itemName;
//    Item item = itemsMap[id];
//    setState(() {
//      nameMap[id] = itemName;
//      item.name = itemName;
//    });
//  }
//
//  void takeNumber(String id, String text, TextEditingController controller) {
//    controller.text = text;
//    Item item = itemsMap[id];
//    setState(() {
//      qtyMap[id] = int.parse(text);
//      item.qty = int.parse(text);
//    });
//  }
  void redirectToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FireMapApp()),
    );
  }

  Future _submitItems() async {
    var jsonConvertMap = new Map<String, Map<String, String>>();
    var keys = itemsMap.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      jsonConvertMap[keys[i]] = itemsMap[keys[i]].toJson();
    }
    String jsonData = jsonEncode(jsonConvertMap);
    await SupplyRepository()
        .addMarkerWithChecklist("supplyLocation", point, "supply", jsonData);
    redirectToMap();
  }

  void _addItem() {
    var uuid = new Uuid();
    var dateTime = DateTime.now();
    var item = Item(uuid.v1().toString(), "", 0, dateTime);
    setState(() {
      itemsMap[item.id] = item;
    });
  }

  void _removeItem(String id) {
    print(id);
    print("begin remove");
    setState(() {
      itemsMap.remove(id);
    });
    print(itemsMap);
  }

  Widget singleItemList(int index) {
    var nameController = new TextEditingController();
    var qtyController = new TextEditingController();

    var keys = itemsMap.keys.toList();
    var item = itemsMap[keys[index]];

    nameController.text = item.name;
    qtyController.text = item.qty == 0 ? "" : item.qty.toString();

    void nameListener() {
      itemsMap[keys[index]].name = nameController.text;
    }

    nameController.addListener(nameListener);

    void qtyListener() {
      itemsMap[keys[index]].qty = int.parse(qtyController.text);
    }

    qtyController.addListener(qtyListener);

    print("singleItemList");
    var id = item.id;

    @override
    void dispose() {
      nameController.dispose();
      qtyController.dispose();
    }

    return Container(
      // constraints: BoxConstraints(minWidth: 100, maxWidth: 200),
      decoration:
          BoxDecoration(color: index % 2 == 0 ? Colors.white : Colors.cyan[50]),
//      constraints: BoxConstraints(maxWidth: 200),
      width: 200,
      height: 80,
      key: Key(id),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 80,
            child: Center(child: Text("${index + 1}")),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                // Name
                Expanded(
                  child: TextField(
                    controller: nameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        labelText: "Name", hintText: "Item Name"),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    // onChanged: (text) => takeItemName(item.id, text, qtyController),
                    decoration: InputDecoration(
                        labelText: "Quantity", hintText: "1 - 1000"),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 80,
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _removeItem(id);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int itemsMapLength = itemsMap == null ? 0 : itemsMap.length;
    return Scaffold(
      appBar: AppBar(title: Text("Inventory")),
      body: Center(
          child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: itemsMapLength,
                itemBuilder: (context, index) {
                  if (itemsMap.keys.toList().length == 0) {
                    print("the if is right");
                    return Center(
                      child: Text("Add new item ..."),
                    );
                  } else {
                    return singleItemList(index);
                  }
                }),
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                child: new Text("Save"),
                color: Colors.teal,
                onPressed: _submitItems,
              ),
              RaisedButton(
                child: new Text("Back To Map"),
                color: Colors.teal,
                onPressed: redirectToMap,
              ),
            ],
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: Icon(Icons.add),
        backgroundColor: Colors.pink,
      ),
    );
  }
}
