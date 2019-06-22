import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:location/location.dart';

// import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

import 'DynamicChecklist/simpleDynamicChecklist.dart';

import 'utils/math.dart';

import 'CloneGeofire/GeoFirePoint.dart';
import 'CloneGeofire/GeoFireCollectionRef.dart';
import 'package:geohash/geohash.dart';

void main() => runApp(FireMapApp());

// initialize, used a single stateful widget in body
class FireMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: FireMap(),
    ));
  }
}

class FireMap extends StatefulWidget {
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;

  // locate user
  Location location = new Location();

  LatLng currentLocation;

  // essential for adding points
  Firestore firestore = Firestore.instance;

  // Stateful Data
  BehaviorSubject<double> radius = BehaviorSubject(seedValue: 20.0);
  Stream<dynamic> query;

  // Subscription
  StreamSubscription subscription;

  String nameHash;

  @override
  void initState() {
    super.initState();
    location.onLocationChanged().listen(onData);
  }

  void onData(Map<String, double> newLocation) {
    var newLatLng = LatLng(newLocation["latitude"], newLocation["longtitude"]);
    var distance = Math.calculateDistance(currentLocation.latitude,
        currentLocation.longitude, newLatLng.latitude, newLatLng.longitude);
    // in meter
    if (distance > 5) {
      setState(() {
        currentLocation = newLatLng;
      });
      firestore.collection('usersLiveLovation').add({
        'position': newLatLng,
        'nameHash': nameHash,
        'timestamp': DateTime.now()
      });
    }
  }

  build(context) {
    return Stack(children: [
      GoogleMap(
        initialCameraPosition:
            CameraPosition(target: LatLng(22.281168, 114.166298), zoom: 17),
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        mapType: MapType.normal,
        compassEnabled: true,
        trackCameraPosition: true,
      ),
      Center(child: Image.asset("images/cross.png", width: 30.0, height: 30.0)),
//     Positioned(
//          bottom: 50,
//          right: 10,
//          child:
//          FlatButton(
//            child: Image.asset("images/cross.png", width: 30.0, height: 30.0),
//            color: Colors.green,
//            onPressed: (){_addMarker("default");}
//          )
//      ),

      // help
      Positioned(
          bottom: 100,
          right: 10,
          child: RaisedButton(
              child: Image.asset("images/help.png", width: 25.0, height: 25.0),
              color: Colors.red,
              onPressed: () async  {
                await _addMarker('help');
              })),

      // supply
      Positioned(
          bottom: 150,
          right: 10,
          child: RaisedButton(
              child: Image.asset("images/supplyBlack.png",
                  width: 25.0, height: 25.0),
              color: Colors.yellow,
              onPressed: () async {
                var myPosition = await location.getLocation();
                String geohash = Geohash.encode(myPosition["latitude"], myPosition['longitude']);
                var position = mapController.cameraPosition.target;
                var point = GeoPoint(position.latitude, position.longitude);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SimpleDynamicChecklistApp(point, geohash)),
                );
              })),

      // medic
      Positioned(
          bottom: 200,
          right: 10,
          child: RaisedButton(
              child: Image.asset("images/medic.png", width: 25.0, height: 25.0),
              color: Colors.blue,
              onPressed: () async {
                await _addMarker('medic');
              })),

      // dog
      Positioned(
          bottom: 250,
          right: 10,
          child: RaisedButton(
              child: Image.asset("images/dog.png", width: 25.0, height: 25.0),
              color: Colors.orange,
              onPressed: () async {
                await _addMarker('dog');
              })),

      Positioned(
          bottom: 50,
          left: 10,
          child: Slider(
            min: 20,
            max: 100,
            divisions: 4,
            value: radius.value,
            label: 'Radius ${radius.value}km',
            activeColor: Colors.green,
            inactiveColor: Colors.green.withOpacity(0.2),
            onChanged: _updateQuery,
          ))
    ]);
  }

  // Map Created Lifecycle Hook
  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  Future _addMarker(String btnType) async {
    var myPosition = await location.getLocation();
    var position = mapController.cameraPosition.target;
    var geoPoint = new GeoPoint(position.latitude, position.longitude);
    String geohash =
        Geohash.encode(myPosition['latitude'], myPosition['longitude']);

    BitmapDescriptor roundSpot = _roundSpotSwitch(btnType);
    var marker = MarkerOptions(
        position: position,
        icon: roundSpot,
        infoWindowText: InfoWindowText('Magic Marker', '🍄🍄🍄'));

    mapController.addMarker(marker);
    firestore.collection('generalLocations').add({
      'position': {'geohash': geohash, 'geopoint': geoPoint},
      'name': btnType,
      'timestamp': DateTime.now()
    });
  }

  _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('TextField in Dialog'),
            content: TextField(
              // controller: _textFieldController,
              decoration: InputDecoration(hintText: "TextField in Dialog"),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  BitmapDescriptor _roundSpotSwitch(String btnType) {
    BitmapDescriptor spot;
    switch (btnType) {
      case "help":
        {
          spot = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        }
        break;
      case "supply":
        {
          spot =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
        }
        break;
      case "medic":
        {
          spot =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        }
        break;
      case "dog":
        {
          spot =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          // not working
          // spot = BitmapDescriptor.fromAsset("/images/bitmap.bmp");
        }
        break;
      default:
        {
          spot =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        }
        break;
    }
    return spot;
  }

  // move to user position
  _animateToUser() async {
    // get your current position
    var pos = await location.getLocation();
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      // set current position
      target: LatLng(pos['latitude'], pos['longitude']),
      zoom: 17.0,
    )));
  }

  // Set GeoLocation Data
