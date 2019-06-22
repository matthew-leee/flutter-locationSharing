import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_base/main.dart';

import 'dart:async';



import '../main.dart';

class SupplyRepository {
  var firestore = FireMapState().firestore;

Future addMarkerWithChecklist(String dbKey, GeoPoint point, String geohash, String btnType, String jsonData) async {

    await firestore.collection(dbKey).add({
      'position': {'geohash': geohash, 'geopoint': point},
      'name': btnType,
      'timestamp': DateTime.now(),
      'jsonData': jsonData
    });
  }
}
