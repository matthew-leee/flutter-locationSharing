import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:geoflutterfire/src/point.dart';
import 'package:meta/meta.dart';
import 'util.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'GeoFirePoint.dart';


class GeoFireCollectionRef{

  Query _collectionReference;
  Stream<QuerySnapshot> _stream;

  GeoFireCollectionRef(this._collectionReference)
      : assert(_collectionReference != null) {
    _stream = _createStream(_collectionReference).shareReplay(maxSize: 1);
  }

  Stream<List<DocumentSnapshot>> within(
      {@required GeoFirePoint center,
        @required double radius,
        @required String field,
        bool strictMode = false}) {
    int precision = Util.setPrecision(radius);
    String centerHash = center.hash.substring(0, precision);
    List<String> area = GeoFirePoint.neighborsOf(hash: centerHash)
      ..add(centerHash);

    var queries = area.map((hash) {
      Query tempQuery = _queryPoint(hash, field);
      return _createStream(tempQuery).map((QuerySnapshot querySnapshot) {
        return querySnapshot.documents;
      });
    });

    var mergedObservable = Observable.combineLatest(queries,
            (List<List<DocumentSnapshot>> originalList) {
          var reducedList = <DocumentSnapshot>[];
          originalList.forEach((t) {
            reducedList.addAll(t);
          });
          return reducedList;
        });

    var filtered = mergedObservable.map((List<DocumentSnapshot> list) {
      var mappedList = list.map((DocumentSnapshot documentSnapshot) {
        // split and fetch geoPoint from the nested Map
        List<String> fieldList = field.split('.');
        var geoPointField = documentSnapshot.data[fieldList[0]];
        if (fieldList.length > 1) {
          for (int i = 1; i < fieldList.length; i++) {
            geoPointField = geoPointField[fieldList[i]];
          }
        }
        GeoPoint geoPoint = geoPointField['geopoint'];
        documentSnapshot.data['distance'] =
            center.distance(lat: geoPoint.latitude, lng: geoPoint.longitude);
        return documentSnapshot;
      });

      var filteredList = strictMode
          ? mappedList.where((DocumentSnapshot doc) {
        double distance = doc.data['distance'];
        return distance <= radius * 1.02; // buffer for edge distances;
      }).toList()
          : mappedList.toList();
      filteredList.sort((a, b) {
        double distA = a.data['distance'];
        double distB = b.data['distance'];
        int val = (distA * 1000).toInt() - (distB * 1000).toInt();
        return val;
      });
      return filteredList;
    });
    return filtered.asBroadcastStream();
  }

  Query _queryPoint(String geoHash, String field) {
    String end = '$geoHash~';
    Query temp = _collectionReference;
    return temp.orderBy('$field.geohash').startAt([geoHash]).endAt([end]);
  }

  Observable<QuerySnapshot> _createStream(var ref) {
    return Observable<QuerySnapshot>(ref.snapshots());
  }
}