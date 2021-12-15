import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



class Showmap extends StatefulWidget {
  String id,deviceid;
  Showmap({Key key,this.id,this.deviceid}) : super(key: key);

  @override
  _ShowmapState createState() => _ShowmapState();
}

class _ShowmapState extends State<Showmap> {
  
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData> _locationSubscription;
  final CollectionReference profilelist = FirebaseFirestore.instance.collection('data');
  List data = [];
  double lat,long;
  bool a = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getlocation();
  }

  getlocation() {
    _locationSubscription = location.onLocationChanged.handleError((onError){
      _locationSubscription.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) {
      profilelist.where('deviceid',isEqualTo: widget.deviceid.toString()).get().then((querysnapshot) {
        querysnapshot.docs.forEach((element) {
          setState(() {
            lat = element['lat'];
            long = element['longi'];
            a=true;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
      a 
      ? GoogleMap(
        mapType: MapType.hybrid,
        markers: {
          Marker(
            markerId: const MarkerId('Marker id'),
            icon: BitmapDescriptor.defaultMarker,
            position: LatLng(lat,long)
          )
        },
        initialCameraPosition: CameraPosition(target: LatLng(lat,long),zoom: 18),
      )
      : const Center(child: CircularProgressIndicator()),
    );
  }
}
