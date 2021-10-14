import 'dart:async';

import 'package:ad_example/map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;
import 'package:platform_device_id/platform_device_id.dart';
import 'package:workmanager/workmanager.dart';

const myTask = "getCurrentLocation";
 
void callbackDispatcher() {
  Workmanager().executeTask((task, inputdata) async {  
    switch (task) {
      case myTask:
        print("this method was called from native!");
        livelocation();
        break;
 
      case Workmanager.iOSBackgroundTask:
        print("iOS background fetch delegate ran");
        break;
    }
    return Future.value(true);
  });
}

StreamSubscription<loc.LocationData> locationSubscription;
final loc.Location locationn = loc.Location();
final CollectionReference userprofiledata = FirebaseFirestore.instance.collection('data');
String _deviceId;
String uid;

Future<void> livelocation() async {

  await userprofiledata.where('deviceid',isEqualTo: _deviceId.toString()).get().then((querysnapshot) {
    querysnapshot.docs.forEach((element) {
      print('user id : ------ ${element.id}');
      uid = element.id;
    });
  });

  locationSubscription = locationn.onLocationChanged.handleError((onError){
    locationSubscription.cancel();
  }).listen((loc.LocationData currentlocation) {
    print("hu aavo");
    userprofiledata.doc(uid).update({
      'lat' : currentlocation.latitude,
      'longi' : currentlocation.longitude
    }); 
  });
  
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  Workmanager().initialize(callbackDispatcher); 
 
  Workmanager().registerPeriodicTask(
      "1",
      myTask,
      frequency: const Duration(seconds: 5),
  );
  await Firebase.initializeApp();
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      // home: const Admin(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData> _locationSubscription;
  String idd = "";
  String name = "";
  String userdeviceid = "";
  FocusNode txtbox = FocusNode();

  final CollectionReference profilelist = FirebaseFirestore.instance.collection('data');
  List datalist = [];

  var a = false;
  
  loc.LocationData getlocation;

  Future getdata() async {
    try {
      getlocation = await location.getLocation();
      await profilelist.get().then((querysnapshot) {
        querysnapshot.docs.forEach((element) {
          setState(() {
            datalist.add(element.data());
            a=true;
          });
        });
      });

      await profilelist.where('deviceid',isEqualTo: _deviceId.toString()).get().then((querysnapshot) {
        querysnapshot.docs.forEach((element) {
          setState(() {
            print('user id : ------ ${element.id}');
            idd = element.id;
            name = element['name'];
            userdeviceid = element['deviceid'];
          });
        });
      });
    } catch (e) {
      return null;
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    getdata();
    enablelocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initPlatformState() async {
    String deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
    } on PlatformException {
      deviceId = 'Failed to get deviceId.';
    }
    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
      print("deviceId->$_deviceId");
    });
  }

  final edit = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live location racker"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30,),
            name=="" || name == null
            ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    focusNode: txtbox,
                    decoration: const InputDecoration(
                      hintText: 'Enter Your Name',
                      border: OutlineInputBorder()
                    ),
                    controller: edit,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    profilelist.add({
                      'name' : edit.text,
                      'deviceid' : _deviceId,
                      'lat' : getlocation.latitude,
                      'longi' : getlocation.longitude
                    });
                    edit.text = "";
                    datalist.clear();
                    txtbox.unfocus();
                    getdata();
                    enablelocation();
                    setState(() {
                      name = " ";
                    });
                  }, 
                  child: Text('Save'),
                ),
              ],
            )
            : Center(
              child: Text("Welcome "+name)
            ),
          // a
          // ? Expanded(
          //   child: ListView.builder(
          //     itemCount: datalist.length,
          //     itemBuilder: (BuildContext context, int index) {
          //       getuserid(datalist[index]['deviceid']);
          //       return Container(
          //         child: Column(
          //           children: [
          //             ListTile(
          //               title: Text(datalist[index]['name']),
          //               subtitle: Row(
          //                 children: [
          //                   Text(datalist[index]['lat'].toString()),
          //                   SizedBox(width: 10,),
          //                   Text(datalist[index]['longi'].toString()),
          //                 ],
          //               ),
          //               trailing: IconButton(
          //                 onPressed: (){
          //                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => Showmap(id: idd,deviceid: datalist[index]['deviceid'],),));
          //                 }, 
          //                 icon: Icon(Icons.directions),
          //               ),
          //             ),
          //           ],
          //         ),
          //       );
          //     },
          //   ),
          // )
          // : const CircularProgressIndicator()
        ],
      ),
       
    );
  }

  Future<void> getuserid(did) async{
    await profilelist.where('deviceid',isEqualTo: did.toString()).get().then((querysnapshot) {
      querysnapshot.docs.forEach((element) {
        setState(() {
          print('user id : ------ ${element.id}');
          idd = element.id;
          userdeviceid = element['deviceid'];
        });
      });
    });
  }

  Future<void> enablelocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError){
      _locationSubscription.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) {
      print("hu aavo");
      profilelist.doc(idd).update({
        'lat' : currentlocation.latitude,
        'longi' : currentlocation.longitude
      });
      // print("current location : ${currentlocation.latitude}  ---  ${currentlocation.longitude}");
      datalist.clear();
      getdata();  
    });
    
  }

}


