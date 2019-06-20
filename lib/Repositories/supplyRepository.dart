import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:location/location.dart';

import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

import '../main.dart';

class SupplyRepository {
  var firestore = FireMapState().firestore;

  Future addMarkerWithChecklist(String dbKey, GeoFirePoint point, String btnType, String jsonData) async {

    await firestore.collection(dbKey).add({
      'position': point.data,
      'name': btnType,
      'timestamp': DateTime.now(),
      'jsonData': jsonData
    });
  }
}