//  Future<DocumentReference> _addGeoPoint() async {
//    var pos = await location.getLocation();
//    GeoFirePoint point = geo.point(latitude: pos['latitude'], longitude: pos['longitude']);
//    return firestore.collection('generalLocations').add({
//      'position': point.data,
//      'name': 'Yay I can be queried!'
//    });
//  }

  // firebase emits changes automatically, get caught by this function
  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print(documentList);
    //
    mapController.clearMarkers();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.data['position']['geopoint'];
      double distance = document.data['distance'];
      var marker = MarkerOptions(
          position: LatLng(pos.latitude, pos.longitude),
          icon: _roundSpotSwitch(document.data["name"]),
          infoWindowText: InfoWindowText(
              'Magic Marker', '$distance kilometers from query center'));

      if (_notExpired(document.data["name"], document.data["timestamp"])) {
        mapController.addMarker(marker);
      }
    });
  }

  bool _notExpired(String name, DateTime timestamp) {
    var now = DateTime.now();
    Duration timePassed = now.difference(timestamp);
    switch (name) {
      case "help":
        {
          return timePassed.inMinutes > 5 ? false : true;
        }
      case "supply":
        {
          return true;
        }
      case "medic":
        {
          return true;
        }
      case "dog":
        {
          return timePassed.inMinutes > 5 ? false : true;
        }
      default:
        {
          return false;
        }
    }
  }

  _startQuery() async {
    // Get users location
    var pos = await location.getLocation();
    double lat = pos['latitude'];
    double lng = pos['longitude'];
    setState(() {
      currentLocation = LatLng(lat, lng);
    });

    // Make a referece to firestore
    var ref = firestore.collection('generalLocations');
    GeoFirePoint center = new GeoFirePoint(lat, lng);

    // subscribe to query
    subscription = radius.switchMap((rad) {
      return GeoFireCollectionRef(ref).within(
          center: center, radius: rad, field: 'position', strictMode: true);
    }).listen(_updateMarkers);
  }

  _updateQuery(value) {
    final zoomMap = {
      20.0: 21.0,
      40.0: 19.0,
      60.0: 17.0,
      80.0: 15.0,
      100.0: 13.0
    };
    final zoom = zoomMap[value];
    mapController.moveCamera(CameraUpdate.zoomTo(zoom));

    setState(() {
      radius.add(value);
    });
  }

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }
}