class Admin extends StatefulWidget {
  const Admin({Key key}) : super(key: key);

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
    final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData> _locationSubscription;
  String idd = "";
  String name = "";
  String userdeviceid = "";
  FocusNode txtbox = FocusNode();

  final CollectionReference profilelist = FirebaseFirestore.instance.collection('data');
  List datalist = [];

  var a = false;
  String _deviceId;
  loc.LocationData getlocation;

  Future getdata() async {
    try {
      getlocation = await location.getLocation();
      await profilelist.get().then((querysnapshot) {
        querysnapshot.docs.forEach((element) {
          setState(() {
            datalist.add(element.data());
            a=true;
          });
        });
      });
    } catch (e) {
      return null;
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    getdata();
  }

  Future<void> initPlatformState() async {
    String deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
    } on PlatformException {
      deviceId = 'Failed to get deviceId.';
    }
    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
      print("deviceId->$_deviceId");
    });
  }

  final edit = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 3));
        datalist.clear();
        getdata();
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Live location racker"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30,),
              // name=="" || name == null
              // ? Column(
              //   children: [
              //     Container(
              //       padding: const EdgeInsets.all(20),
              //       child: TextField(
              //         focusNode: txtbox,
              //         decoration: const InputDecoration(
              //           hintText: 'Enter Your Name',
              //           border: OutlineInputBorder()
              //         ),
              //         controller: edit,
              //       ),
              //     ),
              //     ElevatedButton(
              //       onPressed: () async {
              //         profilelist.add({
              //           'name' : edit.text,
              //           'deviceid' : _deviceId,
              //           'lat' : getlocation.latitude,
              //           'longi' : getlocation.longitude
              //         });
              //         edit.text = "";
              //         datalist.clear();
              //         txtbox.unfocus();
              //         getdata();
              //         enablelocation();
              //         setState(() {
              //           name = " ";
              //         });
              //       }, 
              //       child: Text('Save'),
              //     ),
              //   ],
              // )
              // : Center(
              //   child: Text("Welcome "+name)
              // ),
            a
            ? Expanded(
              child: ListView.builder(
                itemCount: datalist.length,
                itemBuilder: (BuildContext context, int index) {
                  getuserid(datalist[index]['deviceid']);
                  return Container(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(datalist[index]['name']),
                          subtitle: Row(
                            children: [
                              Text(datalist[index]['lat'].toString()),
                              SizedBox(width: 10,),
                              Text(datalist[index]['longi'].toString()),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: (){
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => Showmap(id: idd,deviceid: datalist[index]['deviceid'],),));
                            }, 
                            icon: Icon(Icons.directions),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
            : const CircularProgressIndicator()
          ],
        ),
         
      ),
    );
  }

  Future<void> getuserid(did) async{
    await profilelist.where('deviceid',isEqualTo: did.toString()).get().then((querysnapshot) {
      querysnapshot.docs.forEach((element) {
        setState(() {
          print('user id : ------ ${element.id}');
          idd = element.id;
          userdeviceid = element['deviceid'];
        });
      });
    });
  }
}

